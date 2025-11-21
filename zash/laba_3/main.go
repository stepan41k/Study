package main

import (
	"fmt"
	"strings"
	"unicode"
)

// Алфавит из 32 букв (А-Я, исключая Ё)
const russianAlphabet = "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
const matrixRows = 4
const matrixCols = 8

// PlayfairCipher содержит ключевую матрицу и карту позиций для быстрого доступа.
type PlayfairCipher struct {
	matrix      [matrixRows][matrixCols]rune
	charPositions map[rune]struct{ row, col int }
}

// NewPlayfairCipher создает новый шифратор с заданным ключом.
func NewPlayfairCipher(key string) (*PlayfairCipher, error) {
	cipher := &PlayfairCipher{
		charPositions: make(map[rune]struct{ row, col int }),
	}

	// 1. Подготовка ключа и алфавита
	// Приводим ключ к верхнему регистру
	key = strings.ToUpper(key)
	
	// Создаем множество для уникальных символов ключа и алфавита
	alphabetSet := make(map[rune]bool)
	for _, r := range russianAlphabet {
		alphabetSet[r] = true
	}

	// Формируем последовательность для заполнения матрицы
	var sequence []rune
	usedChars := make(map[rune]bool)

	// Добавляем уникальные символы из ключа
	for _, r := range key {
		if !usedChars[r] && alphabetSet[r] {
			sequence = append(sequence, r)
			usedChars[r] = true
		}
	}

	// Добавляем оставшиеся символы алфавита
	for _, r := range russianAlphabet {
		if !usedChars[r] {
			sequence = append(sequence, r)
		}
	}
	
	if len(sequence) != len(russianAlphabet) {
		return nil, fmt.Errorf("ошибка при формировании последовательности для матрицы")
	}

	// 2. Заполнение матрицы
	k := 0
	for i := 0; i < matrixRows; i++ {
		for j := 0; j < matrixCols; j++ {
			char := sequence[k]
			cipher.matrix[i][j] = char
			cipher.charPositions[char] = struct{ row, col int }{i, j}
			k++
		}
	}

	return cipher, nil
}

// prepareText подготавливает текст для шифрования.
func (c *PlayfairCipher) prepareText(plaintext string) string {
	var builder strings.Builder
	
	// Приводим к верхнему регистру и удаляем неалфавитные символы
	for _, r := range plaintext {
		if unicode.IsLetter(r) {
			upperChar := unicode.ToUpper(r)
			// Заменяем Ё на Е, если нужно
			if upperChar == 'Ё' {
				upperChar = 'Е'
			}
			// Добавляем только символы из нашего алфавита
			if _, exists := c.charPositions[upperChar]; exists {
				builder.WriteRune(upperChar)
			}
		}
	}

	// Промежуточный результат после очистки
	prepared := builder.String()
	builder.Reset()

	runes := []rune(prepared)
	
	// Разбиваем на диграфы, вставляя заполнитель при необходимости
	for i := 0; i < len(runes); i++ {
		char1 := runes[i]
		builder.WriteRune(char1)

		if i+1 < len(runes) {
			char2 := runes[i+1]
			// Если символы в паре одинаковые, вставляем заполнитель 'Ъ'
			if char1 == char2 {
				builder.WriteRune('Ъ')
			} else {
				builder.WriteRune(char2)
				i++ // Пропускаем следующий символ, так как он уже обработан
			}
		} else {
			// Если остался один символ, добавляем заполнитель
			builder.WriteRune('Ъ')
		}
	}

	return builder.String()
}

// Encrypt шифрует подготовленный текст.
func (c *PlayfairCipher) Encrypt(plaintext string) (string, error) {
	preparedText := c.prepareText(plaintext)
	runes := []rune(preparedText)
	var encryptedText strings.Builder

	// Шифруем по парам
	for i := 0; i < len(runes); i += 2 {
		char1 := runes[i]
		char2 := runes[i+1]

		pos1, ok1 := c.charPositions[char1]
		pos2, ok2 := c.charPositions[char2]

		if !ok1 || !ok2 {
			return "", fmt.Errorf("символ '%c' или '%c' не найден в матрице", char1, char2)
		}

		var newChar1, newChar2 rune

		// Правило 1: Буквы в одной строке
		if pos1.row == pos2.row {
			newChar1 = c.matrix[pos1.row][(pos1.col+1)%matrixCols]
			newChar2 = c.matrix[pos2.row][(pos2.col+1)%matrixCols]
		} else if pos1.col == pos2.col { // Правило 2: Буквы в одном столбце
			newChar1 = c.matrix[(pos1.row+1)%matrixRows][pos1.col]
			newChar2 = c.matrix[(pos2.row+1)%matrixRows][pos2.col]
		} else { // Правило 3: Буквы образуют прямоугольник
			newChar1 = c.matrix[pos1.row][pos2.col]
			newChar2 = c.matrix[pos2.row][pos1.col]
		}
		
		encryptedText.WriteRune(newChar1)
		encryptedText.WriteRune(newChar2)
	}

	return encryptedText.String(), nil
}

// PrintMatrix выводит ключевую матрицу в консоль для проверки.
func (c *PlayfairCipher) PrintMatrix() {
	fmt.Println("Ключевая матрица:")
	for i := 0; i < matrixRows; i++ {
		for j := 0; j < matrixCols; j++ {
			fmt.Printf("%c ", c.matrix[i][j])
		}
		fmt.Println()
	}
}


func main() {
	// Пример использования
	password := "ШИФРОВАНИЕ"
	plaintext := "Лабораторная работа по традиционным методам шифрования"

	fmt.Printf("Исходный текст: %s\n", plaintext)
	fmt.Printf("Пароль: %s\n", password)
	fmt.Println("---")

	// Создаем экземпляр шифра
	cipher, err := NewPlayfairCipher(password)
	if err != nil {
		fmt.Printf("Ошибка создания шифра: %v\n", err)
		return
	}

	// Выводим матрицу
	cipher.PrintMatrix()
	fmt.Println("---")

	// Подготавливаем текст (для наглядности)
	prepared := cipher.prepareText(plaintext)
	fmt.Printf("Подготовленный текст: %s\n", prepared)
	
	// Шифруем
	encrypted, err := cipher.Encrypt(plaintext)
	if err != nil {
		fmt.Printf("Ошибка шифрования: %v\n", err)
		return
	}
	
	fmt.Printf("Зашифрованный текст: %s\n", encrypted)
}