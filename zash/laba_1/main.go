package main

import (
	"bufio"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strings"
	"unicode"
)

// Константы для алфавитов
const (
	LangRu = "ru"
	LangEn = "en"
)

// Структура для хранения статистики текста
type TextAnalysis struct {
	Filename      string
	Language      string
	CleanText     []rune
	Alphabet      []rune
	CharCounts    map[rune]float64
	CharProbs     map[rune]float64 // p(a_i)
	BigramCounts  map[string]float64
	BigramProbs   map[string]float64 // p(a_i, a_k)
	CondProbs     map[string]float64 // p(a_k | a_i)
	Entropy       float64            // H(A)
	MarkovEntropy float64            // H(A|A)
}

func main() {
	// Проверка аргументов
	args := os.Args[1:]
	if len(args) < 2 {
		fmt.Println("Ошибка: Необходимо указать два файла.")
		fmt.Println("Пример использования: go run main.go hud_A.txt hud_B.txt")
		return
	}

	filePaths := args[:2] // Берем только первые два аргумента

	// Создание имени директории для вывода (file1_file2)
	baseName1 := strings.TrimSuffix(filepath.Base(filePaths[0]), filepath.Ext(filePaths[0]))
	baseName2 := strings.TrimSuffix(filepath.Base(filePaths[1]), filepath.Ext(filePaths[1]))
	outputDir := fmt.Sprintf("%s_%s", baseName1, baseName2)

	// Создаем директорию, если её нет
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		fmt.Printf("Ошибка создания директории %s: %v\n", outputDir, err)
		return
	}
	fmt.Printf("Результаты будут сохранены в директорию: %s\n", outputDir)

	var analyses []*TextAnalysis

	for _, path := range filePaths {
		// 1. Чтение файла
		text, err := readFile(path)
		if err != nil {
			fmt.Printf("Ошибка чтения файла %s: %v\n", path, err)
			continue
		}

		if len([]rune(text)) < 200 {
			fmt.Printf("Внимание: Файл %s слишком короткий (<200 символов)\n", path)
		}

		// Автоопределение языка
		lang := detectLanguage(text)

		fmt.Printf("\n=== Анализ файла: %s (%s) ===\n", path, lang)

		// 2. Анализ текста
		analysis := analyzeText(text, lang, filepath.Base(path))
		analyses = append(analyses, analysis)

		// 3. Вывод результатов в консоль (Визуальная гистограмма и Энтропия)
		printHistogram(analysis)
		fmt.Printf("Энтропия источника H(A): %.4f бит\n", analysis.Entropy)
		fmt.Printf("Марковская энтропия 1-го порядка H(A|A): %.4f бит\n", analysis.MarkovEntropy)

		// Сохранение таблиц в CSV (включая новую гистограмму)
		saveTablesToCSV(analysis, outputDir)
	}

	// 4. Совместная и условная энтропия для пары текстов
	if len(analyses) >= 2 {
		fmt.Println("\n=== Анализ пары текстов (A и B) ===")
		analyzePair(analyses[0], analyses[1])
	}
}

// detectLanguage проверяет наличие русских букв
func detectLanguage(text string) string {
	for _, r := range text {
		if unicode.Is(unicode.Cyrillic, r) {
			return LangRu
		}
	}
	return LangEn
}

// readFile читает файл целиком
func readFile(path string) (string, error) {
	bytes, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return string(bytes), nil
}

// analyzeText выполняет полный цикл расчетов для одного текста
func analyzeText(rawText string, lang string, filename string) *TextAnalysis {
	ta := &TextAnalysis{
		Filename:     filename,
		Language:     lang,
		CharCounts:   make(map[rune]float64),
		CharProbs:    make(map[rune]float64),
		BigramCounts: make(map[string]float64),
		BigramProbs:  make(map[string]float64),
		CondProbs:    make(map[string]float64),
	}

	// Очистка и формирование алфавита
	ta.CleanText = cleanText(rawText, lang)
	ta.Alphabet = getAlphabet(lang)
	totalLen := float64(len(ta.CleanText))

	// 1. Подсчет одиночных символов
	for _, r := range ta.CleanText {
		ta.CharCounts[r]++
	}

	// Вероятности одиночных символов и Энтропия H(A)
	for _, r := range ta.Alphabet {
		count := ta.CharCounts[r]
		if count > 0 {
			prob := count / totalLen
			ta.CharProbs[r] = prob
			ta.Entropy -= prob * math.Log2(prob)
		} else {
			ta.CharProbs[r] = 0
		}
	}

	// 2. Подсчет биграмм
	for i := 0; i < len(ta.CleanText)-1; i++ {
		r1 := ta.CleanText[i]
		r2 := ta.CleanText[i+1]
		key := string([]rune{r1, r2})
		ta.BigramCounts[key]++
	}

	// Вероятности биграмм и Условные вероятности
	bigramTotal := totalLen - 1
	for _, r1 := range ta.Alphabet {
		for _, r2 := range ta.Alphabet {
			key := string([]rune{r1, r2})
			count := ta.BigramCounts[key]

			if count > 0 {
				pJoint := count / bigramTotal // p(ai, ak)
				ta.BigramProbs[key] = pJoint

				pCond := 0.0
				if ta.CharProbs[r1] > 0 {
					pCond = pJoint / ta.CharProbs[r1]
				}
				ta.CondProbs[key] = pCond

				if pCond > 0 {
					ta.MarkovEntropy -= pJoint * math.Log2(pCond)
				}
			}
		}
	}

	return ta
}

