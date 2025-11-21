package main

import (
	"bufio"
	"encoding/csv"
	"fmt"
	"log"
	"math"
	"os"
	"path/filepath"
	"strings"
	"unicode"
)


var russianAlphabet = []rune{
	'а', 'б', 'в', 'г', 'д', 'е', 'ё', 'ж', 'з',
	'и', 'й', 'к', 'л', 'м', 'н', 'о', 'п',
	'р', 'с', 'т', 'у', 'ф', 'х', 'ц', 'ч',
	'ш', 'щ', 'ъ', 'ы', 'ь', 'э', 'ю', 'я',
}

var latinAlphabet = []rune{
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h',
	'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
	'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
	'y', 'z',
}

type Alph struct {
	Name   string
	Letters []rune
	Index  map[rune]int
}

func newAlph(name string, letters []rune) Alph {
	idx := make(map[rune]int, len(letters))
	for i, r := range letters {
		idx[r] = i
	}
	return Alph{Name: name, Letters: letters, Index: idx}
}

// Читает файл UTF-8 в одну строку (все символы).
func readFile(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()
	sb := strings.Builder{}
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		sb.WriteString(sc.Text())
		sb.WriteRune('\n')
	}
	if err := sc.Err(); err != nil {
		return "", err
	}
	return sb.String(), nil
}

// Нормализация символа: lower, и для кириллицы можно преобразовать 'ё'->'е' если нужно.
// Возвращает rune и флаг — принадлежит ли символ данному алфавиту и индекс в алфавите.
func filterChar(r rune, alph Alph) (int, bool) {
	r = unicode.ToLower(r)
	// Приведение ё к е (если нужно). В задании 32 буквы без ё — я исключаю 'ё'.
	if r == 'ё' {
		// можно заменить на 'е' или пропустить; здесь пропускаем (не считаем 'ё').
		return -1, false
	}
	idx, ok := alph.Index[r]
	return idx, ok
}

// Подсчёт частот одиночных символов и биграмм для текста и указанного алфавита.
func analyzeTextForAlphabet(text string, alph Alph) (counts []int, bigrams [][]int, total int) {
	n := len(alph.Letters)
	counts = make([]int, n)
	bigrams = make([][]int, n)
	for i := 0; i < n; i++ {
		bigrams[i] = make([]int, n)
	}

	var prevIdx = -1
	for _, r := range text {
		// игнорируем цифры, пунктуацию, пробелы
		// считаем только символы из алфавита
		if idx, ok := filterChar(r, alph); ok {
			counts[idx]++
			total++
			if prevIdx != -1 {
				bigrams[prevIdx][idx]++
			}
			prevIdx = idx
		} else {
			// разрыв: не учитываем биграммы через не-алфавитные символы
			prevIdx = -1
		}
	}
	return
}

// Вычисление вероятностей из счетчиков
func toProbabilitiesInt(counts []int, total int) []float64 {
	if total == 0 {
		out := make([]float64, len(counts))
		return out
	}
	out := make([]float64, len(counts))
	for i, c := range counts {
		out[i] = float64(c) / float64(total)
	}
	return out
}

func toProbMatrixInt(mat [][]int, total int) [][]float64 {
	n := len(mat)
	out := make([][]float64, n)
	for i := 0; i < n; i++ {
		out[i] = make([]float64, n)
		for j := 0; j < n; j++ {
			if total > 0 {
				out[i][j] = float64(mat[i][j]) / float64(total)
			} else {
				out[i][j] = 0.0
			}
		}
	}
	return out
}

// Энтропия: H = - sum p log2 p (игнорируем p==0)
func entropyFromProbs(probs []float64) float64 {
	h := 0.0
	for _, p := range probs {
		if p > 0 {
			h -= p * math.Log2(p)
		}
	}
	return h
}

// Энтропия для матрицы совместных вероятностей (двумерный)
func entropyFromJoint(joint [][]float64) float64 {
	h := 0.0
	for i := 0; i < len(joint); i++ {
		for j := 0; j < len(joint[i]); j++ {
			p := joint[i][j]
			if p > 0 {
				h -= p * math.Log2(p)
			}
		}
	}
	return h
}

