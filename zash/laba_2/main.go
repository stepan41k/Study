package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"sort"
	"strconv"
	"strings"
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

// --- ЧАСТЬ 2: LFSR в поле GF(2^5) ---

type LFSR struct {
	State        [5]int
	Coefficients [5]int
}

func NewLFSR(polyCoeffs [5]int, seedVal int) *LFSR {
	lfsr := &LFSR{
		Coefficients: polyCoeffs,
	}
	if seedVal == 0 {
		seedVal = 1
	}
	for i := 0; i < 5; i++ {
		lfsr.State[i] = (seedVal >> i) & 1
	}
	return lfsr
}

func (gen *LFSR) Next() int {
	val := 0
	for i := 0; i < 5; i++ {
		val |= gen.State[i] << i
	}
	
	newState := [5]int{}
	topBit := 0
	for i := 0; i < 5; i++ {
		coeffIdx := i 
		stateIdx := 4 - i 
		topBit ^= (gen.Coefficients[coeffIdx] * gen.State[stateIdx])
	}
	newState[4] = topBit & 1
	
	newState[3] = gen.State[4]
	newState[2] = gen.State[3]
	newState[1] = gen.State[2]
	newState[0] = gen.State[1]
	
	gen.State = newState
	return val + 1
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

// saveHistogramToCSV сохраняет результаты в CSV файл
func saveHistogramToCSV(filename string, analysis AnalysisResult) error {
	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("не удалось создать файл %s: %v", filename, err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Записываем заголовок
	if err := writer.Write([]string{"Value", "Probability"}); err != nil {
		return err
	}

	// Сортируем ключи (числа), чтобы в CSV они шли по порядку
	keys := make([]int, 0, len(analysis.Probs))
	for k := range analysis.Probs {
		keys = append(keys, k)
	}
	sort.Ints(keys)

	// Записываем данные
	for _, k := range keys {
		prob := analysis.Probs[k]
		// Форматируем число и вероятность (6 знаков после запятой)
		record := []string{
			strconv.Itoa(k),
			fmt.Sprintf("%.6f", prob),
		}
		if err := writer.Write(record); err != nil {
			return err
		}
	}

	fmt.Printf(">> Результаты сохранены в файл: %s\n", filename)
	return nil
}

func PrintAnalysis(title string, seq []int) AnalysisResult {
	analysis := AnalyzeSequence(seq)
	
	fmt.Printf("\n--- %s ---\n", title)
	fmt.Printf("Длина: %d, Энтропия: %.4f бит\n", len(seq), analysis.Entropy)
	
	// Консольный вывод гистограммы (опционально, можно закомментировать)
	minVal, maxVal := 1000, -1
	for k := range analysis.Counts {
		if k < minVal { minVal = k }
		if k > maxVal { maxVal = k }
	}
	for i := minVal; i <= maxVal; i++ {
		if p, ok := analysis.Probs[i]; ok {
			barLen := int(p * 20) // Уменьшил масштаб для консоли
			fmt.Printf("%3d | %.4f | %s\n", i, p, strings.Repeat("█", barLen))
		}
	}
	return analysis
}

// --- MAIN ---

func main() {
	// LCG Параметры
	lcgParams := []struct{ a, c, m int }{
		{37, 67, 13},
		{42, 70, 29},
	}
	
	lengths := []int{20, 50, 100}
	
	fmt.Println("=== Генерация CSV файлов для LCG ===")

	for i, p := range lcgParams {
		for _, l := range lengths {
			gen := NewLCG(p.a, p.c, p.m, 0)
			seq := make([]int, 0, l)
			for k := 0; k < l; k++ {
				seq = append(seq, gen.Next())
			}
			
			title := fmt.Sprintf("LCG Set%d (m=%d) Len=%d", i+1, p.m, l)
			res := PrintAnalysis(title, seq)

			// Формируем имя файла: lcg_set1_m13_len20.csv
			filename := fmt.Sprintf("lcg_set%d_m%d_len%d.csv", i+1, p.m, l)
			if err := saveHistogramToCSV(filename, res); err != nil {
				fmt.Println("Ошибка сохранения:", err)
			}
		}
	}

	fmt.Println("\n=== Генерация CSV файлов для LFSR ===")
	
	polys := []struct {
		name   string
		shortName string // Короткое имя для файла
		coeffs [5]int
	}{
		{"x^5 + x + 1", "poly1", [5]int{0, 0, 0, 1, 1}},
		{"x^5 + x^3 + 1", "poly2", [5]int{0, 1, 0, 0, 1}},
		{"x^5 + x^4 + x^2 + x + 1", "poly3", [5]int{1, 0, 1, 1, 1}},
	}

	for _, poly := range polys {
		for _, l := range lengths {
			gen := NewLFSR(poly.coeffs, 1) 
			seq := make([]int, 0, l)
			for k := 0; k < l; k++ {
				seq = append(seq, gen.Next())
			}
			
			title := fmt.Sprintf("LFSR %s Len=%d", poly.name, l)
			res := PrintAnalysis(title, seq)

			// Формируем имя файла: lfsr_poly1_len20.csv
			filename := fmt.Sprintf("lfsr_%s_len%d.csv", poly.shortName, l)
			if err := saveHistogramToCSV(filename, res); err != nil {
				fmt.Println("Ошибка сохранения:", err)
			}
		}
	}
}