package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"strconv"
	"strings"
	"time"
)

// --- ЧАСТЬ 1: Линейный конгруэнтный генератор (LCG) ---

type LCG struct {
	a, c, m int
	current int
}

func NewLCG(a, c, m, seed int) *LCG {
	return &LCG{a: a, c: c, m: m, current: seed}
}

func (gen *LCG) Next() int {
	gen.current = (gen.a*gen.current + gen.c) % gen.m
	return gen.current
}

// --- ЧАСТЬ 2: LFSR через Умножение Матрицы на Вектор в GF(2) ---

type LFSR struct {
	State  [5]int    // Вектор состояния (столбец)
	Matrix [5][5]int // Переходная матрица 5x5
}

func NewLFSR(polyCoeffs [5]int, seedVal int) *LFSR {
	lfsr := &LFSR{}

	// Защита от нулевого начального состояния (для LFSR состояние "все нули" часто стационарно)
	if (seedVal & 0x1F) == 0 {
		seedVal = 1
		fmt.Println("Warning: Seed low bits were 0, forced to 1 to avoid stuck state.")
	}

	for i := 0; i < 5; i++ {
		lfsr.State[i] = (seedVal >> i) & 1
	}

	// Формирование матрицы (сдвиг + обратная связь)
	for r := 0; r < 4; r++ {
		lfsr.Matrix[r][r+1] = 1
	}
	for i := 0; i < 5; i++ {
		lfsr.Matrix[4][i] = polyCoeffs[4-i]
	}

	return lfsr
}

func (gen *LFSR) Next() int {
	var newState [5]int
	// Умножение матрицы на вектор
	for r := 0; r < 5; r++ {
		sum := 0
		for c := 0; c < 5; c++ {
			sum += gen.Matrix[r][c] * gen.State[c]
		}
		newState[r] = sum % 2
	}
	gen.State = newState

	// Перевод битов состояния в число
	val := 0
	for i := 0; i < 5; i++ {
		val |= gen.State[i] << i
	}

	return val
}

func (gen *LFSR) PrintMatrix() {
	fmt.Println("Переходная матрица M (где S_new = M * S_old):")
	fmt.Println("   c0 c1 c2 c3 c4")
	fmt.Println("  ---------------")
	for i := 0; i < 5; i++ {
		fmt.Printf("r%d| ", i)
		for j := 0; j < 5; j++ {
			if gen.Matrix[i][j] == 1 {
				fmt.Printf("1  ")
			} else {
				fmt.Printf(".  ")
			}
		}
		fmt.Println("|")
	}
	fmt.Println()
}

// --- ЧАСТЬ 3: Анализатор и Экспорт ---

type AnalysisResult struct {
	Counts  map[int]float64
	Probs   map[int]float64
	Entropy float64
	Total   int
}

func AnalyzeSequence(seq []int) AnalysisResult {
	res := AnalysisResult{
		Counts: make(map[int]float64),
		Probs:  make(map[int]float64),
	}
	res.Total = len(seq)

	for _, num := range seq {
		res.Counts[num]++
	}

	for k, v := range res.Counts {
		p := v / float64(res.Total)
		res.Probs[k] = p
		if p > 0 {
			res.Entropy -= p * math.Log2(p)
		}
	}

	return res
}

