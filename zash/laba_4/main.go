package main

import (
	"encoding/csv"
	"fmt"
	"math" // --- ДОБАВЛЕНО: Для вычисления логарифма ---
	"os"
	"strings"
)

// ЗАДАНИЕ 1: РЕАЛИЗАЦИЯ СЕТИ ФЕЙСТЕЛЯ

// AlphabetMap содержит отображение русских букв в 5-битные числа (0-31)
var AlphabetMap map[rune]uint8

// ReverseAlphabetMap содержит обратное отображение для декодирования
var ReverseAlphabetMap map[uint8]rune

// initializeMaps инициализирует карты для алфавита Z_32
func initializeMaps() {
	AlphabetMap = make(map[rune]uint8)
	ReverseAlphabetMap = make(map[uint8]rune)
	alphabet := "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"

	runes := []rune(alphabet)

	for i, r := range runes {
		AlphabetMap[r] = uint8(i)
		ReverseAlphabetMap[uint8(i)] = r
	}
}

// FeistelCipher представляет собой структуру для шифра на основе сети Фейстеля.
type FeistelCipher struct {
	roundKeys []uint8
}

// NewFeistelCipher создает новый экземпляр шифра с ключами, сгенерированными из пароля.
func NewFeistelCipher(password string) (*FeistelCipher, error) {
	password = strings.ToUpper(password)
	builder := strings.Builder{}

	for _, r := range password {
		if _, ok := AlphabetMap[r]; ok {
			builder.WriteRune(r)
		}
	}

	runes := []rune(builder.String())

	if len(runes) < 8 {
		return nil, fmt.Errorf("длина пароля должна быть не менее 8 символов для 8 раундов")
	}

	keys := make([]uint8, 8)
	for i := 0; i < 8; i++ {
		r := runes[i]
		if val, ok := AlphabetMap[r]; ok {
			keys[i] = val
		} else {
			return nil, fmt.Errorf("недопустимый символ в пароле: %c", r)
		}
	}

	return &FeistelCipher{roundKeys: keys}, nil
}

// fFunction - раундовая функция F.
func (fc *FeistelCipher) fFunction(r, key uint8) uint8 {
	sum := (r + key) & 0x1F
	return sum ^ r
}

// splitBlock разделяет 10-битный блок на две 5-битные части (L и R).
func splitBlock(block uint16) (uint8, uint8) {
	l := uint8((block >> 5) & 0x1F)
	r := uint8(block & 0x1F)
	return l, r
}

func combineHalves(l, r uint8) uint16 {
	return (uint16(l) << 5) | uint16(r)
}

// EncryptBlock - функция шифрования блока
func (fc *FeistelCipher) EncryptBlock(block uint16) uint16 {
	l, r := splitBlock(block)
	for i := 0; i < 8; i++ {
		l_prev := l
		f_result := fc.fFunction(r, fc.roundKeys[i])
		l = r
		r = l_prev ^ f_result
	}
	return combineHalves(l, r)
}

// DecryptBlock - функция дешифрования блока
func (fc *FeistelCipher) DecryptBlock(block uint16) uint16 {
	l, r := splitBlock(block)
	for i := 7; i >= 0; i-- {
		r_prev := r
		f_result := fc.fFunction(l, fc.roundKeys[i])
		r = l
		l = r_prev ^ f_result
	}
	return combineHalves(l, r)
}

// EncryptAndRecordRounds - шифрование с записью результатов каждого раунда
func EncryptAndRecordRounds(fc *FeistelCipher, plaintextBlocks []uint16) map[int][]uint16 {
	roundResults := make(map[int][]uint16)
	currentBlocks := make([]uint16, len(plaintextBlocks))
	copy(currentBlocks, plaintextBlocks)
	for i := 0; i < 8; i++ {
		nextBlocks := make([]uint16, len(currentBlocks))
		for j, block := range currentBlocks {
			l, r := splitBlock(block)
			l_prev := l
			f_result := fc.fFunction(r, fc.roundKeys[i])
			l = r
			r = l_prev ^ f_result
			nextBlocks[j] = combineHalves(l, r)
		}
		currentBlocks = nextBlocks
		roundCopy := make([]uint16, len(currentBlocks))
		copy(roundCopy, currentBlocks)
		roundResults[i+1] = roundCopy
	}
	return roundResults
}

// --- Утилиты ---

func prepareText(text string) string {
	text = strings.ToUpper(text)
	var builder strings.Builder
	for _, r := range text {
		if _, ok := AlphabetMap[r]; ok {
			builder.WriteRune(r)
		}
	}
	res := builder.String()
	if len([]rune(res))%2 != 0 {
		builder.WriteRune('А')
	}
	return builder.String()
}

