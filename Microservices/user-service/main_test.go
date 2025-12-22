package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

// setupTestDB создает изолированную БД в памяти для каждого теста

func TestCreateUser(t *testing.T) {
	// 1. Подготовка
	r := gin.Default()
	r.POST("/users", createUser)

	user := User{Name: "TestUser", Email: "test@test.com"}
	jsonValue, _ := json.Marshal(user)

	// 2. Выполнение запроса
	req, _ := http.NewRequest("POST", "/users", bytes.NewBuffer(jsonValue))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	// 3. Проверка
	assert.Equal(t, http.StatusOK, w.Code)
	
	var responseUser User
	json.Unmarshal(w.Body.Bytes(), &responseUser)
	assert.Equal(t, "TestUser", responseUser.Name)
	assert.NotZero(t, responseUser.ID)
}

func TestGetUsers(t *testing.T) {
	db.Create(&User{Name: "Alice", Email: "alice@test.com"})
	db.Create(&User{Name: "Bob", Email: "bob@test.com"})

	r := gin.Default()
	r.GET("/users", getUsers)

	req, _ := http.NewRequest("GET", "/users", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	
	var users []User
	json.Unmarshal(w.Body.Bytes(), &users)
	assert.Len(t, users, 2)
}

func TestGetUserByID(t *testing.T) {
	user := User{Name: "Charlie", Email: "charlie@test.com"}
	db.Create(&user)

	r := gin.Default()
	r.GET("/users/:id", getUserByID)

	req, _ := http.NewRequest("GET", "/users/1", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	
	var responseUser User
	json.Unmarshal(w.Body.Bytes(), &responseUser)
	assert.Equal(t, "Charlie", responseUser.Name)
}