// Марковская энтропия 1-го порядка: H1 = - sum_a p(a) sum_b p(b|a) log2 p(b|a)
// где p(b|a) = p(ab)/p(a)
func markovEntropy1(singleProbs []float64, bigramCounts [][]int) float64 {
	h := 0.0
	n := len(singleProbs)
	for a := 0; a < n; a++ {
		pa := singleProbs[a]
		if pa <= 0 {
			continue
		}
		// подсчёт суммы по b
		sum := 0.0
		// определим сумму биграмм для a
		totalForA := 0
		for b := 0; b < n; b++ {
			totalForA += bigramCounts[a][b]
		}
		if totalForA == 0 {
			continue
		}
		for b := 0; b < n; b++ {
			pab := float64(bigramCounts[a][b]) / float64(totalForA)
			if pab > 0 {
				sum -= pab * math.Log2(pab)
			}
		}
		h += pa * sum
	}
	return h
}

// Сохранение таблицы вероятностей в CSV (одномерная)
func saveProbCSV(path string, alph Alph, probs []float64) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	w := csv.NewWriter(f)
	defer w.Flush()
	// заголовок
	if err := w.Write([]string{"symbol", "index(1..)", "probability"}); err != nil {
		return err
	}
	for i, r := range alph.Letters {
		if err := w.Write([]string{string(r), fmt.Sprintf("%d", i+1), fmt.Sprintf("%.10f", probs[i])}); err != nil {
			return err
		}
	}
	return nil
}

// Сохранение матрицы вероятностей в CSV (bigrams/joint). Строки = символы a, столбцы = символы b
func saveMatrixCSV(path string, rowAlph Alph, colAlph Alph, mat [][]float64) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	w := csv.NewWriter(f)
	defer w.Flush()

	// заголовок: пустая ячейка + символы столбцов
	header := make([]string, len(colAlph.Letters)+1)
	header[0] = ""
	for j, c := range colAlph.Letters {
		header[j+1] = string(c)
	}
	if err := w.Write(header); err != nil {
		return err
	}
	for i, r := range rowAlph.Letters {
		row := make([]string, len(colAlph.Letters)+1)
		row[0] = string(r)
		for j := 0; j < len(colAlph.Letters); j++ {
			row[j+1] = fmt.Sprintf("%.12f", mat[i][j])
		}
		if err := w.Write(row); err != nil {
			return err
		}
	}
	return nil
}

// Совместное распределение для двух текстов (выравниваем по позициям)
func jointDistributionAligned(textA string, alphA Alph, textB string, alphB Alph) (joint [][]int, total int) {
	nA := len(alphA.Letters)
	nB := len(alphB.Letters)
	joint = make([][]int, nA)
	for i := 0; i < nA; i++ {
		joint[i] = make([]int, nB)
	}
	// Проходим по обоим текстам голова-к-голове
	runesA := []rune(textA)
	runesB := []rune(textB)
	minLen := len(runesA)
	if len(runesB) < minLen {
		minLen = len(runesB)
	}
	for i := 0; i < minLen; i++ {
		ra := unicode.ToLower(runesA[i])
		rb := unicode.ToLower(runesB[i])
		// пропускаем 'ё'
		if ra == 'ё' || rb == 'ё' {
			continue
		}
		ia, oka := alphA.Index[ra]
		ib, okb := alphB.Index[rb]
		if oka && okb {
			joint[ia][ib]++
			total++
		}
	}
	return
}

func printCountsAndProbs(path string, alph Alph, counts []int, bigrams [][]int, total int) {
	fmt.Printf("=== Анализ для %s (файл: %s) ===\n", alph.Name, filepath.Base(path))
	fmt.Printf("Общее число символов (в алфавите %d): %d\n", len(alph.Letters), total)
	fmt.Println("Счётчики по символам:")
	for i, c := range counts {
		fmt.Printf("%2d) %s : %d\n", i+1, string(alph.Letters[i]), c)
	}
	probs := toProbabilitiesInt(counts, total)
	fmt.Println("\nВероятности (p):")
	for i, p := range probs {
		fmt.Printf("%2d) %s : %.8f\n", i+1, string(alph.Letters[i]), p)
	}

	asciiHistogram(alph, counts, total)

	// биграммы: выведем суммарно по a -> суммарно
	fmt.Println("\nБиграммы (частично, только ненулевые):")
	for i := 0; i < len(alph.Letters); i++ {
		for j := 0; j < len(alph.Letters); j++ {
			if bigrams[i][j] > 0 {
				fmt.Printf("%s%s : %d\n", string(alph.Letters[i]), string(alph.Letters[j]), bigrams[i][j])
			}
		}
	}
}

