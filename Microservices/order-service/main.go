package main

import (
	"context"
	// "fmt"
	"log"
	"net"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	pb "github.com/stepan41k/protos/grpc_microservices/pb"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type Order struct {
	ID     uint    `gorm:"primaryKey" json:"id"`
	UserID int     `json:"user_id"`
	Amount float32 `json:"amount"`
	Status string  `json:"status"` // "created", "formed", "paid", "shipped"
}

var db *gorm.DB
var paymentClient pb.PaymentServiceClient
var userClient pb.UserServiceClient

type server struct {
	pb.UnimplementedOrderServiceServer
}

func (s *server) UpdateOrderStatus(ctx context.Context, req *pb.UpdateOrderStatusRequest) (*pb.Empty, error) {
	var order Order
	if err := db.First(&order, req.OrderId).Error; err != nil {
		return nil, err
	}
	order.Status = req.NewStatus
	db.Save(&order)
	log.Printf("Order %d status updated to %s via gRPC", order.ID, order.Status)
	return &pb.Empty{}, nil
}

func (s *server) GetUserOrders(ctx context.Context, req *pb.GetUserOrdersRequest) (*pb.GetUserOrdersResponse, error) {
	var orders []Order

	result := db.Where("user_id = ?", req.UserId).Find(&orders)
	if result.Error != nil {
		log.Printf("Error fetching orders for user %d: %v", req.UserId, result.Error)
		return nil, status.Error(codes.Internal, "Database error")
	}

	var pbOrders []*pb.Order
	for _, o := range orders {
		pbOrders = append(pbOrders, &pb.Order{
			Id:     int32(o.ID),
			Amount: float32(o.Amount),
			Status: o.Status,
		})
	}

	return &pb.GetUserOrdersResponse{
		Orders: pbOrders,
	}, nil
}

func main() {
	dsn := os.Getenv("DB_URL")
	var err error
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to DB:", err)
	}
	db.AutoMigrate(&Order{})

	var count int64

	if err := db.Model(&Order{}).Count(&count); err == nil && count == 0 {
		db.Create(&Order{UserID: 1, Amount: 100.50, Status: "created"})
		db.Create(&Order{UserID: 2, Amount: 250.00, Status: "created"})
	}

	connUser, _ := grpc.Dial(os.Getenv("USER_SERVICE_URL"), grpc.WithTransportCredentials(insecure.NewCredentials()))
    userClient = pb.NewUserServiceClient(connUser)

	conn, err := grpc.Dial(os.Getenv("PAYMENT_SERVICE_URL"), grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Printf("Did not connect to Payment Service: %v", err) // Не падаем сразу, ждем поднятия
	} else {
		paymentClient = pb.NewPaymentServiceClient(conn)
	}

	go func() {
		lis, err := net.Listen("tcp", ":"+os.Getenv("GRPC_PORT"))
		if err != nil {
			log.Fatalf("failed to listen: %v", err)
		}
		s := grpc.NewServer()
		pb.RegisterOrderServiceServer(s, &server{})
		log.Printf("Order gRPC server listening at %v", lis.Addr())
		if err := s.Serve(lis); err != nil {
			log.Fatalf("failed to serve: %v", err)
		}
	}()

	r := gin.Default()
	r.POST("/orders", createOrder)
	r.GET("/orders", getOrders)
	r.GET("/orders/:id", getOrder)
	r.PUT("/orders/:id/status", updateStatus)
	r.PUT("/orders/:id/cancel", cancelOrder)

	r.Run(":" + os.Getenv("PORT"))
}

func createOrder(c *gin.Context) {
	var order Order
	if err := c.ShouldBindJSON(&order); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
    defer cancel()

    _, err := userClient.GetUser(ctx, &pb.GetUserRequest{UserId: int32(order.UserID)})
    if err != nil {
        log.Printf("User validation failed: %v", err)
        c.JSON(http.StatusBadRequest, gin.H{"error": "User does not exist or User Service unavailable"})
        return
    }

	order.Status = "created"
	db.Create(&order)
	c.JSON(http.StatusOK, order)
}

func getOrders(c *gin.Context) {
	var orders []Order
	db.Find(&orders)
	c.JSON(http.StatusOK, orders)
}

func getOrder(c *gin.Context) {
	var order Order
	if err := db.First(&order, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	c.JSON(http.StatusOK, order)
}

func updateStatus(c *gin.Context) {
	id := c.Param("id")
	var input struct {
		Status string `json:"status"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var order Order
	if err := db.First(&order, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}

	order.Status = input.Status
	db.Save(&order)

	if input.Status == "formed" {
		if paymentClient == nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Payment service unavailable"})
			return
		}
		ctx, cancel := context.WithTimeout(context.Background(), time.Second*5)
		defer cancel()

		_, err := paymentClient.CreatePayment(ctx, &pb.CreatePaymentRequest{
			OrderId: int32(order.ID),
			Amount:  order.Amount,
		})
		if err != nil {
			log.Printf("Error creating payment: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create payment", "details": err.Error()})
			return
		}
		log.Println("Payment creation initiated via gRPC")
	}

	c.JSON(http.StatusOK, order)
}

func cancelOrder(c *gin.Context) {
    id := c.Param("id")
    var order Order
    if err := db.First(&order, id).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
        return
    }

    if order.Status == "cancelled" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Already cancelled"})
        return
    }

    // 1. Локальная отмена
    previousStatus := order.Status
    order.Status = "cancelled"
    db.Save(&order)

    if previousStatus == "formed" || previousStatus == "paid" {
        go func(orderID uint) {
            ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
            defer cancel()
            
            _, err := paymentClient.FailPayment(ctx, &pb.FailPaymentRequest{
                OrderId: int32(orderID),
            })
            if err != nil {
                log.Printf("Failed to cancel payment for order %d: %v", orderID, err)
            } else {
                log.Printf("Payment cancellation requested for order %d", orderID)
            }
        }(order.ID)
    }

    c.JSON(http.StatusOK, gin.H{"message": "Order cancelled", "status": order.Status})
}
