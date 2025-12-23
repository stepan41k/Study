package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

// DTO структуры для общения с API
type OrderDTO struct {
	ID      uint    `json:"id"`
	UserID  uint    `json:"user_id"`
	Amount  float64 `json:"amount"`
	Status  string  `json:"status"`
}

type PaymentDTO struct {
	ID      uint    `json:"id"`
	OrderID uint    `json:"order_id"`
	Status  string  `json:"status"`
	Amount  float64 `json:"amount"`
}

const (
	orderServiceURL   = "http://localhost:8082"
	paymentServiceURL = "http://localhost:8083"
)

func TestE2E_CreateOrder(t *testing.T) {
	// 1. Подготовка данных
	order := OrderDTO{
		UserID: 1, 
		Amount: 500,
	}
	jsonValue, _ := json.Marshal(order)

	// 2. Выполнение запроса
	resp, err := http.Post(orderServiceURL+"/orders", "application/json", bytes.NewBuffer(jsonValue))
	assert.NoError(t, err)
	defer resp.Body.Close()

	// 3. Проверка
	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var createdOrder OrderDTO
	body, _ := io.ReadAll(resp.Body)
	json.Unmarshal(body, &createdOrder)

	assert.NotZero(t, createdOrder.ID)
	assert.Equal(t, "created", createdOrder.Status) // Ожидаем начальный статус
	assert.Equal(t, 500.0, createdOrder.Amount)
}

func TestE2E_UpdateStatus_Formed_TriggersPayment(t *testing.T) {
	// 1. Сначала создаем заказ, чтобы у нас был реальный ID
	newOrder := OrderDTO{UserID: 2, Amount: 100}
	createPayload, _ := json.Marshal(newOrder)
	
	createResp, err := http.Post(orderServiceURL+"/orders", "application/json", bytes.NewBuffer(createPayload))
	assert.NoError(t, err)
	defer createResp.Body.Close()

	var createdOrder OrderDTO
	bodyBytes, _ := io.ReadAll(createResp.Body)
	json.Unmarshal(bodyBytes, &createdOrder)
	orderID := createdOrder.ID

	// 2. Меняем статус заказа на "formed"
	// Это действие должно триггернуть gRPC вызов к сервису Оплаты
	statusUpdate := map[string]string{"status": "formed"}
	updatePayload, _ := json.Marshal(statusUpdate)
	
	client := &http.Client{}
	req, _ := http.NewRequest("PUT", fmt.Sprintf("%s/orders/%d/status", orderServiceURL, orderID), bytes.NewBuffer(updatePayload))
	req.Header.Set("Content-Type", "application/json")
	
	updateResp, err := client.Do(req)
	assert.NoError(t, err)
	defer updateResp.Body.Close()
	
	assert.Equal(t, http.StatusOK, updateResp.StatusCode)

	// Проверяем, что статус заказа действительно обновился
	var updatedOrder OrderDTO
	updateBody, _ := io.ReadAll(updateResp.Body)
	json.Unmarshal(updateBody, &updatedOrder)
	assert.Equal(t, "formed", updatedOrder.Status)

	// 3. ПРОВЕРКА ИНТЕГРАЦИИ (Вместо MockPaymentClient)
	// Мы идем в Payment Service и проверяем, создался ли там платеж для нашего заказа.
	
	// Небольшая задержка, на случай если gRPC вызов асинхронный (можно убрать, если синхронный)
	time.Sleep(100 * time.Millisecond)

	// Получаем все платежи (в идеале должен быть метод GetPaymentByOrderID, но используем список для простоты)
	paymentResp, err := http.Get(paymentServiceURL + "/payments")
	assert.NoError(t, err)
	defer paymentResp.Body.Close()

	var payments []PaymentDTO
	payBody, _ := io.ReadAll(paymentResp.Body)
	json.Unmarshal(payBody, &payments)

	// Ищем наш платеж
	var foundPayment *PaymentDTO
	for _, p := range payments {
		if p.OrderID == orderID { // Ищем платеж, привязанный к нашему ID заказа
			foundPayment = &p
			break
		}
	}

	// 4. Утверждаем, что платеж существует
	if assert.NotNil(t, foundPayment, "Платеж не был создан в Payment Service (gRPC вызов не прошел?)") {
		assert.Equal(t, "pending", foundPayment.Status)
		// Проверка суммы (опционально, если логика передает сумму)
		// assert.Equal(t, 100.0, foundPayment.Amount) 
	}
}