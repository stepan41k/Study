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

// Структура для парсинга ответов (дублируем, так как в тестах пакета main она видна, 
// но если это отдельный пакет - нужно объявить)
type UserDTO struct {
	ID    uint   `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}

const baseURL = "http://localhost:8081"

// Вспомогательная функция для генерации уникального email
func generateUniqueEmail(prefix string) string {
	return fmt.Sprintf("%s_%d@test.com", prefix, time.Now().UnixNano())
}

func TestE2E_CreateUser(t *testing.T) {
	// 1. Подготовка данных
	// Важно: генерируем уникальный email, иначе при втором запуске теста будет ошибка 500 (Unique constraint)
	user := UserDTO{
		Name:  "TestUser",
		Email: generateUniqueEmail("create"),
	}
	jsonValue, _ := json.Marshal(user)

	// 2. Выполнение реального HTTP запроса к запущенному сервису
	resp, err := http.Post(baseURL+"/users", "application/json", bytes.NewBuffer(jsonValue))
	assert.NoError(t, err)
	defer resp.Body.Close()

	// 3. Проверка
	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var responseUser UserDTO
	// Читаем тело ответа
	body, _ := io.ReadAll(resp.Body)
	err = json.Unmarshal(body, &responseUser)
	assert.NoError(t, err)

	assert.Equal(t, user.Name, responseUser.Name)
	assert.Equal(t, user.Email, responseUser.Email)
	assert.NotZero(t, responseUser.ID)
}

func TestE2E_GetUsers(t *testing.T) {
	// 1. Сначала создадим пару пользователей через API, чтобы список точно не был пустым
	// (мы не можем использовать db.Create напрямую)
	usersToCreate := []UserDTO{
		{Name: "Alice", Email: generateUniqueEmail("alice")},
		{Name: "Bob", Email: generateUniqueEmail("bob")},
	}

	for _, u := range usersToCreate {
		val, _ := json.Marshal(u)
		http.Post(baseURL+"/users", "application/json", bytes.NewBuffer(val))
	}

	// 2. Выполняем запрос на получение списка
	resp, err := http.Get(baseURL + "/users")
	assert.NoError(t, err)
	defer resp.Body.Close()

	// 3. Проверка
	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var users []UserDTO
	body, _ := io.ReadAll(resp.Body)
	err = json.Unmarshal(body, &users)
	assert.NoError(t, err)

	// Проверяем, что в списке есть как минимум те двое, кого мы создали (или больше)
	assert.GreaterOrEqual(t, len(users), 2)
}

func TestE2E_GetUserByID(t *testing.T) {
	// 1. Подготовка: Сначала СОЗДАЕМ пользователя, чтобы получить реальный ID.
	// Мы не можем запрашивать ID=1, так как он может быть удален или занят другим тестом.
	newUser := UserDTO{
		Name:  "Charlie",
		Email: generateUniqueEmail("charlie"),
	}
	jsonValue, _ := json.Marshal(newUser)
	
	createResp, err := http.Post(baseURL+"/users", "application/json", bytes.NewBuffer(jsonValue))
	assert.NoError(t, err)
	defer createResp.Body.Close()

	var createdUser UserDTO
	bodyBytes, _ := io.ReadAll(createResp.Body)
	json.Unmarshal(bodyBytes, &createdUser)
	
	realID := createdUser.ID
	assert.NotZero(t, realID, "Не удалось создать пользователя для теста")

	// 2. Выполнение запроса GET по полученному ID
	getResp, err := http.Get(fmt.Sprintf("%s/users/%d", baseURL, realID))
	assert.NoError(t, err)
	defer getResp.Body.Close()

	// 3. Проверка
	assert.Equal(t, http.StatusOK, getResp.StatusCode)

	var fetchedUser UserDTO
	getBody, _ := io.ReadAll(getResp.Body)
	json.Unmarshal(getBody, &fetchedUser)

	assert.Equal(t, "Charlie", fetchedUser.Name)
	assert.Equal(t, createdUser.Email, fetchedUser.Email)
	assert.Equal(t, realID, fetchedUser.ID)
}