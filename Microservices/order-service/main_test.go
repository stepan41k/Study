package main

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/glebarez/sqlite"
	"github.com/stepan41k/Microservices/order-service/pb"
	"github.com/stretchr/testify/assert"
	"google.golang.org/grpc"
	"gorm.io/gorm"
)

// MockPaymentClient имитирует gRPC клиент сервиса оплаты
type MockPaymentClient struct {
	pb.UnimplementedPaymentServiceServer // Встраиваем для совместимости
	CreatePaymentFunc func(ctx context.Context, in *pb.CreatePaymentRequest, opts ...grpc.CallOption) (*pb.PaymentResponse, error)
}

// Реализуем интерфейс клиента (обратите внимание, сигнатура клиента чуть отличается от сервера opts...)
func (m *MockPaymentClient) CreatePayment(ctx context.Context, in *pb.CreatePaymentRequest, opts ...grpc.CallOption) (*pb.PaymentResponse, error) {
	if m.CreatePaymentFunc != nil {
		return m.CreatePaymentFunc(ctx, in, opts...)
	}
	return &pb.PaymentResponse{PaymentId: 100, Status: "pending"}, nil
}

func setupTestDB() *gorm.DB {
	db, _ := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	db.AutoMigrate(&Order{})
	return db
}

func TestCreateOrder(t *testing.T) {
	db = setupTestDB()
	r := gin.Default()
	r.POST("/orders", createOrder)

	order := Order{UserID: 1, Amount: 500}
	jsonValue, _ := json.Marshal(order)

	req, _ := http.NewRequest("POST", "/orders", bytes.NewBuffer(jsonValue))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	
	var resp Order
	json.Unmarshal(w.Body.Bytes(), &resp)
	assert.Equal(t, "created", resp.Status)
}

func TestUpdateStatus_Formed_TriggersPayment(t *testing.T) {
	db = setupTestDB()
	// Создаем заказ
	existingOrder := Order{UserID: 1, Amount: 100, Status: "created"}
	db.Create(&existingOrder)

	// Мокаем gRPC клиент
	called := false
	paymentClient = &MockPaymentClient{
		CreatePaymentFunc: func(ctx context.Context, in *pb.CreatePaymentRequest, opts ...grpc.CallOption) (*pb.PaymentResponse, error) {
			called = true
			assert.Equal(t, int32(1), in.OrderId)
			return &pb.PaymentResponse{PaymentId: 999, Status: "pending"}, nil
		},
	}

	r := gin.Default()
	r.PUT("/orders/:id/status", updateStatus)

	// Шлем запрос на смену статуса
	body := []byte(`{"status": "formed"}`)
	req, _ := http.NewRequest("PUT", "/orders/1/status", bytes.NewBuffer(body))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, called, "gRPC метод CreatePayment должен быть вызван")
	
	// Проверяем статус в БД
	var updatedOrder Order
	db.First(&updatedOrder, 1)
	assert.Equal(t, "formed", updatedOrder.Status)
}