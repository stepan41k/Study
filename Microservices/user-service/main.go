package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type User struct {
	ID    uint   `gorm:"primaryKey" json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}

var db *gorm.DB

func main() {
	dsn := os.Getenv("DB_URL")
	var err error
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to DB:", err)
	}
	db.AutoMigrate(&User{})

	var count int64

	// Seed Data
	if err := db.Model(&User{}).Count(&count); err == nil && count == 0 {
		db.Create(&User{Name: "Alice", Email: "alice@example.com"})
		db.Create(&User{Name: "Bob", Email: "bob@example.com"})
	}

	r := gin.Default()
	r.POST("/users", createUser)
	r.GET("/users", getUsers)
	r.GET("/users/:id", getUserByID)

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