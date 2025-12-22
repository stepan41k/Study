package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)


func TestGetShippings(t *testing.T) {
	db.Create(&Shipping{OrderID: 1, UserID: 1, Status: "created"})

	r := gin.Default()
	r.GET("/shippings", func(c *gin.Context) {
		var shippings []Shipping
		db.Find(&shippings)
		c.JSON(http.StatusOK, shippings)
	})

	req, _ := http.NewRequest("GET", "/shippings", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	
	var list []Shipping
	json.Unmarshal(w.Body.Bytes(), &list)
	assert.Len(t, list, 1)
}