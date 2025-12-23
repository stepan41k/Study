package main

import (
	"context"
	"log"
	"net"
	"net/http"
	"os"

	pb "github.com/stepan41k/protos/grpc_microservices/pb"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type Shipping struct {
	ID      uint   `gorm:"primaryKey" json:"id"`
	OrderID int32  `json:"order_id"`
	UserID  int32  `json:"user_id"`
	Status  string `json:"status"` // "pending", "shipped"
}

var db *gorm.DB

type server struct {
	pb.UnimplementedShippingServiceServer
}

func (s *server) CreateShipping(ctx context.Context, req *pb.CreateShippingRequest) (*pb.ShippingResponse, error) {
	shipping := Shipping{
		OrderID: req.OrderId,
		UserID:  req.UserId,
		Status:  "created",
	}
	result := db.Create(&shipping)
	if result.Error != nil {
		return nil, result.Error
	}
	log.Printf("Shipping created for Order %d", req.OrderId)
	return &pb.ShippingResponse{ShippingId: int32(shipping.ID)}, nil
}

func main() {
	dsn := os.Getenv("DB_URL")
	var err error
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to DB:", err)
	}
	db.AutoMigrate(&Shipping{})

	go func() {
		lis, err := net.Listen("tcp", ":"+os.Getenv("GRPC_PORT"))
		if err != nil {
			log.Fatalf("failed to listen: %v", err)
		}
		s := grpc.NewServer()
		pb.RegisterShippingServiceServer(s, &server{})
		log.Printf("gRPC server listening at %v", lis.Addr())
		if err := s.Serve(lis); err != nil {
			log.Fatalf("failed to serve: %v", err)
		}
	}()

	r := gin.Default()
	r.GET("/shippings", func(c *gin.Context) {
		var shippings []Shipping
		db.Find(&shippings)
		c.JSON(http.StatusOK, shippings)
	})

	r.Run(":" + os.Getenv("PORT"))
}