// analyzePair рассчитывает H(A,B) и H(A|B) для двух текстов
func analyzePair(t1, t2 *TextAnalysis) {
	minLen := len(t1.CleanText)
	if len(t2.CleanText) < minLen {
		minLen = len(t2.CleanText)
	}

	jointCounts := make(map[string]float64)

	// Считаем совместные появления
	for i := 0; i < minLen; i++ {
		r1 := t1.CleanText[i]
		r2 := t2.CleanText[i]
		key := string([]rune{r1, r2})
		jointCounts[key]++
	}

	total := float64(minLen)
	jointEntropy := 0.0

	for _, count := range jointCounts {
		p := count / total
		if p > 0 {
			jointEntropy -= p * math.Log2(p)
		}
	}

	condEntropy := jointEntropy - t2.Entropy

	fmt.Printf("Текст A: %s (Lang: %s)\n", t1.Filename, t1.Language)
	fmt.Printf("Текст B: %s (Lang: %s)\n", t2.Filename, t2.Language)
	fmt.Printf("Совместная энтропия H(A, B): %.4f\n", jointEntropy)
	fmt.Printf("Условная энтропия H(A|B): %.4f\n", condEntropy)
}

// cleanText оставляет только буквы заданного алфавита
func cleanText(text string, lang string) []rune {
	var res []rune
	for _, r := range text {
		r = unicode.ToLower(r)

		if lang == LangRu {
			if r == 'ё' {
				r = 'е'
			}
			if r >= 'а' && r <= 'я' {
				res = append(res, r)
			}
		} else if lang == LangEn {
			if r >= 'a' && r <= 'z' {
				res = append(res, r)
			}
		}
	}
	return res
}

func getAlphabet(lang string) []rune {
	var abc []rune
	if lang == LangRu {
		for r := 'а'; r <= 'я'; r++ {
			abc = append(abc, r)
			if r == 'е' {
				abc = append(abc, 'ё')
			}
		}
	} else {
		for r := 'a'; r <= 'z'; r++ {
			abc = append(abc, r)
		}
	}
	return abc
}

// --- Функции вывода ---

func printHistogram(ta *TextAnalysis) {
	fmt.Println("Гистограмма:")
	maxCount := 0.0
	for _, count := range ta.CharCounts {
		if count > maxCount {
			maxCount = count
		}
	}
	const maxBarLen = 30
	for _, r := range ta.Alphabet {
		count := ta.CharCounts[r]
		currentBarLen := 0
		if maxCount > 0 {
			currentBarLen = int((count / maxCount) * float64(maxBarLen))
		}
		bar := strings.Repeat("█", currentBarLen)
		padding := strings.Repeat(" ", maxBarLen-currentBarLen)
		fmt.Printf("%c | %s%s (%d)\n", r, bar, padding, int(count))
	}
	fmt.Println()
}

func saveTablesToCSV(ta *TextAnalysis, outputDir string) {
	baseName := ta.Filename

	// 1. Таблица одиночных (Вероятности)
	fPath1 := filepath.Join(outputDir, baseName+"_single.csv")
	f1, _ := os.Create(fPath1)
	defer f1.Close()
	w1 := bufio.NewWriter(f1)
	fmt.Fprintln(w1, "Char;Probability")
	for _, r := range ta.Alphabet {
		fmt.Fprintf(w1, "%c;%.6f\n", r, ta.CharProbs[r])
	}
	w1.Flush()

	// 2. Таблица Биграмм
	fPath2 := filepath.Join(outputDir, baseName+"_bigrams.csv")
	f2, _ := os.Create(fPath2)
	defer f2.Close()
	w2 := bufio.NewWriter(f2)
	fmt.Fprint(w2, ";")
	for _, r := range ta.Alphabet {
		fmt.Fprintf(w2, "%c;", r)
	}
	fmt.Fprintln(w2)
	for _, r1 := range ta.Alphabet {
		fmt.Fprintf(w2, "%c;", r1)
		for _, r2 := range ta.Alphabet {
			key := string([]rune{r1, r2})
			fmt.Fprintf(w2, "%.5f;", ta.BigramProbs[key])
		}
		fmt.Fprintln(w2)
	}
	w2.Flush()

	// 3. Таблица Условных вероятностей
	fPath3 := filepath.Join(outputDir, baseName+"_conditional.csv")
	f3, _ := os.Create(fPath3)
	defer f3.Close()
	w3 := bufio.NewWriter(f3)
	fmt.Fprint(w3, ";")
	for _, r := range ta.Alphabet {
		fmt.Fprintf(w3, "%c;", r)
	}
	fmt.Fprintln(w3)
	for _, r1 := range ta.Alphabet {
		fmt.Fprintf(w3, "%c;", r1)
		for _, r2 := range ta.Alphabet {
			key := string([]rune{r1, r2})
			fmt.Fprintf(w3, "%.5f;", ta.CondProbs[key])
		}
		fmt.Fprintln(w3)
	}
	w3.Flush()

	// 4. ГИСТОГРАММА (Количество символов)
	fPath4 := filepath.Join(outputDir, baseName+"_histogram.csv")
	f4, err := os.Create(fPath4)
	if err != nil {
		fmt.Printf("Ошибка создания файла гистограммы: %v\n", err)
	} else {
		defer f4.Close()
		w4 := bufio.NewWriter(f4)

		fmt.Fprintln(w4, "Char;Count") // Заголовок
		for _, r := range ta.Alphabet {
			// Сохраняем символ и его количество
			fmt.Fprintf(w4, "%c;%d\n", r, int(ta.CharCounts[r]))
		}
		w4.Flush()
		fmt.Printf("Гистограмма сохранена в файл: %s\n", fPath4)
	}
	
	fmt.Printf("Остальные файлы сохранены в папку: %s\n", outputDir)
}