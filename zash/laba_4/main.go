package main

import (
	"fmt"
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
	for i, r := range alphabet {
		AlphabetMap[r] = uint8(i)
		ReverseAlphabetMap[uint8(i)] = r
	}
}

// FeistelCipher представляет собой структуру для шифра на основе сети Фейстеля.
type FeistelCipher struct {
	roundKeys []uint8
}

// NewFeistelCipher создает новый экземпляр шифра с ключами, сгенерированными из пароля.
// Ключи - это последовательные 5-битные отрезки пароля.
// Для 8 раундов требуется пароль длиной не менее 8 символов.
func NewFeistelCipher(password string) (*FeistelCipher, error) {
	password = strings.ToUpper(password)
	if len(password) < 8 {
		return nil, fmt.Errorf("длина пароля должна быть не менее 8 символов для 8 раундов")
	}

	keys := make([]uint8, 8)
	for i := 0; i < 8; i++ {
		r := rune(password[i])
		if val, ok := AlphabetMap[r]; ok {
			keys[i] = val
		} else {
			return nil, fmt.Errorf("недопустимый символ в пароле: %c", r)
		}
	}

	return &FeistelCipher{roundKeys: keys}, nil
}

// fFunction - раундовая функция F.
// В соответствии со схемой: F(R, K) = ((R + K) mod 32) XOR R
func (fc *FeistelCipher) fFunction(r, key uint8) uint8 {
	// Сложение по модулю 32 (5 бит)
	sum := (r + key) & 0x1F
	// XOR с исходной правой частью
	return sum ^ r
}

// splitBlock разделяет 10-битный блок на две 5-битные части (L и R).
func splitBlock(block uint16) (uint8, uint8) {
	l := uint8((block >> 5) & 0x1F)
	r := uint8(block & 0x1F)
	return l, r
}

// combineHalves объединяет две 5-битные части в один 10-битный блок.
func combineHalves(l, r uint8) uint16 {
	return (uint16(l) << 5) | uint16(r)
}

// EncryptBlock шифрует один 10-битный блок.
// Параметр verbose управляет выводом промежуточных результатов.
func (fc *FeistelCipher) EncryptBlock(block uint16, verbose bool) uint16 {
	l, r := splitBlock(block)
	if verbose {
		fmt.Printf("Начальный блок: L0=%d (%s), R0=%d (%s)\n", l, string(ReverseAlphabetMap[l]), r, string(ReverseAlphabetMap[r]))
	}

	for i := 0; i < 8; i++ {
		l_prev, r_prev := l, r
		f_result := fc.fFunction(r_prev, fc.roundKeys[i])
		l = r_prev
		r = l_prev ^ f_result

		if verbose {
			fmt.Printf("Раунд %d: Ключ K%d=%d (%s)\n", i+1, i+1, fc.roundKeys[i], string(ReverseAlphabetMap[fc.roundKeys[i]]))
			fmt.Printf("  F(R%d, K%d) = F(%d, %d) = %d\n", i, i+1, r_prev, fc.roundKeys[i], f_result)
			fmt.Printf("  L%d = R%d = %d\n", i+1, i, r_prev)
			fmt.Printf("  R%d = L%d XOR F = %d XOR %d = %d\n", i+1, i, l_prev, f_result, r)
			fmt.Printf("  Результат раунда: L%d=%d (%s), R%d=%d (%s)\n\n", i+1, l, string(ReverseAlphabetMap[l]), i+1, r, string(ReverseAlphabetMap[r]))
		}
	}

	// Важно: после последнего раунда половины L и R не меняются местами.
	return combineHalves(l, r)
}

// DecryptBlock расшифровывает один 10-битный блок.
func (fc *FeistelCipher) DecryptBlock(block uint16) uint16 {
	l, r := splitBlock(block)

	// Раунды и ключи используются в обратном порядке.
	for i := 7; i >= 0; i-- {
		l_prev, r_prev := l, r
		f_result := fc.fFunction(l_prev, fc.roundKeys[i])
		r = l_prev
		l = r_prev ^ f_result
	}
	return combineHalves(l, r)
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
	// Если длина нечетная, добавляем 'А' для выравнивания
	if builder.Len()%2 != 0 {
		builder.WriteRune('А')
	}
	return builder.String()
}

