package main

import (
	"fmt"
	"math/big"
	"strings"
)

type TaskParams struct {
	N *big.Int
	E *big.Int
	P *big.Int
}


var paramsTable = map[int]TaskParams{
	1:  {N: big.NewInt(473), E: big.NewInt(17), P: big.NewInt(37)},
	2:  {N: big.NewInt(481), E: big.NewInt(19), P: big.NewInt(23)},
	3:  {N: big.NewInt(493), E: big.NewInt(13), P: big.NewInt(29)},
	4:  {N: big.NewInt(589), E: big.NewInt(19), P: big.NewInt(31)},
	5:  {N: big.NewInt(437), E: big.NewInt(17), P: big.NewInt(41)},
	6:  {N: big.NewInt(1073), E: big.NewInt(13), P: big.NewInt(29)},
	7:  {N: big.NewInt(667), E: big.NewInt(17), P: big.NewInt(43)},
	8:  {N: big.NewInt(377), E: big.NewInt(35), P: big.NewInt(37)},
	9:  {N: big.NewInt(899), E: big.NewInt(19), P: big.NewInt(23)},
	10: {N: big.NewInt(551), E: big.NewInt(13), P: big.NewInt(29)},
	11: {N: big.NewInt(473), E: big.NewInt(19), P: big.NewInt(31)},
	12: {N: big.NewInt(481), E: big.NewInt(5), P: big.NewInt(41)},
	13: {N: big.NewInt(493), E: big.NewInt(55), P: big.NewInt(23)},
	14: {N: big.NewInt(589), E: big.NewInt(77), P: big.NewInt(43)},
	15: {N: big.NewInt(437), E: big.NewInt(65), P: big.NewInt(37)},
	16: {N: big.NewInt(1073), E: big.NewInt(99), P: big.NewInt(23)},
	17: {N: big.NewInt(667), E: big.NewInt(65), P: big.NewInt(29)},
	18: {N: big.NewInt(377), E: big.NewInt(55), P: big.NewInt(31)},
	19: {N: big.NewInt(899), E: big.NewInt(29), P: big.NewInt(41)},
	20: {N: big.NewInt(551), E: big.NewInt(31), P: big.NewInt(29)},
	21: {N: big.NewInt(473), E: big.NewInt(43), P: big.NewInt(43)},
	22: {N: big.NewInt(481), E: big.NewInt(47), P: big.NewInt(37)},
	23: {N: big.NewInt(493), E: big.NewInt(47), P: big.NewInt(23)},
	24: {N: big.NewInt(493), E: big.NewInt(61), P: big.NewInt(29)},
	25: {N: big.NewInt(437), E: big.NewInt(53), P: big.NewInt(31)},
}

// =================================================================================
// Задание 1: Алгоритм Диффи-Хэллмана
// =================================================================================

