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

// DTO для ответа (Shipping Service)
type ShippingDTO struct {
	ID      uint   `json:"id"`
	OrderID uint   `json:"order_id"`
	Status  string `json:"status"`
}

// Вспомогательные DTO для подготовки данных
type OrderCreateRequest struct {
	UserID uint    `json:"user_id"`
	Amount float64 `json:"amount"`
}
type OrderResponse struct {
	ID uint `json:"id"`
}
type PaymentCreateRequest struct {
	OrderID uint    `json:"order_id"`
	Amount  float64 `json:"amount"`
}
type PaymentResponse struct {
	ID uint `json:"id"`
}

const (
	orderSvcURL    = "http://localhost:8082"
	paymentSvcURL  = "http://localhost:8083"
	shippingSvcURL = "http://localhost:8084"
)

func TestE2E_GetShippings(t *testing.T) {
	// --- ШАГ 1: ПОДГОТОВКА ДАННЫХ (SETUP) ---
	// Нам нужно создать доставку. Напрямую это сделать нельзя (согласно бизнес-логике),
	// поэтому мы проходим цепочку: Заказ -> Оплата -> Доставка.

	// 1.1 Создаем заказ
	orderPayload, _ := json.Marshal(OrderCreateRequest{UserID: 55, Amount: 150})
	oResp, err := http.Post(orderSvcURL+"/orders", "application/json", bytes.NewBuffer(orderPayload))
	assert.NoError(t, err)
	var createdOrder OrderResponse
	_ = json.NewDecoder(oResp.Body).Decode(&createdOrder)
	oResp.Body.Close()
	
	// 1.2 Создаем платеж
	payPayload, _ := json.Marshal(PaymentCreateRequest{OrderID: createdOrder.ID, Amount: 150})
	pResp, err := http.Post(paymentSvcURL+"/payments", "application/json", bytes.NewBuffer(payPayload))
	assert.NoError(t, err)
	var createdPayment PaymentResponse
	_ = json.NewDecoder(pResp.Body).Decode(&createdPayment)
	pResp.Body.Close()

	// 1.3 Проводим оплату (триггер создания доставки)
	client := &http.Client{}
	req, _ := http.NewRequest("PUT", fmt.Sprintf("%s/payments/%d/pay", paymentSvcURL, createdPayment.ID), nil)
	payProcResp, err := client.Do(req)
	assert.NoError(t, err)
	payProcResp.Body.Close()
	assert.Equal(t, http.StatusOK, payProcResp.StatusCode)

	// Даем системе немного времени на асинхронное создание доставки (gRPC вызовы)
	time.Sleep(200 * time.Millisecond)

	// --- ШАГ 2: ТЕСТИРОВАНИЕ ENDPOINT (ACTION) ---
	
	// Выполняем запрос GET /shippings к реальному сервису
	resp, err := http.Get(shippingSvcURL + "/shippings")
	assert.NoError(t, err)
	defer resp.Body.Close()

	// --- ШАГ 3: ПРОВЕРКА (ASSERT) ---
	
	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var shippings []ShippingDTO
	body, _ := io.ReadAll(resp.Body)
	err = json.Unmarshal(body, &shippings)
	assert.NoError(t, err)

	// Проверяем, что список не пуст (как минимум одна доставка, которую мы только что инициировали, должна быть)
	assert.NotEmpty(t, shippings, "Список доставок не должен быть пустым после успешной оплаты")

	// (Опционально) Ищем конкретно нашу доставку
	found := false
	for _, s := range shippings {
		if s.OrderID == createdOrder.ID {
			found = true
			break
		}
	}
	assert.True(t, found, "В списке доставок должна присутствовать запись для нашего OrderID")
}