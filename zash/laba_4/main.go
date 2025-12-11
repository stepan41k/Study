package main

import (
	"fmt"
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
	
	// ВАЖНО: Преобразуем строку в срез рун, чтобы индексы шли по порядку (0, 1, 2...),
	// а не по байтам (0, 2, 4...).
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

// --- ИСПРАВЛЕННАЯ ФУНКЦИЯ ШИФРОВАНИЯ ---
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

// --- ИСПРАВЛЕННАЯ ФУНКЦИЯ ДЕШИФРОВАНИЯ ---
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

// --- ИСПРАВЛЕННАЯ ФУНКЦИЯ ДЛЯ ЗАДАНИЯ 1 ---
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



// --- Утилиты для текста и блоков ---

// prepareText очищает и подготавливает текст для шифрования.
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

// textToBlocks преобразует строку в срез 10-битных блоков.
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


// blocksToText преобразует срез 10-битных блоков обратно в строку.
func blocksToText(blocks []uint16) string {
	var builder strings.Builder
	for _, block := range blocks {
		l, r := splitBlock(block)
		builder.WriteRune(ReverseAlphabetMap[l])
		builder.WriteRune(ReverseAlphabetMap[r])
	}

	return builder.String()
}

// blocksToSymbols преобразует срез 10-битных блоков в срез 5-битных символов для гистограммы.
func blocksToSymbols(blocks []uint16) []uint8 {
	symbols := make([]uint8, len(blocks)*2)
	for i, block := range blocks {
		l, r := splitBlock(block)
		symbols[2*i] = l
		symbols[2*i+1] = r
	}
	return symbols
}

// printHistogram выводит частотную гистограмму.
func printHistogram(title string, symbols []uint8) {
	fmt.Println(title)

	if len(ReverseAlphabetMap) == 0 {
		fmt.Println("Ошибка: Алфавит не инициализирован.")
		return
	}

	counts := make(map[uint8]int)
	for _, s := range symbols {
		counts[s]++
	}

	totalSymbols := float64(len(symbols))
	if totalSymbols == 0 {
		fmt.Println("Нет данных для построения гистограммы.")
		return
	}

	for i := uint8(0); i < 32; i++ {
		char, ok := ReverseAlphabetMap[i]
		if !ok {
			continue
		}

		count := counts[i]
		prob := float64(count) / totalSymbols
		barLen := int(prob * 100)
		bar := strings.Repeat("█", barLen)

		// Диапазон [1, 32] в задании, поэтому i+1
		fmt.Printf("Символ %2d ('%c') | %.4f | %s\n", i+1, char, prob, bar)
	}
	fmt.Println()
}


// ЗАДАНИЕ 2: РЕЖИМЫ ШИФРОВАНИЯ

func encryptECB(fc *FeistelCipher, plaintext []uint16) []uint16 {
	ciphertext := make([]uint16, len(plaintext))
	for i, block := range plaintext {
		ciphertext[i] = fc.EncryptBlock(block)
	}
	return ciphertext
}

func decryptECB(fc *FeistelCipher, ciphertext []uint16) []uint16 {
	plaintext := make([]uint16, len(ciphertext))
	for i, block := range ciphertext {
		plaintext[i] = fc.DecryptBlock(block)
	}
	return plaintext
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

func decryptCBC(fc *FeistelCipher, ciphertext []uint16, iv uint16) []uint16 {
	plaintext := make([]uint16, len(ciphertext))
	prevCipherBlock := iv
	for i, block := range ciphertext {
		decryptedBlock := fc.DecryptBlock(block)
		plaintext[i] = decryptedBlock ^ prevCipherBlock
		prevCipherBlock = block
	}
	return plaintext
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

func decryptCFB(fc *FeistelCipher, ciphertext []uint16, iv uint16) []uint16 {
	plaintext := make([]uint16, len(ciphertext))
	prevBlock := iv
	for i, cBlock := range ciphertext {
		keystream := fc.EncryptBlock(prevBlock)
		pBlock := cBlock ^ keystream
		plaintext[i] = pBlock
		prevBlock = cBlock
	}
	return plaintext
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

func decryptOFB(fc *FeistelCipher, ciphertext []uint16, iv uint16) []uint16 {
	return encryptOFB(fc, ciphertext, iv)
}


func main() {
	initializeMaps()

	const password = "Пуст мешок стоять не будет" 

	const sourceFilename = "source.txt"
	sourceBytes, err := os.ReadFile(sourceFilename)
	if err != nil {
		fmt.Printf("ОШИБКА: Не удалось прочитать исходный файл '%s'.\n", sourceFilename)
		fmt.Println("Пожалуйста, создайте этот файл в одной папке с программой и поместите в него текст для шифрования.")
		fmt.Printf("Детали ошибки: %v\n", err)
		return // Завершаем программу, если файл не найден
	}

	sourceText := string(sourceBytes)

	fmt.Printf("Исходный текст: %s\n", sourceText)
	fmt.Printf("Пароль: %s\n\n", password)

	fc, err := NewFeistelCipher(password)
	if err != nil {
		fmt.Println("Ошибка:", err)
		return
	}
	
	// --- ИЗМЕНЕННЫЙ БЛОК ЗАДАНИЯ 1 ---
	fmt.Println("--- ЗАДАНИЕ 1: ПОСТРОЕНИЕ ГИСТОГРАММ ПО РАУНДАМ ---")
	
	allBlocks, err := textToBlocks(sourceText)
	if err != nil {
		fmt.Println("Ошибка:", err)
		return
	}
	
	// Получаем результаты шифрования после каждого из 8 раундов
	roundData := EncryptAndRecordRounds(fc, allBlocks)

	// Последовательно выводим гистограммы для каждого раунда
	for i := 1; i <= 8; i++ {
		title := fmt.Sprintf("Гистограмма после раунда %d:", i)
		// Преобразуем блоки этого раунда в последовательность 5-битных символов
		symbols := blocksToSymbols(roundData[i])
		printHistogram(title, symbols)
	}


	// --- ЗАДАНИЕ 2: РЕАЛИЗАЦИЯ РЕЖИМОВ ШИФРОВАНИЯ ---
	fmt.Println("\n\n--- ЗАДАНИЕ 2: РЕЖИМЫ ШИФРОВАНИЯ ---")

	const iv uint16 = 819

	// 1. Режим ECB
	fmt.Println("--- 1. Режим ECB (Electronic Codebook) ---")
	ecbCiphertextBlocks := encryptECB(fc, allBlocks)
	ecbDecryptedBlocks := decryptECB(fc, ecbCiphertextBlocks)
	fmt.Println("Зашифрованный текст:", blocksToText(ecbCiphertextBlocks))
	printHistogram("Гистограмма для итогового шифротекста ECB:", blocksToSymbols(ecbCiphertextBlocks))
	fmt.Println("Расшифрованный текст:", blocksToText(ecbDecryptedBlocks))
	fmt.Println("Проверка:", prepareText(sourceText) == blocksToText(ecbDecryptedBlocks))

	// 2. Режим CBC
	fmt.Println("\n--- 2. Режим CBC (Cipher Block Chaining) ---")
	cbcCiphertextBlocks := encryptCBC(fc, allBlocks, iv)
	cbcDecryptedBlocks := decryptCBC(fc, cbcCiphertextBlocks, iv)
	fmt.Println("Зашифрованный текст:", blocksToText(cbcCiphertextBlocks))
	printHistogram("Гистограмма для шифротекста CBC:", blocksToSymbols(cbcCiphertextBlocks))
	fmt.Println("Расшифрованный текст:", blocksToText(cbcDecryptedBlocks))
	fmt.Println("Проверка:", prepareText(sourceText) == blocksToText(cbcDecryptedBlocks))
	
	// 3. Режим CFB
	fmt.Println("\n--- 3. Режим CFB (Cipher Feedback) ---")
	cfbCiphertextBlocks := encryptCFB(fc, allBlocks, iv)
	cfbDecryptedBlocks := decryptCFB(fc, cfbCiphertextBlocks, iv)
	fmt.Println("Зашифрованный текст:", blocksToText(cfbCiphertextBlocks))
	printHistogram("Гистограмма для шифротекста CFB:", blocksToSymbols(cfbCiphertextBlocks))
	fmt.Println("Расшифрованный текст:", blocksToText(cfbDecryptedBlocks))
	fmt.Println("Проверка:", prepareText(sourceText) == blocksToText(cfbDecryptedBlocks))

	// 4. Режим OFB
	fmt.Println("\n--- 4. Режим OFB (Output Feedback) ---")
	ofbCiphertextBlocks := encryptOFB(fc, allBlocks, iv)
	ofbDecryptedBlocks := decryptOFB(fc, ofbCiphertextBlocks, iv)
	fmt.Println("Зашифрованный текст:", blocksToText(ofbCiphertextBlocks))
	printHistogram("Гистограмма для шифротекста OFB:", blocksToSymbols(ofbCiphertextBlocks))
	fmt.Println("Расшифрованный текст:", blocksToText(ofbDecryptedBlocks))
	fmt.Println("Проверка:", prepareText(sourceText) == blocksToText(ofbDecryptedBlocks))
}