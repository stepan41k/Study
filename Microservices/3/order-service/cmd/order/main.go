package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	_ "github.com/mattn/go-sqlite3" 
)

type Order struct {
	ID     int     `json:"id"`
	Item   string  `json:"item"`
	Amount float64 `json:"amount"`
	Status string  `json:"status"` // например: "создан", "сформировано", "оплачено", "доставляется"
}

var db *sql.DB // Глобальная переменная для подключения к БД

func initDB() {
	var err error
	db, err = sql.Open("sqlite3", "./orders.db")
	if err != nil {
		log.Fatal(err)
	}

	createTableSQL := `CREATE TABLE IF NOT EXISTS orders (
		"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
		"item" TEXT,
		"amount" REAL,
		"status" TEXT
	)`;

	_, err = db.Exec(createTableSQL)
	if err != nil {
		log.Fatal(err)
	}
}

func createOrderHandler(w http.ResponseWriter, r *http.Request) {
	var newOrder Order
	if err := json.NewDecoder(r.Body).Decode(&newOrder); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Вставляем заказ в БД
	result, err := db.Exec("INSERT INTO orders (item, amount, status) VALUES (?, ?, ?)", newOrder.Item, newOrder.Amount, newOrder.Status)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	id, err := result.LastInsertId()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	newOrder.ID = int(id)

	// Если заказ "сформирован", создаем оплату
	if newOrder.Status == "сформировано" {
		if err := createPayment(newOrder.ID, newOrder.Amount); err != nil {
			log.Printf("Ошибка при создании оплаты для заказа %d: %v", newOrder.ID, err)
		}
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(newOrder)
}

func getOrdersHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query("SELECT id, item, amount, status FROM orders")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var orders []Order
	for rows.Next() {
		var o Order
		if err := rows.Scan(&o.ID, &o.Item, &o.Amount, &o.Status); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		orders = append(orders, o)
	}
	json.NewEncoder(w).Encode(orders)
}

func getOrderHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Неверный ID заказа", http.StatusBadRequest)
		return
	}

	var o Order
	err = db.QueryRow("SELECT id, item, amount, status FROM orders WHERE id = ?", id).Scan(&o.ID, &o.Item, &o.Amount, &o.Status)
	if err != nil {
		if err == sql.ErrNoRows {
			http.NotFound(w, r)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}
	json.NewEncoder(w).Encode(o)
}

func updateOrderStatusHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Неверный ID заказа", http.StatusBadRequest)
		return
	}

	var statusUpdate struct {
		Status string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&statusUpdate); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err = db.Exec("UPDATE orders SET status = ? WHERE id = ?", statusUpdate.Status, id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	log.Printf("Статус заказа %d обновлен на '%s'", id, statusUpdate.Status)

	// Если заказ оплачен, инициируем доставку
	if statusUpdate.Status == "оплачено" {
		if err := createShipping(id, "Стандартный адрес доставки"); err != nil {
			log.Printf("Ошибка при создании доставки для заказа %d: %v", id, err)
		}
	}

	w.WriteHeader(http.StatusOK)
}

// Функции createPayment и createShipping остаются без изменений

func createPayment(orderID int, amount float64) error {
	// ... (код без изменений)
	paymentRequest := map[string]interface{}{"order_id": orderID, "amount": amount}
	jsonData, err := json.Marshal(paymentRequest)
	if err != nil { return err }
	resp, err := http.Post("http://payment-service:8052/payments", "application/json", bytes.NewBuffer(jsonData))
	if err != nil { return err }
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusCreated { return fmt.Errorf("сервис оплаты вернул статус: %s", resp.Status) }
	return nil
}

func createShipping(orderID int, address string) error {
	// ... (код без изменений)
	shippingRequest := map[string]interface{}{"order_id": orderID, "address": address}
	jsonData, err := json.Marshal(shippingRequest)
	if err != nil { return err }
	resp, err := http.Post("http://shipping-service:8053/shipping", "application/json", bytes.NewBuffer(jsonData))
	if err != nil { return err }
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusCreated { return fmt.Errorf("сервис доставки вернул статус: %s", resp.Status) }
	return nil
}


func main() {
	initDB()
	defer db.Close()

	r := mux.NewRouter()
	r.HandleFunc("/orders", createOrderHandler).Methods("POST")
	r.HandleFunc("/orders", getOrdersHandler).Methods("GET")
	r.HandleFunc("/orders/{id}", getOrderHandler).Methods("GET")
	r.HandleFunc("/orders/{id}/status", updateOrderStatusHandler).Methods("PUT")

	fmt.Println("Сервис заказов запущен на порту 8051")
	log.Fatal(http.ListenAndServe(":8051", r))
}