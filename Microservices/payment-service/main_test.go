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

// DTO структуры для взаимодействия с REST API микросервисов
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

type ShippingDTO struct {
	ID      uint   `json:"id"`
	OrderID uint   `json:"order_id"`
	Status  string `json:"status"`
}

// Константы URL сервисов (согласно docker-compose)
const (
	orderServiceURL    = "http://localhost:8082"
	paymentServiceURL  = "http://localhost:8083"
	shippingServiceURL = "http://localhost:8084" // или /deliveries, в зависимости от роутинга
)

func TestE2E_ProcessPayment(t *testing.T) {
	// --- 1. ПОДГОТОВКА (SETUP) ---
	
	// Шаг 1. Создаем РЕАЛЬНЫЙ заказ в Order Service.
	// Нам нужен существующий OrderID, иначе Payment Service при попытке обновить статус заказа по gRPC
	// может получить ошибку "Order not found", если в БД заказов пусто.
	newOrder := OrderDTO{UserID: 10, Amount: 200, Status: "created"}
	orderPayload, _ := json.Marshal(newOrder)
	
	orderResp, err := http.Post(orderServiceURL+"/orders", "application/json", bytes.NewBuffer(orderPayload))
	assert.NoError(t, err)
	defer orderResp.Body.Close()
	
	var createdOrder OrderDTO
	orderBody, _ := io.ReadAll(orderResp.Body)
	json.Unmarshal(orderBody, &createdOrder)
	realOrderID := createdOrder.ID
	assert.NotZero(t, realOrderID, "Не удалось создать подготовительный заказ")

	// Шаг 2. Создаем платеж в Payment Service со статусом "pending".
	// Мы привязываем его к только что созданному realOrderID.
	newPayment := PaymentDTO{OrderID: realOrderID, Amount: 200}
	paymentPayload, _ := json.Marshal(newPayment)

	// Предполагаем, что есть ручка POST /payments (или она вызывается автоматически,
	// но для теста мы создаем платеж вручную, чтобы иметь точный ID).
	payCreateResp, err := http.Post(paymentServiceURL+"/payments", "application/json", bytes.NewBuffer(paymentPayload))
	assert.NoError(t, err)
	defer payCreateResp.Body.Close()

	var createdPayment PaymentDTO
	payBody, _ := io.ReadAll(payCreateResp.Body)
	json.Unmarshal(payBody, &createdPayment)
	paymentID := createdPayment.ID
	assert.Equal(t, "pending", createdPayment.Status)


	// --- 2. ДЕЙСТВИЕ (ACTION) ---

	// Выполняем запрос на оплату (тот самый endpoint, который мы тестируем)
	// PUT /payments/{id}/pay
	client := &http.Client{}
	payReq, _ := http.NewRequest("PUT", fmt.Sprintf("%s/payments/%d/pay", paymentServiceURL, paymentID), nil)
	
	payProcessResp, err := client.Do(payReq)
	assert.NoError(t, err)
	defer payProcessResp.Body.Close()

	// Проверяем HTTP статус ответа
	assert.Equal(t, http.StatusOK, payProcessResp.StatusCode)


	// --- 3. ПРОВЕРКА (ASSERTION / VERIFICATION) ---

	// Проверка А: Статус платежа в Payment Service изменился на "paid"?
	// Делаем GET запрос, так как DB скрыта
	// (В реальном коде можно проверить тело payProcessResp, если оно возвращает обновленный объект)
	// checkPayResp, _ := http.Get(fmt.Sprintf("%s/payments?id=%d", paymentServiceURL, paymentID)) // Или перебор списка
	// Для простоты, предположим, что PUT возвращает обновленный JSON:
	var updatedPayment PaymentDTO
	payProcessBody, _ := io.ReadAll(payProcessResp.Body)
	json.Unmarshal(payProcessBody, &updatedPayment)
	
	// Если API возвращает обновленный объект - проверяем его. Если нет - делаем GET.
	// Допустим, API вернул обновленный:
	assert.Equal(t, "paid", updatedPayment.Status)


	// Проверка Б (Замена MockOrderClient): Уведомлен ли Order Service?
	// Мы проверяем это косвенно: статус заказа в сервисе заказов должен стать "paid".
	// Даем небольшую задержку на асинхронную обработку (если она есть)
	time.Sleep(100 * time.Millisecond)

	checkOrderResp, err := http.Get(fmt.Sprintf("%s/orders/%d", orderServiceURL, realOrderID))
	assert.NoError(t, err)
	defer checkOrderResp.Body.Close()

	var updatedOrder OrderDTO
	checkOrderBody, _ := io.ReadAll(checkOrderResp.Body)
	json.Unmarshal(checkOrderBody, &updatedOrder)

	assert.Equal(t, "paid", updatedOrder.Status, "Статус заказа должен обновиться через gRPC вызов")


	// Проверка В (Замена MockShippingClient): Уведомлен ли Shipping Service?
	// Проверяем, появилась ли запись о доставке для этого заказа.
	checkShipResp, err := http.Get(shippingServiceURL + "/shippings") // или /deliveries
	assert.NoError(t, err)
	defer checkShipResp.Body.Close()

	var shippings []ShippingDTO
	shipBody, _ := io.ReadAll(checkShipResp.Body)
	json.Unmarshal(shipBody, &shippings)

	foundShipping := false
	for _, s := range shippings {
		if s.OrderID == realOrderID {
			foundShipping = true
			// Можно проверить начальный статус доставки, например "prepared"
			// assert.Equal(t, "prepared", s.Status)
			break
		}
	}
	assert.True(t, foundShipping, "Сущность доставки должна быть создана в Shipping Service")
}