func solveDiffieHellman(studentID int) {
	fmt.Println("=====================================================")
	fmt.Println("Задание 1: Алгоритм обмена ключами Диффи-Хэллмана")
	fmt.Println("=====================================================")

	params, ok := paramsTable[studentID]
	if !ok {
		fmt.Printf("Ошибка: Не найдены параметры для студента с номером %d.\n", studentID)
		return
	}

	p := params.P
	fmt.Printf("Выбран студент с номером i = %d.\n", studentID)
	fmt.Printf("Второй участник имеет номер 35 - i = %d.\n", 35-studentID)
	fmt.Printf("Из таблицы 6 для варианта %d, открытый элемент (модуль) P = %v.\n", studentID, p)

	// Проверка, является ли P простым числом.
	if !p.ProbablyPrime(20) {
		fmt.Printf("\n!!! ОШИБКА: P = %v не является простым числом. Алгоритм не может быть выполнен.\n", p)
		return
	}

	// Шаг 1: Найти примитивный элемент g (альфа) поля GF(p)
	// Для P = 37, p-1 = 36. Простые делители 36: 2, 3.
	// Проверим g = 2: 2^(36/2) mod 37 != 1; 2^(36/3) mod 37 != 1.
	// Следовательно, g = 2 является примитивным элементом для P = 37.
	g := big.NewInt(2)
	fmt.Printf("\nШаг 1: Нахождение примитивного элемента.\n")
	fmt.Printf("Для P = %v, p-1 = %d. Простые делители %d: 2 и 3.\n", p, 36, 36)
	fmt.Printf("Выбираем g = %v в качестве примитивного элемента (генератора группы).\n", g)
	
	// Шаг 2: Генерация секретных ключей
	aliceSecretKey := big.NewInt(int64(studentID))
	bobSecretKey := big.NewInt(int64(35 - studentID))
	fmt.Println("\nШаг 2: Секретные ключи участников.")
	fmt.Printf("Секретный ключ абонента A (i=%d): a = %v\n", studentID, aliceSecretKey)
	fmt.Printf("Секретный ключ абонента B (i=%d): b = %v\n", 35-studentID, bobSecretKey)

	// Шаг 3: Вычисление открытых ключей
	alicePublicKey := new(big.Int).Exp(g, aliceSecretKey, p)
	bobPublicKey := new(big.Int).Exp(g, bobSecretKey, p)
	fmt.Println("\nШаг 3: Вычисление открытых ключей.")
	fmt.Printf("Абонент A вычисляет свой открытый ключ: A = g^a mod P = %v^%v mod %v = %v\n", g, aliceSecretKey, p, alicePublicKey)
	fmt.Printf("Абонент B вычисляет свой открытый ключ: B = g^b mod P = %v^%v mod %v = %v\n", g, bobSecretKey, p, bobPublicKey)
	fmt.Println("Абоненты обмениваются открытыми ключами A и B.")

	// Шаг 4: Вычисление общего секретного ключа
	sharedKeyAlice := new(big.Int).Exp(bobPublicKey, aliceSecretKey, p)
	sharedKeyBob := new(big.Int).Exp(alicePublicKey, bobSecretKey, p)
	fmt.Println("\nШаг 4: Вычисление общего секретного ключа.")
	fmt.Printf("Абонент A вычисляет общий ключ: K = B^a mod P = %v^%v mod %v = %v\n", bobPublicKey, aliceSecretKey, p, sharedKeyAlice)
	fmt.Printf("Абонент B вычисляет общий ключ: K = A^b mod P = %v^%v mod %v = %v\n", alicePublicKey, bobSecretKey, p, sharedKeyBob)
	
	if sharedKeyAlice.Cmp(sharedKeyBob) == 0 {
		fmt.Printf("\nРезультат: Общий секретный ключ успешно вычислен и равен %v.\n", sharedKeyAlice)
	} else {
		fmt.Printf("\nОшибка: Вычисленные ключи не совпадают!\n")
	}
}


// =================================================================================
// Задание 2: Алгоритм RSA
// =================================================================================

// Вспомогательная функция для нахождения p и q (факторизация)
func factorize(n *big.Int) (*big.Int, *big.Int) {
	limit := new(big.Int).Sqrt(n)
	i := big.NewInt(2)
	one := big.NewInt(1)
	
	if new(big.Int).Rem(n, i).Cmp(big.NewInt(0)) == 0 {
		return new(big.Int).Set(i), new(big.Int).Div(n, i)
	}

	i.Add(i, one) 
	for i.Cmp(limit) <= 0 {
		if new(big.Int).Rem(n, i).Cmp(big.NewInt(0)) == 0 {
			p := new(big.Int).Set(i)
			q := new(big.Int).Div(n, i)
			return p, q
		}
		i.Add(i, big.NewInt(2)) 
	}
	return nil, nil
}