func textToBlocks(text string) ([]uint16, error) {
	preparedText := prepareText(text)
	runes := []rune(preparedText)

	if len(runes)%2 != 0 {
		return nil, fmt.Errorf("длина подготовленного текста должна быть четной")
	}

	numBlocks := len(runes) / 2
	blocks := make([]uint16, numBlocks)

	for i := 0; i < numBlocks; i++ {
		r1 := runes[2*i]
		r2 := runes[2*i+1]

		v1, ok1 := AlphabetMap[r1]
		v2, ok2 := AlphabetMap[r2]

		if !ok1 || !ok2 {
			return nil, fmt.Errorf("недопустимый символ в тексте после подготовки: %c или %c", r1, r2)
		}
		blocks[i] = combineHalves(v1, v2)
	}
	return blocks, nil
}

func blocksToSymbols(blocks []uint16) []uint8 {
	symbols := make([]uint8, len(blocks)*2)
	for i, block := range blocks {
		l, r := splitBlock(block)
		symbols[2*i] = l
		symbols[2*i+1] = r
	}
	return symbols
}

// --- ДОБАВЛЕНО: Функция расчета энтропии Шеннона ---
func calculateEntropy(symbols []uint8) float64 {
	if len(symbols) == 0 {
		return 0.0
	}

	counts := make(map[uint8]int)
	for _, s := range symbols {
		counts[s]++
	}

	total := float64(len(symbols))
	entropy := 0.0

	for _, count := range counts {
		p := float64(count) / total
		if p > 0 {
			entropy -= p * math.Log2(p)
		}
	}
	return entropy
}

// ----------------------------------------------------

// printHistogram выводит гистограмму в консоль
func printHistogram(title string, symbols []uint8) {
	fmt.Printf("\n--- %s ---\n", title)

	counts := make(map[uint8]int)
	maxCount := 0

	for _, s := range symbols {
		counts[s]++
		if counts[s] > maxCount {
			maxCount = counts[s]
		}
	}

	totalSymbols := float64(len(symbols))
	if totalSymbols == 0 {
		return
	}

	const maxWidth = 60

	for i := uint8(0); i < 32; i++ {
		char, ok := ReverseAlphabetMap[i]
		if !ok {
			continue
		}

		count := counts[i]
		prob := float64(count) / totalSymbols

		var barLen int
		if maxCount > 0 {
			barLen = int((float64(count) / float64(maxCount)) * maxWidth)
		}

		bar := strings.Repeat("█", barLen)

		if barLen == 0 && count > 0 {
			bar = "▏"
		} else if count == 0 {
			bar = " "
		}

		fmt.Printf("%c | %.5f | %s\n", char, prob, bar)
	}
	fmt.Println()
}

// saveHistogramToCSV сохраняет в файл СИМВОЛ и ВЕРОЯТНОСТЬ с заголовками
func saveHistogramToCSV(filename string, symbols []uint8) error {
	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	headers := []string{"Символ", "Вероятность"}
	if err := writer.Write(headers); err != nil {
		return err
	}

	counts := make(map[uint8]int)
	for _, s := range symbols {
		counts[s]++
	}
	totalSymbols := float64(len(symbols))

	if totalSymbols == 0 {
		return nil
	}

	for i := uint8(0); i < 32; i++ {
		char, ok := ReverseAlphabetMap[i]
		if !ok {
			continue
		}

		count := counts[i]
		prob := float64(count) / totalSymbols

		record := []string{
			string(char),
			fmt.Sprintf("%.5f", prob),
		}

		if err := writer.Write(record); err != nil {
			return err
		}
	}

	// Убрал вывод "Файл сохранен" чтобы не засорять консоль, так как файлов много
	return nil
}

// ЗАДАНИЕ 2: РЕЖИМЫ ШИФРОВАНИЯ

func encryptECB(fc *FeistelCipher, plaintext []uint16) []uint16 {
	ciphertext := make([]uint16, len(plaintext))
	for i, block := range plaintext {
		ciphertext[i] = fc.EncryptBlock(block)
	}
	return ciphertext
}

func encryptCBC(fc *FeistelCipher, plaintext []uint16, iv uint16) []uint16 {
	ciphertext := make([]uint16, len(plaintext))
	prevCipherBlock := iv
	for i, block := range plaintext {
		inputBlock := block ^ prevCipherBlock
		encryptedBlock := fc.EncryptBlock(inputBlock)
		ciphertext[i] = encryptedBlock
		prevCipherBlock = encryptedBlock
	}
	return ciphertext
}

func encryptCFB(fc *FeistelCipher, plaintext []uint16, iv uint16) []uint16 {
	ciphertext := make([]uint16, len(plaintext))
	prevBlock := iv
	for i, pBlock := range plaintext {
		keystream := fc.EncryptBlock(prevBlock)
		cBlock := pBlock ^ keystream
		ciphertext[i] = cBlock
		prevBlock = cBlock
	}
	return ciphertext
}

