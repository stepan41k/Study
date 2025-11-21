package main

import (
	"fmt"
	"math"
)

// lcg реализует Линейный конгруэнтный генератор.
// Xn+1 = (a * Xn + c) mod m
func lcg(a, c, m, seed, n int) []int {
	result := make([]int, n)
	x := seed
	for i := 0; i < n; i++ {
		x = (a*x + c) % m
		result[i] = x
	}
	return result
}

// lfsr реализует Линейный рекуррентный генератор (регистр сдвига с линейной обратной связью).
// Используется неприводимый полином x^5 + x^2 + 1 для n=5.
// Это соответствует отводам от 5-го и 2-го битов.
func lfsr(seed uint, n int) []int {
	result := make([]int, n)
	// Состояние регистра не должно быть нулевым.
	if seed == 0 {
		seed = 1
	}
	lfsrState := seed & 0b11111 // Убедимся, что состояние 5-битное

	for i := 0; i < n; i++ {
		// Для полинома x^5 + x^2 + 1, отводы находятся в позициях 5 и 2.
		// В 5-битном регистре (биты от 0 до 4) это соответствует XOR битов 4 и 1.
		bit4 := (lfsrState >> 4) & 1
		bit1 := (lfsrState >> 1) & 1
		newBit := bit4 ^ bit1

		// Сдвигаем регистр вправо и устанавливаем новый старший бит
		lfsrState = (lfsrState >> 1) | (newBit << 4)

		result[i] = int(lfsrState)
	}
	return result
}

// calculateFrequency вычисляет частоту каждого числа в последовательности.
func calculateFrequency(sequence []int) map[int]int {
	freq := make(map[int]int)
	for _, num := range sequence {
		freq[num]++
	}
	return freq
}

// calculateEntropy вычисляет энтропию Шеннона для последовательности.
func calculateEntropy(sequence []int) float64 {
	freq := calculateFrequency(sequence)
	total := float64(len(sequence))
	if total == 0 {
		return 0
	}

	entropy := 0.0
	for _, count := range freq {
		probability := float64(count) / total
		if probability > 0 {
			entropy -= probability * math.Log2(probability)
		}
	}
	return entropy
}

// analyzeAndPrint выполняет анализ и выводит результаты.
func analyzeAndPrint(title string, sequence []int) {
	fmt.Println(title)
	fmt.Println("--------------------------------------------------")
	fmt.Printf("Сгенерированная последовательность (длина %d):\n%v\n", len(sequence), sequence)

	freq := calculateFrequency(sequence)
	fmt.Println("Гистограмма (частотный анализ):")
	for num, count := range freq {
		fmt.Printf("  Число %2d: %d раз\n", num, count)
	}

	entropy := calculateEntropy(sequence)
	fmt.Printf("Энтропия последовательности: %.4f\n", entropy)
	fmt.Println()
}

func main() {
	// Параметры для LCG
	lcgParams := []struct{ a, c, m int }{
		{37, 67, 13}, {37, 67, 29},
		{37, 70, 13}, {37, 70, 29},
		{42, 67, 13}, {42, 67, 29},
		{42, 70, 13}, {42, 70, 29},
	}
	// Длины генерируемых последовательностей
	lengths := []int{20, 50, 100}
	lcgSeed := 1 // Начальное значение для LCG

	fmt.Println("=============== Лабораторная работа 2 ===============")
	fmt.Println("======= Генераторы псевдослучайных величин =======\n")

	fmt.Println("--- Анализ Линейного конгруэнтного генератора (LCG) ---")
	for _, params := range lcgParams {
		for _, length := range lengths {
			sequence := lcg(params.a, params.c, params.m, lcgSeed, length)
			title := fmt.Sprintf("LCG с параметрами: a=%d, c=%d, m=%d, длина=%d", params.a, params.c, params.m, length)
			analyzeAndPrint(title, sequence)
		}
	}

	fmt.Println("\n--- Анализ Линейного рекуррентного генератора (LFSR) ---")
	var lfsrSeed uint = 21 // Начальное значение для LFSR (любое ненулевое 5-битное число, например, 0b10101)
	for _, length := range lengths {
		sequence := lfsr(lfsrSeed, length)
		title := fmt.Sprintf("LFSR (n=5, полином x^5+x^2+1), начальное значение=%d, длина=%d", lfsrSeed, length)
		analyzeAndPrint(title, sequence)
	}
}