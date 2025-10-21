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
	_ "github.com/mattn/go-sqlite3" // Импортируем драйвер SQLite
)

type Payment struct {
	ID      int     `json:"id"`
	OrderID int     `json:"order_id"`
	Amount  float64 `json:"amount"`
	Status  string  `json:"status"` // например: "ожидает", "оплачено"
}

var db *sql.DB // Глобальная переменная для подключения к БД

func initDB() {
	var err error
	db, err = sql.Open("sqlite3", "./payments.db")
	if err != nil {
		log.Fatal(err)
	}

	createTableSQL := `CREATE TABLE IF NOT EXISTS payments (
		"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
		"order_id" INTEGER,
		"amount" REAL,
		"status" TEXT
	);`

	_, err = db.Exec(createTableSQL)
	if err != nil {
		log.Fatal(err)
	}
}

func createPaymentHandler(w http.ResponseWriter, r *http.Request) {
	var newPayment Payment
	if err := json.NewDecoder(r.Body).Decode(&newPayment); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	newPayment.Status = "ожидает" // Начальный статус
	result, err := db.Exec("INSERT INTO payments (order_id, amount, status) VALUES (?, ?, ?)", newPayment.OrderID, newPayment.Amount, newPayment.Status)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	id, err := result.LastInsertId()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	newPayment.ID = int(id)

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(newPayment)
}

func getPaymentsHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query("SELECT id, order_id, amount, status FROM payments")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var payments []Payment
	for rows.Next() {
		var p Payment
		if err := rows.Scan(&p.ID, &p.OrderID, &p.Amount, &p.Status); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		payments = append(payments, p)
	}
	json.NewEncoder(w).Encode(payments)
}

func getPaymentHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Неверный ID оплаты", http.StatusBadRequest)
		return
	}

	var p Payment
	err = db.QueryRow("SELECT id, order_id, amount, status FROM payments WHERE id = ?", id).Scan(&p.ID, &p.OrderID, &p.Amount, &p.Status)
	if err != nil {
		if err == sql.ErrNoRows {
			http.NotFound(w, r)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}
	json.NewEncoder(w).Encode(p)
}

func updatePaymentStatusHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Неверный ID оплаты", http.StatusBadRequest)
		return
	}

	var statusUpdate struct {
		Status string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&statusUpdate); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	
	// Получаем OrderID до обновления, чтобы знать, какой заказ уведомлять
	var orderID int
	err = db.QueryRow("SELECT order_id FROM payments WHERE id = ?", id).Scan(&orderID)
	if err != nil {
		http.Error(w, "Оплата не найдена", http.StatusNotFound)
		return
	}


	_, err = db.Exec("UPDATE payments SET status = ? WHERE id = ?", statusUpdate.Status, id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	log.Printf("Статус оплаты %d обновлен на '%s'", id, statusUpdate.Status)

	if statusUpdate.Status == "оплачено" {
		if err := notifyOrderPaid(orderID); err != nil {
			log.Printf("Ошибка при обновлении статуса заказа %d: %v", orderID, err)
		}
	}

	w.WriteHeader(http.StatusOK)
}

// Функция notifyOrderPaid остается без изменений
func notifyOrderPaid(orderID int) error {
	statusRequest := map[string]string{"status": "оплачено"}
	jsonData, err := json.Marshal(statusRequest)
	if err != nil { return err }
	req, err := http.NewRequest(http.MethodPut, fmt.Sprintf("http://order-service:8051/orders/%d/status", orderID), bytes.NewBuffer(jsonData))
	if err != nil { return err }
	req.Header.Set("Content-Type", "application/json")
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil { return err }
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK { return fmt.Errorf("сервис заказов вернул статус: %s", resp.Status) }
	return nil
}

func main() {
	initDB()
	defer db.Close()

	r := mux.NewRouter()
	r.HandleFunc("/payments", createPaymentHandler).Methods("POST")
	r.HandleFunc("/payments", getPaymentsHandler).Methods("GET")
	r.HandleFunc("/payments/{id}", getPaymentHandler).Methods("GET")
	r.HandleFunc("/payments/{id}/status", updatePaymentStatusHandler).Methods("PUT")

	fmt.Println("Сервис оплаты запущен на порту 8052")
	log.Fatal(http.ListenAndServe(":8052", r))
}