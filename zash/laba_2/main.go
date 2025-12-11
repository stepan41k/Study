package main

import (
	"fmt"
	"math"
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
	// Формула: X_{n+1} = (a*X_n + c) mod m
	gen.current = (gen.a*gen.current + gen.c) % gen.m
	return gen.current
}

// --- ЧАСТЬ 2: LFSR в поле GF(2^5) ---

// LFSR реализует генератор на основе матричного уравнения X_{k+1} = A * X_k
type LFSR struct {
	State        [5]int // Вектор состояния (биты), index 0 - младший, 4 - старший (или наоборот, зависит от интерпретации матрицы)
	Coefficients [5]int // Коэффициенты полинома (a_{n-1} ... a_0) для первой строки матрицы
}

// NewLFSR инициализирует генератор.
// polyCoeffs - коэффициенты при степенях x^4, x^3, x^2, x^1, x^0.
// Например, для x^5 + x + 1 (т.е. 1*x^1 + 1*x^0) -> [0, 0, 0, 1, 1]
func NewLFSR(polyCoeffs [5]int, seedVal int) *LFSR {
	lfsr := &LFSR{
		Coefficients: polyCoeffs,
	}
	// Преобразуем числовое зерно (seed) в битовый вектор
	// Предполагаем seed от 1 до 31
	if seedVal == 0 {
		seedVal = 1 // Нулевое состояние для LFSR недопустимо (зациклится на 0)
	}
	for i := 0; i < 5; i++ {
		lfsr.State[i] = (seedVal >> i) & 1
	}
	// Важно: По заданию матрица A имеет вид:
	// Строка 0: a4 a3 a2 a1 a0
	// Строка 1: 1  0  0  0  0
	// ...
	// Это значит вектор X_k должен интерпретироваться как столбец.
	// Примем State[4] как верхний элемент, State[0] как нижний.
	
	return lfsr
}

func (gen *LFSR) Next() int {
	// Сохраняем текущее состояние для вывода числа
	// Преобразуем биты в число 1-32
	val := 0
	for i := 0; i < 5; i++ {
		val |= gen.State[i] << i
	}
	
	// Вычисляем следующее состояние: X_{k+1} = A * X_k
	// Матрица A (по заданию):
	// [ a4 a3 a2 a1 a0 ]
	// [ 1  0  0  0  0  ]
	// [ 0  1  0  0  0  ]
	// [ 0  0  1  0  0  ]
	// [ 0  0  0  1  0  ]
	
	// Вектор X_k = [x4, x3, x2, x1, x0]^T (где x4 - верхний)
	// В нашей структуре State[4] это x4.
	
	newState := [5]int{}
	
	// 1. Вычисляем верхний элемент (первая строка матрицы умножается на столбец)
	// new_x4 = sum(ai * xi) mod 2
	topBit := 0
	for i := 0; i < 5; i++ {
		// Coefficients идут как a4, a3, a2, a1, a0
		// State мы храним так, что State[4] это x4.
		// Индекс i=0 соответствует a4 и x4.
		coeffIdx := i 
		stateIdx := 4 - i 
		
		topBit ^= (gen.Coefficients[coeffIdx] * gen.State[stateIdx])
	}
	newState[4] = topBit & 1
	
	// 2. Остальные элементы - это сдвиг (умножение на единичную поддиагональ)
	// new_x3 = x4
	// new_x2 = x3
	// ...
	newState[3] = gen.State[4]
	newState[2] = gen.State[3]
	newState[1] = gen.State[2]
	newState[0] = gen.State[1]
	
	gen.State = newState
	
	// Возвращаем числовое значение (коррекция +1, чтобы диапазон был 1-32)
	return val + 1
}

// --- ЧАСТЬ 3: Анализатор (Гистограмма и Энтропия) ---

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
	
	// Энтропия H(X) = - sum p(x) log2 p(x)
	for k, v := range res.Counts {
		p := v / float64(res.Total)
		res.Probs[k] = p
		if p > 0 {
			res.Entropy -= p * math.Log2(p)
		}
	}
	
	return res
}

