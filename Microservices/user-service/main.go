package main

import (
	"context"
	"errors"
	"log"
	"net"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/stepan41k/protos/grpc_microservices/pb"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type User struct {
	ID    uint   `gorm:"primaryKey" json:"id"`
	Name  string `json:"name" binding:"required,min=2"` 
	Email string `json:"email" binding:"required,email"` 
}

type UserProfileResponse struct {
	User   User        `json:"user"`
	Orders []OrderData `json:"orders"`
}

type OrderData struct {
	ID     int32   `json:"id"`
	Amount float32 `json:"amount"`
	Status string  `json:"status"`
}

type ApiError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

var db *gorm.DB
var orderClient pb.OrderServiceClient

type server struct {
	pb.UnimplementedUserServiceServer
}

func (s *server) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.GetUserResponse, error) {
	var user User
	if err := db.First(&user, req.UserId).Error; err != nil {
		return nil, status.Error(codes.NotFound, "User not found")
	}

	// Возвращаем ответ
	return &pb.GetUserResponse{
		Id:    int32(user.ID),
		Name:  user.Name,
		Email: user.Email,
	}, nil
}

func main() {
	dsn := os.Getenv("DB_URL")
	var err error
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to DB:", err)
	}
	db.AutoMigrate(&User{})

	var count int64
	if err := db.Model(&User{}).Count(&count); err == nil && count == 0 {
		db.Create(&User{Name: "Alice", Email: "alice@example.com"})
		db.Create(&User{Name: "Bob", Email: "bob@example.com"})
	}

	connOrder, _ := grpc.Dial(os.Getenv("ORDER_SERVICE_URL"), grpc.WithTransportCredentials(insecure.NewCredentials()))
	orderClient = pb.NewOrderServiceClient(connOrder)

	go func() {
		grpcPort := os.Getenv("GRPC_PORT")
		if grpcPort == "" {
			grpcPort = "50051" 
		}
		
		lis, err := net.Listen("tcp", ":"+grpcPort)
		if err != nil {
			log.Fatalf("failed to listen gRPC: %v", err)
		}
		
		s := grpc.NewServer()
		pb.RegisterUserServiceServer(s, &server{})
		
		log.Printf("User gRPC server listening at %v", lis.Addr())
		if err := s.Serve(lis); err != nil {
			log.Fatalf("failed to serve gRPC: %v", err)
		}
	}()

	r := gin.Default()
	r.POST("/users", createUser)
	r.GET("/users", getUsers)
	r.GET("/users/:id", getUserByID)
	r.GET("/users/:id/full", getUserWithOrders) //orders

	r.Run(":8080")
}

func createUser(c *gin.Context) {
	var user User
	if err := c.ShouldBindJSON(&user); err != nil {
		var ve validator.ValidationErrors
		
		if errors.As(err, &ve) {
			out := make([]ApiError, len(ve))
			for i, fe := range ve {
				out[i] = ApiError{
					Field:   fe.Field(),
					Message: getErrorMsg(fe),
				}
			}
			c.JSON(http.StatusBadRequest, gin.H{"errors": out})
			return
		}

		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	db.Create(&user)
	c.JSON(http.StatusCreated, user)
}

func getUsers(c *gin.Context) {
	var users []User
	db.Find(&users)
	c.JSON(http.StatusOK, users)
}

func getUserByID(c *gin.Context) {
	var user User
	if err := db.First(&user, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	c.JSON(http.StatusOK, user)
}

func getUserWithOrders(c *gin.Context) {
	id := c.Param("id")
	var user User
	if err := db.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	var ordersList []OrderData

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	resp, err := orderClient.GetUserOrders(ctx, &pb.GetUserOrdersRequest{UserId: int32(user.ID)})
	if err == nil {
		for _, o := range resp.Orders {
			ordersList = append(ordersList, OrderData{
				ID:     o.Id,
				Amount: o.Amount,
				Status: o.Status,
			})
		}
	} else {
		log.Printf("Failed to fetch orders: %v", err)
		ordersList = []OrderData{}
	}

	c.JSON(http.StatusOK, UserProfileResponse{
		User:   user,
		Orders: ordersList,
	})
}

func getErrorMsg(fe validator.FieldError) string {
	switch fe.Tag() {
	case "required":
		return "Это поле обязательно для заполнения"
	case "email":
		return "Некорректный формат email"
	case "min":
		return "Длина должна быть больше " + fe.Param() + " символов"
	}
	return "Неизвестная ошибка"
}
