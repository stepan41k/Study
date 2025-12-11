package main

import (
	"fmt"
	"math"
	"math/rand"
	"os"
	"strings"
	"unicode"
)

// --- ГЛОБАЛЬНЫЕ КОНСТАНТЫ ---

var alphabetRunes = []rune("АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
var alphaMap map[rune]int

func init() {
	alphaMap = make(map[rune]int)
	for i, r := range alphabetRunes {
		alphaMap[r] = i
	}
}

// --- СТРУКТУРЫ ДЛЯ АНАЛИЗА ---

type TextAnalysis struct {
	Name      string
	TotalLen  float64
	CharProbs map[rune]float64
	Entropy   float64
}

// --- ФУНКЦИИ АНАЛИЗА ---

func analyzeText(name string, text string) *TextAnalysis {
	clean := cleanText(text)
	totalLen := float64(len([]rune(clean)))
	ta := &TextAnalysis{Name: name, TotalLen: totalLen, CharProbs: make(map[rune]float64)}
	if totalLen == 0 {
		return ta
	}
	counts := make(map[rune]float64)
	for _, r := range clean {
		counts[r]++
	}
	for _, r := range alphabetRunes {
		if count := counts[r]; count > 0 {
			p := count / totalLen
			ta.CharProbs[r] = p
			ta.Entropy -= p * math.Log2(p)
		}
	}
	return ta
}

func printReport(ta *TextAnalysis) {
	fmt.Printf("\n=== АНАЛИЗ: %s ===\n", ta.Name)
	fmt.Printf("Длина текста: %.0f симв.\n", ta.TotalLen)
	fmt.Printf("Энтропия H(A): %.4f бит (Максимум для Z32 = 5.0)\n", ta.Entropy)
	fmt.Println("Гистограмма (частоты символов):")
	const barScale = 200.0
	for _, r := range alphabetRunes {
		prob := ta.CharProbs[r]
		barLen := int(prob * barScale)
		bar := ""
		if barLen > 0 {
			bar = strings.Repeat("█", barLen)
		} else if prob > 0 {
			bar = "▏"
		}
		fmt.Printf("%c: %6.3f%% | %s\n", r, prob*100, bar)
	}
	fmt.Println()
}

func printPSP(ta *TextAnalysis) {
	fmt.Printf("\n=== АНАЛИЗ: %s ===\n", ta.Name)
	fmt.Printf("Длина текста: %.0f симв.\n", ta.TotalLen)
	fmt.Printf("Энтропия H(A): %.4f бит (Макс для Z32 = 5.0)\n", ta.Entropy)
	
	fmt.Println("Гистограмма (частоты символов):")
	// Выводим все 32 символа
	for i, r := range alphabetRunes {
		prob := ta.CharProbs[r]
		// Рисуем бар. Масштабируем: 10% = 10 символов '█'
		barLen := int(prob * 100 * 2) 
		bar := ""
		if barLen > 0 {
			bar = strings.Repeat("█", barLen)
		} else if prob > 0 {
			bar = "▏" // Если частота очень мала, но не 0
		}
		
		// Форматируем таблицу по 2 столбца для компактности
		fmt.Printf("%c: %5.2f%% %-12s ", r, prob*100, bar)
		if (i+1)%2 == 0 {
			fmt.Println()
		}
	}
	fmt.Println()
}

// --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---

func cleanText(text string) string {
	var sb strings.Builder
	for _, r := range text {
		r = unicode.ToUpper(r)
		if r == 'Ё' {
			r = 'Е'
		}
		if _, ok := alphaMap[r]; ok {
			sb.WriteRune(r)
		}
	}
	return sb.String()
}

func saveToFile(filename string, content string) error {
	// os.WriteFile создает файл, если его нет, или перезаписывает, если он есть.
	// 0644 - это стандартные права доступа для файла.
	return os.WriteFile(filename, []byte(content), 0644)
}

// --- БЛОК ШИФРОВАНИЯ ---

// 1. Плейфейер
func encryptPlayfair(text string, key string) string {
	key = cleanText(key)
	seen := make(map[rune]bool)
	var matrixElements []rune
	for _, r := range key {
		if !seen[r] {
			seen[r] = true
			matrixElements = append(matrixElements, r)
		}
	}
	for _, r := range alphabetRunes {
		if !seen[r] {
			seen[r] = true
			matrixElements = append(matrixElements, r)
		}
	}
	var matrix [4][8]rune
	for i := 0; i < 32; i++ {
		matrix[i/8][i%8] = matrixElements[i]
	}
	findPos := func(char rune) (int, int) {
		for r := 0; r < 4; r++ {
			for c := 0; c < 8; c++ {
				if matrix[r][c] == char {
					return r, c
				}
			}
		}
		return 0, 0
	}
	text = cleanText(text)
	runes := []rune(text)
	var sb strings.Builder
	for i := 0; i < len(runes); i++ {
		r1 := runes[i]
		var r2 rune
		if i+1 < len(runes) {
			r2 = runes[i+1]
			if r1 == r2 {
				r2 = 'Ъ'; i--
			}
		} else {
			r2 = 'Ъ'
		}
		row1, col1 := findPos(r1)
		row2, col2 := findPos(r2)
		if row1 == row2 {
			col1, col2 = (col1+1)%8, (col2+1)%8
		} else if col1 == col2 {
			row1, row2 = (row1+1)%4, (row2+1)%4
		} else {
			col1, col2 = col2, col1
		}
		sb.WriteRune(matrix[row1][col1])
		sb.WriteRune(matrix[row2][col2])
		i++
	}
	return sb.String()
}

// 2. Аддитивный шифр
type KeyGen func(i int) int

func encryptAdditive(text string, kg KeyGen) string {
	text = cleanText(text)
	var sb strings.Builder
	for i, p := range []rune(text) {
		pIdx, k := alphaMap[p], kg(i)
		cIdx := (pIdx + k) % 32
		sb.WriteRune(alphabetRunes[cIdx])
	}
	return sb.String()
}

// --- ГЕНЕРАТОР ПСП (LFSR) ИЗ РАБОТЫ 2 ---

// LFSR реализует генератор на основе матричного уравнения X_{k+1} = A * X_k
type LFSR struct {
	State        [5]int // Вектор состояния (биты)
	Coefficients [5]int // Коэффициенты полинома для первой строки матрицы
}

// NewLFSR инициализирует генератор.
func NewLFSR(polyCoeffs [5]int, seedVal int) *LFSR {
	lfsr := &LFSR{Coefficients: polyCoeffs}
	if seedVal == 0 {
		seedVal = 1 // Нулевое состояние недопустимо
	}
	for i := 0; i < 5; i++ {
		lfsr.State[i] = (seedVal >> i) & 1
	}
	return lfsr
}

// Next вычисляет следующее состояние и возвращает числовое значение [1, 32].
func (gen *LFSR) Next() int {
	val := 0
	for i := 0; i < 5; i++ {
		val |= gen.State[i] << i
	}
	newState := [5]int{}
	topBit := 0
	for i := 0; i < 5; i++ {
		topBit ^= (gen.Coefficients[i] * gen.State[4-i])
	}
	newState[4] = topBit & 1
	newState[3] = gen.State[4]
	newState[2] = gen.State[3]
	newState[1] = gen.State[2]
	newState[0] = gen.State[1]
	gen.State = newState
	return val + 1
}

// createLfsrKeyGen "адаптирует" LFSR для использования в функции шифрования.
func createLfsrKeyGen(polyCoeffs [5]int, seed int) KeyGen {
	lfsr := NewLFSR(polyCoeffs, seed)
	return func(i int) int {
		// lfsr.Next() возвращает значение в диапазоне [1, 32].
		// Для шифрования нужен ключ в диапазоне [0, 31].
		return lfsr.Next() - 1
	}
}

// --- MAIN ---

func main() {
	// 0. Подготовка данных
	const sourceFilename = "source.txt"
	sourceBytes, err := os.ReadFile(sourceFilename)
	if err != nil {
		fmt.Printf("ОШИБКА: Не удалось прочитать исходный файл '%s'.\n", sourceFilename)
		fmt.Println("Пожалуйста, создайте этот файл в одной папке с программой и поместите в него текст для шифрования.")
		fmt.Printf("Детали ошибки: %v\n", err)
		return // Завершаем программу, если файл не найден
	}
	sourceText := string(sourceBytes)

	fullText := sourceText
	// if len([]rune(cleanText(fullText))) > 1000 {
	// 	runes := []rune(cleanText(fullText))
	// 	fullText = string(runes[:1000])
	// }
	
	fmt.Println("=== ИСХОДНЫЕ ДАННЫЕ ===")
	fmt.Printf("Текст загружен (%d символов после очистки).\n", len([]rune(cleanText(fullText))))

	var reports []*TextAnalysis

	// --- ВЫПОЛНЕНИЕ ЗАДАНИЯ 1: Плейфейер ---
	keyPlayfair := "ПЛЕЙФЕЙЕР"
	cipher1 := encryptPlayfair(fullText, keyPlayfair)
	saveToFile("cipher_playfair.txt", cipher1)
	reports = append(reports, analyzeText("1. Шифр Плейфейера", encryptPlayfair(fullText, keyPlayfair)))

	// --- ВЫПОЛНЕНИЕ ЗАДАНИЯ 2: Аддитивные шифры ---
	
	// 2.1 Константа
	cipher2_1 := encryptAdditive(fullText, func(i int) int { return 15 })
	saveToFile("cipher_const.txt", cipher2_1)
	reports = append(reports, analyzeText("2.1 Гаммирование (Const=15)", encryptAdditive(fullText, func(i int) int { return 15 })))

	// 2.2 Поговорка
	proverb := "Пуст мешок стоять не будет"
	proverbClean := []rune(cleanText(proverb))
	cipher2_2 := encryptAdditive(fullText, func(i int) int { return alphaMap[proverbClean[i%len(proverbClean)]] })
	saveToFile("cipher_proverb.txt", cipher2_2)
	reports = append(reports, analyzeText("2.2 Гаммирование (Поговорка)", encryptAdditive(fullText, func(i int) int {
		return alphaMap[proverbClean[i%len(proverbClean)]]
	})))

	// 2.3 ПСП (LFSR из работы 2)
	// Используем полином x^5 + x^3 + 1. Коэффициенты для x^4,x^3,x^2,x^1,x^0: [0, 1, 0, 0, 1]
	poly := [5]int{0, 1, 0, 0, 1} 
	seed := rand.Intn(31) + 1 // Любое число от 1 до 31
	lfsrKeyGen := createLfsrKeyGen(poly, seed)
	cipher2_3 := encryptAdditive(fullText, lfsrKeyGen)
	saveToFile("cipher_lfsr.txt", cipher2_3)
	reports = append(reports, analyzeText("2.3 Гаммирование (ПСП LFSR)", encryptAdditive(fullText, lfsrKeyGen)))

	// --- АНАЛИЗ ИСХОДНОГО ТЕКСТА (для сравнения) ---
	reports = append([]*TextAnalysis{analyzeText("Исходный текст", fullText)}, reports...)

	// --- ВЫВОД ОТЧЕТОВ (Задание 3) ---
	for _, rep := range reports {

		printReport(rep)
	}
}