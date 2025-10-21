package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
)

type Shipping struct {
	ID      int    `json:"id"`
	OrderID int    `json:"order_id"`
	Address string `json:"address"`
	Status  string `json:"status"` // например: "создана", "в пути", "доставлена"
}

var shipments []Shipping
var nextShippingID = 1

func createShippingHandler(w http.ResponseWriter, r *http.Request) {
	var newShipping Shipping
	if err := json.NewDecoder(r.Body).Decode(&newShipping); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	newShipping.ID = nextShippingID
	nextShippingID++
	newShipping.Status = "создана"
	shipments = append(shipments, newShipping)

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(newShipping)
}

func getShippingsHandler(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(shipments)
}

func getShippingHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Неверный ID доставки", http.StatusBadRequest)
		return
	}

	for _, shipping := range shipments {
		if shipping.ID == id {
			json.NewEncoder(w).Encode(shipping)
			return
		}
	}

	http.NotFound(w, r)
}

func main() {
	r := mux.NewRouter()
	r.HandleFunc("/shipping", createShippingHandler).Methods("POST")
	r.HandleFunc("/shipping", getShippingsHandler).Methods("GET")
	r.HandleFunc("/shipping/{id}", getShippingHandler).Methods("GET")

	fmt.Println("Сервис доставки запущен на порту 8053")
	log.Fatal(http.ListenAndServe(":8053", r))
}