func encryptOFB(fc *FeistelCipher, plaintext []uint16, iv uint16) []uint16 {
	ciphertext := make([]uint16, len(plaintext))
	prevOutput := iv
	for i, pBlock := range plaintext {
		keystream := fc.EncryptBlock(prevOutput)
		ciphertext[i] = pBlock ^ keystream
		prevOutput = keystream
	}
	return ciphertext
}

func main() {
	initializeMaps()

	const password = "Пуст мешок стоять не будет"
	const sourceFilename = "source.txt"

	sourceBytes, err := os.ReadFile(sourceFilename)
	if err != nil {
		fmt.Printf("ОШИБКА: Файл '%s' не найден. Создайте его и добавьте текст.\n", sourceFilename)
		return
	}

	sourceText := string(sourceBytes)
	fmt.Printf("Исходный текст (первые 50 символов): %.50s...\n", sourceText)

	fc, err := NewFeistelCipher(password)
	if err != nil {
		fmt.Println("Ошибка:", err)
		return
	}

	allBlocks, err := textToBlocks(sourceText)
	if err != nil {
		fmt.Println("Ошибка:", err)
		return
	}

	// 0. Гистограмма исходного текста
	sourceSymbols := blocksToSymbols(allBlocks)
	saveHistogramToCSV("histogram_source.csv", sourceSymbols)
	printHistogram("ИСХОДНЫЙ ТЕКСТ", sourceSymbols)

	// --- ДОБАВЛЕНО: Энтропия исходного текста ---
	fmt.Printf(">> Энтропия исходного текста: %.5f бит\n", calculateEntropy(sourceSymbols))
	// --------------------------------------------

	// --- ЗАДАНИЕ 1: Сохранение по раундам ---
	fmt.Println("\n--- ЗАДАНИЕ 1: ПО РАУНДАМ ---")
	roundData := EncryptAndRecordRounds(fc, allBlocks)

	for i := 1; i <= 8; i++ {
		symbols := blocksToSymbols(roundData[i])
		csvFilename := fmt.Sprintf("histogram_round_%d.csv", i)
		saveHistogramToCSV(csvFilename, symbols)

		// --- ДОБАВЛЕНО: Вывод энтропии для каждого раунда ---
		ent := calculateEntropy(symbols)
		fmt.Printf("Раунд %d: энтропия = %.5f бит\n", i, ent)
		// ----------------------------------------------------

		if i == 1 || i == 8 {
			printHistogram(fmt.Sprintf("РАУНД %d (Гистограмма)", i), symbols)
		}
	}

	// --- ЗАДАНИЕ 2: Режимы ---
	fmt.Println("\n--- ЗАДАНИЕ 2: РЕЖИМЫ ---")
	const iv uint16 = 819

	// ECB
	ecbCipher := encryptECB(fc, allBlocks)
	ecbSymbols := blocksToSymbols(ecbCipher)
	saveHistogramToCSV("histogram_ecb.csv", ecbSymbols)
	printHistogram("РЕЖИМ ECB", ecbSymbols)
	// --- ДОБАВЛЕНО: Энтропия ---
	fmt.Printf(">> Энтропия ECB: %.5f бит\n", calculateEntropy(ecbSymbols))

	// CBC
	cbcCipher := encryptCBC(fc, allBlocks, iv)
	cbcSymbols := blocksToSymbols(cbcCipher)
	saveHistogramToCSV("histogram_cbc.csv", cbcSymbols)
	printHistogram("РЕЖИМ CBC", cbcSymbols)
	// --- ДОБАВЛЕНО: Энтропия ---
	fmt.Printf(">> Энтропия CBC: %.5f бит\n", calculateEntropy(cbcSymbols))

	// CFB
	cfbCipher := encryptCFB(fc, allBlocks, iv)
	cfbSymbols := blocksToSymbols(cfbCipher)
	saveHistogramToCSV("histogram_cfb.csv", cfbSymbols)
	printHistogram("РЕЖИМ CFB", cfbSymbols)
	// --- ДОБАВЛЕНО: Энтропия ---
	fmt.Printf(">> Энтропия CFB: %.5f бит\n", calculateEntropy(cfbSymbols))

	// OFB
	ofbCipher := encryptOFB(fc, allBlocks, iv)
	ofbSymbols := blocksToSymbols(ofbCipher)
	saveHistogramToCSV("histogram_ofb.csv", ofbSymbols)
	printHistogram("РЕЖИМ OFB", ofbSymbols)
	// --- ДОБАВЛЕНО: Энтропия ---
	fmt.Printf(">> Энтропия OFB: %.5f бит\n", calculateEntropy(ofbSymbols))

	fmt.Println("\nВсе файлы успешно созданы.")
}