// textToBlocks преобразует строку в срез 10-битных блоков.
func textToBlocks(text string) ([]uint16, error) {
	preparedText := prepareText(text)
	numBlocks := len(preparedText) / 2
	blocks := make([]uint16, numBlocks)

	for i := 0; i < numBlocks; i++ {
		r1 := rune(preparedText[2*i])
		r2 := rune(preparedText[2*i+1])

		v1, ok1 := AlphabetMap[r1]
		v2, ok2 := AlphabetMap[r2]

		if !ok1 || !ok2 {
			return nil, fmt.Errorf("недопустимый символ в тексте")
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

// printHistogram выводит частотную гистограмму для среза символов.
func printHistogram(title string, symbols []uint8) {
	fmt.Println(title)
	counts := make(map[uint8]int)
	for _, s := range symbols {
		counts[s]++
	}
	// Вывод отсортирован по символам (0-31)
	for i := uint8(0); i < 32; i++ {
		if count, ok := counts[i]; ok {
			char := ReverseAlphabetMap[i]
			// Диапазон [1, 32] в задании, поэтому i+1
			fmt.Printf("Символ %2d ('%c'): %s (%d)\n", i+1, char, strings.Repeat("=", count), count)
		}
	}
	fmt.Println()
}

// ЗАДАНИЕ 2: РЕЖИМЫ ШИФРОВАНИЯ

// encryptECB шифрует в режиме Electronic Codebook.
func encryptECB(fc *FeistelCipher, plaintext []uint16) []uint16 {
	ciphertext := make([]uint16, len(plaintext))
	for i, block := range plaintext {
		ciphertext[i] = fc.EncryptBlock(block, false)
	}
	return ciphertext
}

// decryptECB расшифровывает в режиме Electronic Codebook.
func decryptECB(fc *FeistelCipher, ciphertext []uint16) []uint16 {
	plaintext := make([]uint16, len(ciphertext))
	for i, block := range ciphertext {
		plaintext[i] = fc.DecryptBlock(block)
	}
	return plaintext
}

// encryptCBC шифрует в режиме Cipher Block Chaining.
func encryptCBC(fc *FeistelCipher, plaintext []uint16, iv uint16) []uint16 {
	ciphertext := make([]uint16, len(plaintext))
	prevCipherBlock := iv
	for i, block := range plaintext {
		inputBlock := block ^ prevCipherBlock
		encryptedBlock := fc.EncryptBlock(inputBlock, false)
		ciphertext[i] = encryptedBlock
		prevCipherBlock = encryptedBlock
	}
	return ciphertext
}

// decryptCBC расшифровывает в режиме Cipher Block Chaining.
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

// encryptCFB шифрует в режиме Cipher Feedback.
func encryptCFB(fc *FeistelCipher, plaintext []uint16, iv uint16) []uint16 {
	ciphertext := make([]uint16, len(plaintext))
	prevBlock := iv
	for i, pBlock := range plaintext {
		keystream := fc.EncryptBlock(prevBlock, false)
		cBlock := pBlock ^ keystream
		ciphertext[i] = cBlock
		prevBlock = cBlock
	}
	return ciphertext
}

// decryptCFB расшифровывает в режиме Cipher Feedback.
func decryptCFB(fc *FeistelCipher, ciphertext []uint16, iv uint16) []uint16 {
	plaintext := make([]uint16, len(ciphertext))
	prevBlock := iv
	for i, cBlock := range ciphertext {
		keystream := fc.EncryptBlock(prevBlock, false)
		pBlock := cBlock ^ keystream
		plaintext[i] = pBlock
		prevBlock = cBlock
	}
	return plaintext
}

// encryptOFB шифрует в режиме Output Feedback.
func encryptOFB(fc *FeistelCipher, plaintext []uint16, iv uint16) []uint16 {
	ciphertext := make([]uint16, len(plaintext))
	prevOutput := iv
	for i, pBlock := range plaintext {
		keystream := fc.EncryptBlock(prevOutput, false)
		ciphertext[i] = pBlock ^ keystream
		prevOutput = keystream
	}
	return ciphertext
}

// decryptOFB расшифровывает в режиме Output Feedback.
func decryptOFB(fc *FeistelCipher, ciphertext []uint16, iv uint16) []uint16 {
	// Дешифрование OFB идентично шифрованию
	return encryptOFB(fc, ciphertext, iv)
}

func main() {
	initializeMaps()

	// --- ИСХОДНЫЕ ДАННЫЕ ---
	const plainText = "РЕЖИМЫШИФРОВАНИЯБЛОЧНЫХШИФРОВ"
	const password = "СЕКРЕТНЫЙКЛЮЧ" // Используются первые 8 символов

	fmt.Printf("Исходный текст: %s\n", plainText)
	fmt.Printf("Пароль: %s\n\n", password)

	// --- ЗАДАНИЕ 1: Реализация и демонстрация сети Фейстеля ---
	fmt.Println("--- ЗАДАНИЕ 1: РЕАЛИЗАЦИЯ СЕТИ ФЕЙСТЕЛЯ ---")
	
	fc, err := NewFeistelCipher(password)
	if err != nil {
		fmt.Println("Ошибка:", err)
		return
	}
	
	// Шифруем первый блок текста с подробным выводом
	blocks, err := textToBlocks(plainText)
	if err != nil {
		fmt.Println("Ошибка:", err)
		return
	}

	fmt.Println("Демонстрация шифрования первого блока текста ('РЕ'):")
	encryptedBlock := fc.EncryptBlock(blocks[0], true)
	decryptedBlock := fc.DecryptBlock(encryptedBlock)

	fmt.Printf("Исходный блок: %d (%s)\n", blocks[0], blocksToText([]uint16{blocks[0]}))
	fmt.Printf("Зашифрованный блок: %d (%s)\n", encryptedBlock, blocksToText([]uint16{encryptedBlock}))
	fmt.Printf("Расшифрованный блок: %d (%s)\n", decryptedBlock, blocksToText([]uint16{decryptedBlock}))
	fmt.Println("Проверка: ", blocksToText([]uint16{blocks[0]}) == blocksToText([]uint16{decryptedBlock}))

	// --- ЗАДАНИЕ 2: Реализация режимов шифрования ---
	fmt.Println("\n\n--- ЗАДАНИЕ 2: РЕЖИМЫ ШИФРОВАНИЯ ---")

	// Вектор инициализации (IV), 10-битное число, например 0b1100110011 = 819
	const iv uint16 = 819

	// 1. Режим ECB
	fmt.Println("--- 1. Режим ECB (Electronic Codebook) ---")
	ecbCiphertextBlocks := encryptECB(fc, blocks)
	ecbDecryptedBlocks := decryptECB(fc, ecbCiphertextBlocks)
	fmt.Println("Зашифрованный текст:", blocksToText(ecbCiphertextBlocks))
	printHistogram("Гистограмма для шифротекста ECB:", blocksToSymbols(ecbCiphertextBlocks))
	fmt.Println("Расшифрованный текст:", blocksToText(ecbDecryptedBlocks))
	fmt.Println("Проверка:", plainText == prepareText(blocksToText(ecbDecryptedBlocks)))

	// 2. Режим CBC
	fmt.Println("\n--- 2. Режим CBC (Cipher Block Chaining) ---")
	cbcCiphertextBlocks := encryptCBC(fc, blocks, iv)
	cbcDecryptedBlocks := decryptCBC(fc, cbcCiphertextBlocks, iv)
	fmt.Println("Зашифрованный текст:", blocksToText(cbcCiphertextBlocks))
	printHistogram("Гистограмма для шифротекста CBC:", blocksToSymbols(cbcCiphertextBlocks))
	fmt.Println("Расшифрованный текст:", blocksToText(cbcDecryptedBlocks))
	fmt.Println("Проверка:", plainText == prepareText(blocksToText(cbcDecryptedBlocks)))
	
	// 3. Режим CFB
	fmt.Println("\n--- 3. Режим CFB (Cipher Feedback) ---")
	cfbCiphertextBlocks := encryptCFB(fc, blocks, iv)
	cfbDecryptedBlocks := decryptCFB(fc, cfbCiphertextBlocks, iv)
	fmt.Println("Зашифрованный текст:", blocksToText(cfbCiphertextBlocks))
	printHistogram("Гистограмма для шифротекста CFB:", blocksToSymbols(cfbCiphertextBlocks))
	fmt.Println("Расшифрованный текст:", blocksToText(cfbDecryptedBlocks))
	fmt.Println("Проверка:", plainText == prepareText(blocksToText(cfbDecryptedBlocks)))

	// 4. Режим OFB
	fmt.Println("\n--- 4. Режим OFB (Output Feedback) ---")
	ofbCiphertextBlocks := encryptOFB(fc, blocks, iv)
	ofbDecryptedBlocks := decryptOFB(fc, ofbCiphertextBlocks, iv)
	fmt.Println("Зашифрованный текст:", blocksToText(ofbCiphertextBlocks))
	printHistogram("Гистограмма для шифротекста OFB:", blocksToSymbols(ofbCiphertextBlocks))
	fmt.Println("Расшифрованный текст:", blocksToText(ofbDecryptedBlocks))
	fmt.Println("Проверка:", plainText == prepareText(blocksToText(ofbDecryptedBlocks)))
}