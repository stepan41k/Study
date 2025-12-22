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
	"github.com/stepan41k/Microservices/order-service/pb"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
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

// gRPC Server для приема обновлений статуса
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

func main() {
	// Подключение к БД
	dsn := os.Getenv("DB_URL")
	var err error
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to DB:", err)
	}
	db.AutoMigrate(&Order{})

	var count int64

	// Seed Data
	if err := db.Model(&Order{}).Count(&count); err == nil && count == 0 {
		db.Create(&Order{UserID: 1, Amount: 100.50, Status: "created"})
		db.Create(&Order{UserID: 2, Amount: 250.00, Status: "created"})
	}

	// Подключение к Payment Service (Client)
	conn, err := grpc.Dial(os.Getenv("PAYMENT_SERVICE_URL"), grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Printf("Did not connect to Payment Service: %v", err) // Не падаем сразу, ждем поднятия
	} else {
		paymentClient = pb.NewPaymentServiceClient(conn)
	}

	// Запуск gRPC сервера (Server)
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

	// Gin Handlers
	r := gin.Default()
	r.POST("/orders", createOrder)
	r.GET("/orders", getOrders)
	r.GET("/orders/:id", getOrder)
	r.PUT("/orders/:id/status", updateStatus) // Здесь триггер логики

	r.Run(":" + os.Getenv("PORT"))
}

func createOrder(c *gin.Context) {
	var order Order
	if err := c.ShouldBindJSON(&order); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
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

// updateStatus - Ключевой метод задания
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

	// Сценарий 1: Если статус "formed", автоматически создаем Оплату
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