func PrintAnalysis(title string, seq []int) {
	analysis := AnalyzeSequence(seq)
	
	fmt.Printf("\n--- %s ---\n", title)
	fmt.Printf("Последовательность (первые 20): %v...\n", seq[:min(len(seq), 20)])
	fmt.Printf("Длина: %d\n", len(seq))
	fmt.Printf("Энтропия: %.4f бит\n", analysis.Entropy)
	
	// Идеальная энтропия для диапазона
	// Для LCG диапазон зависит от m, для LFSR диапазон 32.
	// H_max = log2(N)
	
	fmt.Println("Гистограмма:")
	// Сортировка ключей для красивого вывода
	minVal, maxVal := 1000, -1
	for k := range analysis.Counts {
		if k < minVal { minVal = k }
		if k > maxVal { maxVal = k }
	}
	
	for i := minVal; i <= maxVal; i++ {
		if p, ok := analysis.Probs[i]; ok {
			barLen := int(p * 50) // Масштабирование
			fmt.Printf("%3d | %.4f | %s\n", i, p, strings.Repeat("█", barLen))
		}
	}
}

func min(a, b int) int {
	if a < b { return a }
	return b
}

// --- MAIN ---

func main() {
	// 1. Работа с LCG
	// Вариант 15 из таблицы
	// Набор 1: a=37, c=67, m=13
	// Набор 2: a=42, c=70, m=29
	
	lcgParams := []struct{ a, c, m int }{
		{37, 67, 13},
		{42, 70, 29},
	}
	
	lengths := []int{20, 50, 100}
	
	fmt.Println("==========================================")
	fmt.Println("ЗАДАНИЕ 1: Линейный конгруэнтный генератор (LCG)")
	fmt.Println("==========================================")

	for i, p := range lcgParams {
		fmt.Printf("\n>>> Параметры LCG #%d: a=%d, c=%d, m=%d\n", i+1, p.a, p.c, p.m)
		
		// Проверка условий максимального периода (для справки)
		// (c, m) == 1 ?
		// b = a-1 кратно p (делителям m)?
		// Если m кратно 4, b кратно 4?
		// Здесь мы просто запускаем генерацию.
		
		for _, l := range lengths {
			gen := NewLCG(p.a, p.c, p.m, 0) // Seed 0
			seq := make([]int, 0, l)
			for k := 0; k < l; k++ {
				seq = append(seq, gen.Next())
			}
			
			title := fmt.Sprintf("LCG (m=%d) Length=%d", p.m, l)
			PrintAnalysis(title, seq)
		}
	}

	fmt.Println("\n==========================================")
	fmt.Println("ЗАДАНИЕ 2: LFSR (GF(2^5))")
	fmt.Println("==========================================")
	
	// Полиномы для теста
	// 1. x^5 + x + 1. Коэффициенты для x^4..x^0: 0, 0, 0, 1, 1
	// 2. x^5 + x^3 + 1. Коэффициенты для x^4..x^0: 0, 1, 0, 0, 1
	// 3. x^5 + x^4 + x^2 + x + 1. Коэффициенты: 1, 0, 1, 1, 1
	
	polys := []struct {
		name   string
		coeffs [5]int
	}{
		{"x^5 + x + 1", [5]int{0, 0, 0, 1, 1}},
		{"x^5 + x^3 + 1", [5]int{0, 1, 0, 0, 1}},
		{"x^5 + x^4 + x^2 + x + 1", [5]int{1, 0, 1, 1, 1}},
	}

	for _, poly := range polys {
		fmt.Printf("\n>>> Полином: %s\n", poly.name)
		
		for _, l := range lengths {
			// Seed = 1 (начальное состояние 00001)
			gen := NewLFSR(poly.coeffs, 1) 
			seq := make([]int, 0, l)
			for k := 0; k < l; k++ {
				seq = append(seq, gen.Next())
			}
			
			// Ожидаемый диапазон значений: 1 - 32
			title := fmt.Sprintf("LFSR %s Length=%d", poly.name, l)
			PrintAnalysis(title, seq)
		}
	}
}