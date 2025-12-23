package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stepan41k/protos/grpc_microservices/pb"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type User struct {
	ID    uint   `gorm:"primaryKey" json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
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

var db *gorm.DB
var orderClient pb.OrderServiceClient

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

	r := gin.Default()
	r.POST("/users", createUser)
	r.GET("/users", getUsers)
	r.GET("/users/:id", getUserByID)
	r.GET("/users/:id/full", getUserWithOrders)

	r.Run(":8080")
}

func createUser(c *gin.Context) {
	var user User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	db.Create(&user)
	c.JSON(http.StatusOK, user)
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

    // --- НОВАЯ ЛОГИКА: ЗАПРОС ЗАКАЗОВ ---
    var ordersList []OrderData
    
    ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
    defer cancel()

    // gRPC вызов в Order Service
    resp, err := orderClient.GetUserOrders(ctx, &pb.GetUserOrdersRequest{UserId: int32(user.ID)})
    if err == nil {
        // Маппинг gRPC ответа в нашу структуру
        for _, o := range resp.Orders {
            ordersList = append(ordersList, OrderData{
                ID:     o.Id,
                Amount: o.Amount,
                Status: o.Status,
            })
        }
    } else {
        log.Printf("Failed to fetch orders: %v", err)
        // Не падаем с ошибкой, а просто возвращаем пустой список заказов (Graceful degradation)
        ordersList = []OrderData{} 
    }
    // ------------------------------------

    c.JSON(http.StatusOK, UserProfileResponse{
        User:   user,
        Orders: ordersList,
    })
}