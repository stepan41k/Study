package main

import (
	"context"
	"net/http"
	"net/http/httptest"
	"github.com/stepan41k/Microservices/payment-service/pb"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/glebarez/sqlite"
	"github.com/stretchr/testify/assert"
	"google.golang.org/grpc"
	"gorm.io/gorm"
)

// Mocks
type MockOrderClient struct {
	UpdateOrderStatusFunc func(ctx context.Context, in *pb.UpdateOrderStatusRequest, opts ...grpc.CallOption) (*pb.Empty, error)
}

func (m *MockOrderClient) UpdateOrderStatus(ctx context.Context, in *pb.UpdateOrderStatusRequest, opts ...grpc.CallOption) (*pb.Empty, error) {
	if m.UpdateOrderStatusFunc != nil {
		return m.UpdateOrderStatusFunc(ctx, in, opts...)
	}
	return &pb.Empty{}, nil
}

type MockShippingClient struct {
	CreateShippingFunc func(ctx context.Context, in *pb.CreateShippingRequest, opts ...grpc.CallOption) (*pb.ShippingResponse, error)
}

func (m *MockShippingClient) CreateShipping(ctx context.Context, in *pb.CreateShippingRequest, opts ...grpc.CallOption) (*pb.ShippingResponse, error) {
	if m.CreateShippingFunc != nil {
		return m.CreateShippingFunc(ctx, in, opts...)
	}
	return &pb.ShippingResponse{ShippingId: 1}, nil
}

func setupTestDB() *gorm.DB {
	db, _ := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	db.AutoMigrate(&Payment{})
	return db
}

func TestProcessPayment(t *testing.T) {
	db = setupTestDB()
	// Создаем платеж
	payment := Payment{OrderID: 10, Amount: 200, Status: "pending"}
	db.Create(&payment)

	// Флаги вызовов
	orderCalled := false
	shippingCalled := false

	// Настройка моков
	orderClient = &MockOrderClient{
		UpdateOrderStatusFunc: func(ctx context.Context, in *pb.UpdateOrderStatusRequest, opts ...grpc.CallOption) (*pb.Empty, error) {
			orderCalled = true
			assert.Equal(t, int32(10), in.OrderId)
			assert.Equal(t, "paid", in.NewStatus)
			return &pb.Empty{}, nil
		},
	}

	shippingClient = &MockShippingClient{
		CreateShippingFunc: func(ctx context.Context, in *pb.CreateShippingRequest, opts ...grpc.CallOption) (*pb.ShippingResponse, error) {
			shippingCalled = true
			assert.Equal(t, int32(10), in.OrderId)
			return &pb.ShippingResponse{ShippingId: 55}, nil
		},
	}

	r := gin.Default()
	r.PUT("/payments/:id/pay", processPayment)

	req, _ := http.NewRequest("PUT", "/payments/1/pay", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	// Проверки
	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, orderCalled, "Order Service должен быть уведомлен")
	assert.True(t, shippingCalled, "Shipping Service должен быть уведомлен")

	var updatedPayment Payment
	db.First(&updatedPayment, 1)
	assert.Equal(t, "paid", updatedPayment.Status)
}