// saveHistogramToCSV теперь принимает rangeLimit (верхнюю границу диапазона)
func saveHistogramToCSV(filename string, analysis AnalysisResult, rangeLimit int) error {
	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("не удалось создать файл %s: %v", filename, err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	if err := writer.Write([]string{"Value", "Probability"}); err != nil {
		return err
	}

	// Итерируемся от 0 до rangeLimit-1, чтобы записать ВСЕ числа
	for i := 0; i < rangeLimit; i++ {
		prob := analysis.Probs[i] // Если ключа нет, вернется 0.0
		record := []string{
			strconv.Itoa(i),
			fmt.Sprintf("%.6f", prob),
		}
		if err := writer.Write(record); err != nil {
			return err
		}
	}
	return nil
}

// PrintAnalysis теперь принимает rangeLimit (верхнюю границу диапазона)
func PrintAnalysis(title string, seq []int, rangeLimit int) AnalysisResult {
	analysis := AnalyzeSequence(seq)

	fmt.Printf("\n--- %s ---\n", title)
	fmt.Printf("Длина выборки: %d, Энтропия: %.4f бит\n", len(seq), analysis.Entropy)

	// Находим максимальную вероятность для масштабирования гистограммы
	maxProb := 0.0
	for _, p := range analysis.Probs {
		if p > maxProb {
			maxProb = p
		}
	}

	const maxBarWidth = 40
	fmt.Println("Val |  Prob  | Histogram")
	fmt.Println("----|--------|----------------------------------------")

	// Цикл от 0 до rangeLimit-1 гарантирует вывод всех чисел диапазона
	for i := 0; i < rangeLimit; i++ {
		p := analysis.Probs[i] // Вернет 0.0, если числа не было в выборке
		
		barLen := 0
		if maxProb > 0 {
			barLen = int((p / maxProb) * maxBarWidth)
		}
		// Рисуем хотя бы один символ, если вероятность > 0, иначе пусто
		if barLen == 0 && p > 0 {
			barLen = 1
		}
		
		bar := ""
		if barLen > 0 {
			bar = strings.Repeat("█", barLen)
		} else {
			// bar = "_" // Визуальный маркер для нулевой вероятности (можно убрать)
		}

		fmt.Printf("%3d | %.4f | %s\n", i, p, bar)
	}
	return analysis
}

func main() {
	lengths := []int{20, 50, 100}

	lcgParams := []struct{ a, c, m int }{
		{37, 67, 13},
		{42, 70, 29},
	}

	fmt.Println("=== Генерация данных для LCG ===")

	for i, p := range lcgParams {
		for _, l := range lengths {
			gen := NewLCG(p.a, p.c, p.m, 0)
			seq := make([]int, 0, l)
			for k := 0; k < l; k++ {
				seq = append(seq, gen.Next())
			}

			title := fmt.Sprintf("LCG Set%d (m=%d) Len=%d", i+1, p.m, l)
			// Передаем p.m как rangeLimit, т.к. LCG генерирует числа < m
			res := PrintAnalysis(title, seq, p.m)

			filename := fmt.Sprintf("lcg_set%d_m%d_len%d.csv", i+1, p.m, l)
			if err := saveHistogramToCSV(filename, res, p.m); err != nil {
				fmt.Println("Ошибка сохранения:", err)
			}
		}
	}

	fmt.Println("\n=== Генерация данных для LFSR (Matrix Method) ===")

	polys := []struct {
		name      string
		shortName string
		coeffs    [5]int
	}{
		{"x^5 + x + 1", "poly1", [5]int{0, 0, 0, 1, 1}},
		{"x^5 + x^3 + 1", "poly2", [5]int{0, 1, 0, 0, 1}},
		{"x^5 + x^4 + x^2 + x + 1", "poly3", [5]int{1, 0, 1, 1, 1}},
	}

	// LFSR на 5 бит генерирует числа от 0 до 31. Всего 32 значения.
	lfsrRange := 32

	for _, poly := range polys {
		fmt.Printf("\n##################################################\n")
		fmt.Printf("Полином: %s\n", poly.name)
		
		tempGen := NewLFSR(poly.coeffs, 1)
		tempGen.PrintMatrix()

		for _, l := range lengths {
			seed := int(time.Now().UnixNano()) 
			gen := NewLFSR(poly.coeffs, seed+1)
			seq := make([]int, 0, l)
			for k := 0; k < l; k++ {
				seq = append(seq, gen.Next())
			}

			title := fmt.Sprintf("LFSR %s Len=%d", poly.name, l)
			// Передаем 32 как rangeLimit
			res := PrintAnalysis(title, seq, lfsrRange)

			filename := fmt.Sprintf("lfsr_%s_len%d.csv", poly.shortName, l)
			if err := saveHistogramToCSV(filename, res, lfsrRange); err != nil {
				fmt.Println("Ошибка сохранения:", err)
			}
		}
	}
}