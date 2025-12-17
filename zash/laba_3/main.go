package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"strconv"
	"strings"
	"time"
	"unicode"
)


var alphabetRunes = []rune("АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
var alphaMap map[rune]int

func init() {
	alphaMap = make(map[rune]int)
	for i, r := range alphabetRunes {
		alphaMap[r] = i
	}
}


type TextAnalysis struct {
	Name      string
	TotalLen  float64
	CharProbs map[rune]float64
	Entropy   float64
}


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

// saveHistogramToCSV создает CSV файл с частотами символов для данного анализа
func saveHistogramToCSV(ta *TextAnalysis) error {
	// Формируем имя файла: убираем пробелы и лишние знаки из названия анализа
	safeName := strings.ReplaceAll(ta.Name, " ", "_")
	safeName = strings.ReplaceAll(safeName, ".", "")
	safeName = strings.ReplaceAll(safeName, "(", "")
	safeName = strings.ReplaceAll(safeName, ")", "")
	safeName = strings.ReplaceAll(safeName, "=", "")
	safeName = strings.ToLower(safeName)
	
	filename := fmt.Sprintf("hist_%s.csv", safeName)

	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Записываем заголовок
	if err := writer.Write([]string{"Symbol", "Percent"}); err != nil {
		return err
	}

	// Записываем данные в порядке алфавита
	for _, r := range alphabetRunes {
		prob := ta.CharProbs[r] * 100 // переводим в проценты
		// Форматируем число с точностью до 4 знаков
		sProb := strconv.FormatFloat(prob, 'f', 4, 64)
		
		if err := writer.Write([]string{string(r), sProb}); err != nil {
			return err
		}
	}

	fmt.Printf("-> CSV сохранен: %s\n", filename)
	return nil
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

// --- ГЕНЕРАТОР ПСП (LFSR) ---

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

func createLfsrKeyGen(polyCoeffs [5]int, seed int) KeyGen {
	lfsr := NewLFSR(polyCoeffs, seed)
	return func(i int) int {
		return lfsr.Next() - 1
	}
}


func main() {
	// 0. Подготовка данных
	const sourceFilename = "source.txt"
	sourceBytes, err := os.ReadFile(sourceFilename)
	if err != nil {
		fmt.Printf("ОШИБКА: Не удалось прочитать исходный файл '%s'.\n", sourceFilename)
		fmt.Println("Пожалуйста, создайте этот файл и поместите в него текст для шифрования.")
		return
	}
	sourceText := string(sourceBytes)
	fullText := sourceText

	fmt.Println("=== ИСХОДНЫЕ ДАННЫЕ ===")
	fmt.Printf("Текст загружен (%d символов после очистки).\n", len([]rune(cleanText(fullText))))

	var reports []*TextAnalysis

	reports = append(reports, analyzeText("Исходный текст", fullText))

	// --- 1: Плейфейер ---
	keyPlayfair := "ПЛЕЙФЕЙЕР"
	cipher1 := encryptPlayfair(fullText, keyPlayfair)
	saveToFile("cipher_playfair.txt", cipher1)
	reports = append(reports, analyzeText("1. Шифр Плейфейера", cipher1))

	// --- 2.1 Константа ---
	cipher2_1 := encryptAdditive(fullText, func(i int) int { return 15 })
	saveToFile("cipher_const.txt", cipher2_1)
	reports = append(reports, analyzeText("2.1 Гаммирование (Const=15)", cipher2_1))

	// --- 2.2 Поговорка ---
	proverb := "Пуст мешок стоять не будет"
	proverbClean := []rune(cleanText(proverb))
	cipher2_2 := encryptAdditive(fullText, func(i int) int { 
		return alphaMap[proverbClean[i%len(proverbClean)]] 
	})
	saveToFile("cipher_proverb.txt", cipher2_2)
	reports = append(reports, analyzeText("2.2 Гаммирование (Поговорка)", cipher2_2))

	// --- 2.3 ПСП (LFSR) ---
	poly := [5]int{0, 1, 0, 0, 1}
	seed := int(time.Now().UnixNano()) 
	lfsrKeyGen := createLfsrKeyGen(poly, seed+1)
	cipher2_3 := encryptAdditive(fullText, lfsrKeyGen)
	saveToFile("cipher_lfsr.txt", cipher2_3)
	reports = append(reports, analyzeText("2.3 Гаммирование (ПСП LFSR)", cipher2_3))

	// --- ВЫВОД ОТЧЕТОВ И СОХРАНЕНИЕ CSV ---
	for _, rep := range reports {
		printReport(rep)
		// Сохранение гистограммы в CSV файл
		if err := saveHistogramToCSV(rep); err != nil {
			fmt.Printf("Ошибка при сохранении CSV для '%s': %v\n", rep.Name, err)
		}
	}
}