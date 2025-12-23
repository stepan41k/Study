package main

import (
	"context"
	"log"
	"net"
	"net/http"
	"os"
	"time"

	pb "github.com/stepan41k/protos/grpc_microservices/pb"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type Payment struct {
	ID      uint    `gorm:"primaryKey" json:"id"`
	OrderID int32   `json:"order_id" binding:"required"`
	Amount  float32 `json:"amount" binding:"required"`
	Status  string  `json:"status" binding:"required"` // "pending", "paid", "failed"
}

var db *gorm.DB
var orderClient pb.OrderServiceClient
var shippingClient pb.ShippingServiceClient

type server struct {
	pb.UnimplementedPaymentServiceServer
}

func (s *server) CreatePayment(ctx context.Context, req *pb.CreatePaymentRequest) (*pb.PaymentResponse, error) {
	payment := Payment{
		OrderID: req.OrderId,
		Amount:  req.Amount,
		Status:  "pending",
	}
	result := db.Create(&payment)
	if result.Error != nil {
		return nil, result.Error
	}
	log.Printf("Payment created for Order %d", req.OrderId)
	return &pb.PaymentResponse{PaymentId: int32(payment.ID), Status: payment.Status}, nil
}

func (s *server) FailPayment(ctx context.Context, req *pb.FailPaymentRequest) (*pb.Empty, error) {
	var payment Payment

	if err := db.Where("order_id = ?", req.OrderId).First(&payment).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			log.Printf("Payment for order %d not found", req.OrderId)
			return nil, status.Errorf(codes.NotFound, "Payment for order %d not found", req.OrderId)
		}
		return nil, status.Error(codes.Internal, "Database error")
	}

	if payment.Status == "failed" {
		return &pb.Empty{}, nil
	}

	payment.Status = "failed"
	if err := db.Save(&payment).Error; err != nil {
		log.Printf("Failed to update payment status: %v", err)
		return nil, status.Error(codes.Internal, "Failed to update payment")
	}

	log.Printf("Payment for order %d marked as failed", req.OrderId)
	return &pb.Empty{}, nil
}

func main() {
	dsn := os.Getenv("DB_URL")
	var err error
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to DB:", err)
	}
	db.AutoMigrate(&Payment{})

	connOrder, err := grpc.Dial(os.Getenv("ORDER_SERVICE_URL"), grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err == nil {
		orderClient = pb.NewOrderServiceClient(connOrder)
	}
	connShip, err := grpc.Dial(os.Getenv("SHIPPING_SERVICE_URL"), grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err == nil {
		shippingClient = pb.NewShippingServiceClient(connShip)
	}

	go func() {
		lis, err := net.Listen("tcp", ":"+os.Getenv("GRPC_PORT"))
		if err != nil {
			log.Fatalf("failed to listen: %v", err)
		}
		s := grpc.NewServer()
		pb.RegisterPaymentServiceServer(s, &server{})
		log.Printf("Payment gRPC server listening at %v", lis.Addr())
		if err := s.Serve(lis); err != nil {
			log.Fatalf("failed to serve: %v", err)
		}
	}()

	r := gin.Default()
	r.GET("/payments", func(c *gin.Context) {
		var payments []Payment
		db.Find(&payments)
		c.JSON(http.StatusOK, payments)
	})
	
	r.PUT("/payments/:id/pay", processPayment) // order & shipping

	r.Run(":" + os.Getenv("PORT"))
}

func processPayment(c *gin.Context) {
	id := c.Param("id")
	var payment Payment
	if err := db.First(&payment, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment not found"})
		return
	}

	if payment.Status == "paid" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Already paid"})
		return
	}

	payment.Status = "paid"
	db.Save(&payment)

	ctx, cancel := context.WithTimeout(context.Background(), time.Second*5)
	defer cancel()

	if orderClient != nil {
		_, err := orderClient.UpdateOrderStatus(ctx, &pb.UpdateOrderStatusRequest{
			OrderId:   payment.OrderID,
			NewStatus: "paid",
		})
		if err != nil {
			log.Printf("Failed to update order status: %v", err)
		} else {
			log.Println("Order status updated to paid via gRPC")
		}
	}

	if shippingClient != nil {
		_, err := shippingClient.CreateShipping(ctx, &pb.CreateShippingRequest{
			OrderId: payment.OrderID,
			UserId:  1, 
		})
		if err != nil {
			log.Printf("Failed to create shipping: %v", err)
		} else {
			log.Println("Shipping created via gRPC")
		}
	}

	c.JSON(http.StatusOK, payment)
}