func asciiHistogram(alph Alph, counts []int, total int) {
    fmt.Println("\nГистограмма:")

    if total == 0 {
        fmt.Println("(нет данных)")
        return
    }

    maxCount := 0
    for _, c := range counts {
        if c > maxCount {
            maxCount = c
        }
    }
    if maxCount == 0 {
        fmt.Println("(все нули)")
        return
    }

    // ширина столбика в символах
    const barMax = 40

    for i, c := range counts {
        p := float64(c) / float64(maxCount)
        barLen := int(p * barMax)

        bar := strings.Repeat("█", barLen)
        fmt.Printf("%s | %-*s (%d)\n", string(alph.Letters[i]), barMax, bar, c)
    }
}

// main: CLI
func main() {
	if len(os.Args) < 2 {
		fmt.Println("Использование: go run freq_analysis.go fileA.txt [fileB.txt]")
		return
	}
	// Инициализация алфавитов
	rus := newAlph("Russian(32)", russianAlphabet)
	lat := newAlph("Latin(26)", latinAlphabet)

	pathA := os.Args[1]
	textA, err := readFile(pathA)
	if err != nil {
		log.Fatalf("Ошибка чтения %s: %v", pathA, err)
	}

	// Выберем алфавит для файла A: если в тексте есть кириллические буквы -> рус, иначе латинский.
	useRusA := false
	for _, r := range textA {
		if unicode.Is(unicode.Cyrillic, r) {
			useRusA = true
			break
		}
	}
	var alphA Alph
	if useRusA {
		alphA = rus
	} else {
		alphA = lat
	}
	countsA, bigramsA, totalA := analyzeTextForAlphabet(textA, alphA)
	probsA := toProbabilitiesInt(countsA, totalA)
	bigramProbsA := toProbMatrixInt(bigramsA, 0) // позднее нормализуем по каждой строке, если нужно

	// Для биграмм используем нормализацию на общее число биграмм (sum over all pairs)
	totalBigramsA := 0
	for i := 0; i < len(bigramsA); i++ {
		for j := 0; j < len(bigramsA); j++ {
			totalBigramsA += bigramsA[i][j]
		}
	}
	bigramProbsA = toProbMatrixInt(bigramsA, totalBigramsA)

	printCountsAndProbs(pathA, alphA, countsA, bigramsA, totalA)

	// Вычисления энтропий для A
	H_A := entropyFromProbs(probsA)
	H1_A := markovEntropy1(probsA, bigramsA)
	fmt.Printf("\nH(A) = %.12f бит\n", H_A)
	fmt.Printf("Марковская энтропия 1-го порядка H1(A) = %.12f бит\n", H1_A)

	// Сохраняем таблицы в CSV
	_ = os.Mkdir("out", 0755)
	if err := saveProbCSV(filepath.Join("out", filepath.Base(pathA)+".probs.csv"), alphA, probsA); err != nil {
		log.Printf("Ошибка сохранения probs CSV: %v", err)
	}
	if err := saveMatrixCSV(filepath.Join("out", filepath.Base(pathA)+".bigrams.csv"), alphA, alphA, bigramProbsA); err != nil {
		log.Printf("Ошибка сохранения bigrams CSV: %v", err)
	}

	// Если есть второй файл — делаем сравнительный анализ
	if len(os.Args) >= 3 {
		pathB := os.Args[2]
		textB, err := readFile(pathB)
		if err != nil {
			log.Fatalf("Ошибка чтения %s: %v", pathB, err)
		}
		useRusB := false
		for _, r := range textB {
			if unicode.Is(unicode.Cyrillic, r) {
				useRusB = true
				break
			}
		}
		var alphB Alph
		if useRusB {
			alphB = rus
		} else {
			alphB = lat
		}
		countsB, bigramsB, totalB := analyzeTextForAlphabet(textB, alphB)
		probsB := toProbabilitiesInt(countsB, totalB)
		// биграммы для B
		totalBigramsB := 0
		for i := 0; i < len(bigramsB); i++ {
			for j := 0; j < len(bigramsB); j++ {
				totalBigramsB += bigramsB[i][j]
			}
		}
		bigramProbsB := toProbMatrixInt(bigramsB, totalBigramsB)
		printCountsAndProbs(pathB, alphB, countsB, bigramsB, totalB)

		H_B := entropyFromProbs(probsB)
		H1_B := markovEntropy1(probsB, bigramsB)
		fmt.Printf("\nH(B) = %.12f бит\n", H_B)
		fmt.Printf("Марковская энтропия 1-го порядка H1(B) = %.12f бит\n", H1_B)

		// Совместное распределение по выровненным позициям
		jointCounts, totalJoint := jointDistributionAligned(textA, alphA, textB, alphB)
		jointProbs := make([][]float64, len(jointCounts))
		for i := range jointCounts {
			jointProbs[i] = make([]float64, len(jointCounts[i]))
			for j := range jointCounts[i] {
				if totalJoint > 0 {
					jointProbs[i][j] = float64(jointCounts[i][j]) / float64(totalJoint)
				} else {
					jointProbs[i][j] = 0.0
				}
			}
		}

		// Энтропии совместные и условные
		H_AB := entropyFromJoint(jointProbs)
		// Условная H(A|B) = H(A,B) - H(B) (где H(B) считаем по распределению символов B в позициях, где был учтён joint)
		// Сначала получим p_B_in_joint (распределение B только по позициям, участвовавшим в joint)
		pB_in_joint := make([]float64, len(alphB.Letters))
		for i := 0; i < len(jointCounts); i++ {
			for j := 0; j < len(jointCounts[i]); j++ {
				pB_in_joint[j] += float64(jointCounts[i][j])
			}
		}
		for j := 0; j < len(pB_in_joint); j++ {
			if totalJoint > 0 {
				pB_in_joint[j] = pB_in_joint[j] / float64(totalJoint)
			}
		}
		H_B_givenJoint := entropyFromProbs(pB_in_joint)
		// Теперь условная H(A|B) = H(A,B) - H(B|joint)
		H_A_given_B := H_AB - H_B_givenJoint

		// Аналогично H(B|A) = H(A,B) - H(A|joint)
		pA_in_joint := make([]float64, len(alphA.Letters))
		for i := 0; i < len(jointCounts); i++ {
			for j := 0; j < len(jointCounts[i]); j++ {
				pA_in_joint[i] += float64(jointCounts[i][j])
			}
		}
		for i := 0; i < len(pA_in_joint); i++ {
			if totalJoint > 0 {
				pA_in_joint[i] = pA_in_joint[i] / float64(totalJoint)
			}
		}
		H_A_givenJoint := entropyFromProbs(pA_in_joint)
		H_B_given_A := H_AB - H_A_givenJoint

		fmt.Printf("\nСовместная энтропия H(A,B) = %.12f бит (по выровненным позициям, учтено пар: %d)\n", H_AB, totalJoint)
		fmt.Printf("Условная энтропия H(A|B) = %.12f бит\n", H_A_given_B)
		fmt.Printf("Условная энтропия H(B|A) = %.12f бит\n", H_B_given_A)

		// Сохранение joint в CSV
		if err := saveMatrixCSV(filepath.Join("out", filepath.Base(pathA)+"__"+filepath.Base(pathB)+".joint.csv"), alphA, alphB, jointProbs); err != nil {
			log.Printf("Ошибка сохранения joint CSV: %v", err)
		}

		// Также сохраняем одиночные вероятности для B
		if err := saveProbCSV(filepath.Join("out", filepath.Base(pathB)+".probs.csv"), alphB, probsB); err != nil {
			log.Printf("Ошибка сохранения probs CSV для B: %v", err)
		}
		if err := saveMatrixCSV(filepath.Join("out", filepath.Base(pathB)+".bigrams.csv"), alphB, alphB, bigramProbsB); err != nil {
			log.Printf("Ошибка сохранения bigrams CSV для B: %v", err)
		}
	}

	fmt.Println("\nГотово. CSV-таблицы (если созданы) в папке ./out")
}