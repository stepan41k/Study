FROM golang:1.24-alpine

WORKDIR /app

# 1. Сначала копируем только файлы описания модулей
COPY go.mod go.sum ./

# 2. Скачиваем зависимости (используем кеш докера, если файлы не менялись)
RUN go mod download

# 3. Копируем исходный код
COPY . .

# 4. Собираем приложение
RUN go build -o main .

CMD ["./main"]