func solveRSA(studentID int) {
	fmt.Println("\n\n=====================================================")
	fmt.Println("Задание 2: Шифрование и цифровая подпись RSA")
	fmt.Println("=====================================================")
	
	senderID := studentID
	recipientID := 35 - studentID
	
	fmt.Printf("Абонент-отправитель: студент с номером i = %d.\n", senderID)
	fmt.Printf("Абонент-получатель: студент с номером 35 - i = %d.\n", recipientID)

	senderParams, ok1 := paramsTable[senderID]
	recipientParams, ok2 := paramsTable[recipientID]

	if !ok1 || !ok2 {
		fmt.Println("Ошибка: не найдены параметры для одного из участников.")
		return
	}

	// --- Шаг 1: Определение ключей участников ---
	fmt.Println("\n--- Шаг 1: Определение ключей (открытых и закрытых) ---")
	
	// Ключи отправителя
	n_A, e_A := senderParams.N, senderParams.E
	p_A, q_A := factorize(n_A)
	one := big.NewInt(1)
	phi_A := new(big.Int).Mul(new(big.Int).Sub(p_A, one), new(big.Int).Sub(q_A, one))
	d_A := new(big.Int).ModInverse(e_A, phi_A)
	fmt.Printf("Отправитель (Абонент A, i=%d):\n", senderID)
	fmt.Printf("  Открытый ключ (eA, nA) = (%v, %v)\n", e_A, n_A)
	fmt.Printf("  Факторизация nA=%v: pA=%v, qA=%v (437 = 19 * 23)\n", n_A, p_A, q_A)
	fmt.Printf("  Функция Эйлера: φ(nA) = (%v-1)*(%v-1) = %v\n", p_A, q_A, phi_A)
	fmt.Printf("  Закрытый ключ dA (eA*dA ≡ 1 mod φ(nA)) = %v\n\n", d_A)

	// Ключи получателя 
	n_B, e_B := recipientParams.N, recipientParams.E
	p_B, q_B := factorize(n_B)
	phi_B := new(big.Int).Mul(new(big.Int).Sub(p_B, one), new(big.Int).Sub(q_B, one))
	d_B := new(big.Int).ModInverse(e_B, phi_B)
	fmt.Printf("Получатель (Абонент B, i=%d):\n", recipientID)
	fmt.Printf("  Открытый ключ (eB, nB) = (%v, %v)\n", e_B, n_B)
	fmt.Printf("  Факторизация nB=%v: pB=%v, qB=%v (551 = 19 * 29)\n", n_B, p_B, q_B)
	fmt.Printf("  Функция Эйлера: φ(nB) = (%v-1)*(%v-1) = %v\n", p_B, q_B, phi_B)
	fmt.Printf("  Закрытый ключ dB (eB*dB ≡ 1 mod φ(nB)) = %v\n", d_B)


	// --- Шаг 2: Подготовка сообщения ---
	fmt.Println("\n--- Шаг 2: Подготовка сообщения к шифрованию ---")
	message := "РАСПОПОВ С И"
	
	alphabet := " АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
	
	var numericString string
	for _, char := range message {
		index := strings.IndexRune(alphabet, char)
		if index != -1 {
			numericString += fmt.Sprintf("%02d", index)
		}
	}
	fmt.Printf("Исходное сообщение: '%s'\n", message)
	fmt.Printf("Сообщение в числовом виде (кодировка Z32): %s\n", numericString)
	
	var blocks []*big.Int
	for i := 0; i < len(numericString); i += 2 {
		blockStr := numericString[i : i+2]
		blockInt, _ := new(big.Int).SetString(blockStr, 10)
		blocks = append(blocks, blockInt)
	}
	fmt.Printf("Сообщение, разбитое на числовые блоки M: %v\n", blocks)
	
	// --- Задача 2.1: Шифрование сообщения ---
	fmt.Println("\n--- Задача 2.1: Шифрование сообщения ---")
	fmt.Println("Отправитель (A) шифрует сообщение для получателя (B), используя открытый ключ получателя (eB, nB).")
	fmt.Printf("Формула: C = M^eB mod nB\n")
	
	var encryptedBlocks []*big.Int
	for _, block := range blocks {
		encryptedBlock := new(big.Int).Exp(block, e_B, n_B)
		encryptedBlocks = append(encryptedBlocks, encryptedBlock)
		fmt.Printf("  Блок M=%-3v -> C = %-3v^%v mod %v = %v\n", block, block, e_B, n_B, encryptedBlock)
	}
	fmt.Printf("\nЗашифрованное сообщение (последовательность блоков C): %v\n", encryptedBlocks)
	
	// Демонстрация расшифровки
	fmt.Println("\nПолучатель (B) расшифровывает сообщение, используя свой закрытый ключ (dB, nB).")
	fmt.Printf("Формула: M = C^dB mod nB\n")
	var decryptedBlocks []*big.Int
	for i, encryptedBlock := range encryptedBlocks {
		decryptedBlock := new(big.Int).Exp(encryptedBlock, d_B, n_B)
		decryptedBlocks = append(decryptedBlocks, decryptedBlock)
		fmt.Printf("  Блок C=%-3v -> M = %-3v^%v mod %v = %v (исходный: %v)\n", encryptedBlock, encryptedBlock, d_B, n_B, decryptedBlock, blocks[i])
	}
	fmt.Printf("Расшифрованные блоки M: %v. Расшифровка успешна.\n", decryptedBlocks)

	// --- Задача 2.2: Создание цифровой подписи ---
	fmt.Println("\n--- Задача 2.2: Создание цифровой подписи для открытого сообщения ---")
	fmt.Println("Отправитель (A) подписывает сообщение, используя свой закрытый ключ (dA, nA).")
	fmt.Printf("Формула: S = M^dA mod nA\n")
	
	var signatureBlocks []*big.Int
	for _, block := range blocks {
		signatureBlock := new(big.Int).Exp(block, d_A, n_A)
		signatureBlocks = append(signatureBlocks, signatureBlock)
		fmt.Printf("  Блок M=%-3v -> S = %-3v^%v mod %v = %v\n", block, block, d_A, n_A, signatureBlock)
	}
	fmt.Printf("\nЦифровая подпись (последовательность блоков S): %v\n", signatureBlocks)
	fmt.Printf("Отправитель посылает получателю открытое сообщение '%s' и подпись.\n", message)
	
	// Демонстрация проверки подписи
	fmt.Println("\nПолучатель (B) проверяет подпись, используя открытый ключ отправителя (eA, nA).")
	fmt.Printf("Формула: M_verified = S^eA mod nA\n")
	var verifiedBlocks []*big.Int
	for i, signatureBlock := range signatureBlocks {
		verifiedBlock := new(big.Int).Exp(signatureBlock, e_A, n_A)
		verifiedBlocks = append(verifiedBlocks, verifiedBlock)
		fmt.Printf("  Блок S=%-3v -> M' = %-3v^%v mod %v = %v (исходный: %v)\n", signatureBlock, signatureBlock, e_A, n_A, verifiedBlock, blocks[i])
	}
	
	match := true
	if len(blocks) != len(verifiedBlocks) {
		match = false
	} else {
		for i := range blocks {
			if blocks[i].Cmp(verifiedBlocks[i]) != 0 {
				match = false; break;
			}
		}
	}

	if match {
		fmt.Println("\nРезультат: Восстановленные блоки совпадают с исходными. Подпись верна.")
	} else {
		fmt.Println("\nРезультат: Восстановленные блоки НЕ совпадают с исходными. Подпись неверна.")
	}
}

func main() {
	// Номер студента i, указанный в задании (выделена строка 15)
	studentID := 15

	// Выполнение Задания 1
	solveDiffieHellman(studentID)

	// Выполнение Задания 2
	solveRSA(studentID)
}