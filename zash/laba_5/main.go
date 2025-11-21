package main

import (
	"fmt"
	"math/big"
	"strings"
)

// Структура для хранения параметров участника из таблицы
type ParticipantParams struct {
	ID int
	N  int64
	E  int64
	P  int64 // В задании 1 это "открытый элемент P"
}

// --- Задание 1: Диффи-Хеллман ---

// Факторизует число n на два простых сомножителя
func factorize(n int64) (int64, int64) {
	for i := int64(2); i*i <= n; i++ {
		if n%i == 0 {
			return i, n / i
		}
	}
	return n, 1
}

// Находит наименьший примитивный корень по модулю p
func findPrimitiveRoot(p int64) int64 {
	if p == 2 {
		return 1
	}

	phi := p - 1
	pMinus1Factors := findPrimeFactors(phi)

	for g := int64(2); g <= p; g++ {
		isPrimitive := true
		for _, factor := range pMinus1Factors {
			// g^((p-1)/factor) mod p
			exp := new(big.Int).Div(big.NewInt(phi), big.NewInt(factor))
			res := new(big.Int).Exp(big.NewInt(g), exp, big.NewInt(p))
			if res.Cmp(big.NewInt(1)) == 0 {
				isPrimitive = false
				break
			}
		}
		if isPrimitive {
			return g
		}
	}
	return -1
}

// Находит простые сомножители числа
func findPrimeFactors(n int64) []int64 {
	factors := make(map[int64]bool)
	d := int64(2)
	temp := n
	for d*d <= temp {
		if temp%d == 0 {
			factors[d] = true
			temp /= d
		} else {
			d++
		}
	}
	if temp > 1 {
		factors[temp] = true
	}

	keys := make([]int64, 0, len(factors))
	for k := range factors {
		keys = append(keys, k)
	}
	return keys
}

func solveDiffieHellman(params ParticipantParams, studentI, studentJ int) {
	fmt.Println("--- Задание 1: Реализация обмена ключами по алгоритму Диффи-Хеллмана ---")

	// 1. Находим p из n участника i
	p, q := factorize(params.N)
	// Обычно берется большее простое число
	if p < q {
		p, q = q, p
	}
	fmt.Printf("1. Параметры участника %d: n = %d. Факторизуем n: %d * %d. Выбираем p = %d.\n", studentI, params.N, p, q, p)

	// 2. Находим примитивный элемент поля GF(p)
	g := findPrimitiveRoot(p)
	fmt.Printf("2. Находим примитивный корень (генератор) g для поля GF(%d). g = %d.\n", p, g)

	// 3. Секретные ключи участников
	a := int64(studentI)
	b := int64(studentJ)
	fmt.Printf("3. Секретные ключи: a = %d (для участника %d), b = %d (для участника %d).\n", a, studentI, b, studentJ)

	// 4. Вычисление открытых ключей
	bigP := big.NewInt(p)
	bigG := big.NewInt(g)
	bigA := new(big.Int).Exp(bigG, big.NewInt(a), bigP)
	bigB := new(big.Int).Exp(bigG, big.NewInt(b), bigP)
	fmt.Printf("4. Участник %d вычисляет открытый ключ A = g^a mod p = %d^%d mod %d = %s\n", studentI, g, a, p, bigA.String())
	fmt.Printf("   Участник %d вычисляет открытый ключ B = g^b mod p = %d^%d mod %d = %s\n", studentJ, g, b, p, bigB.String())

	// 5. Вычисление общего секретного ключа
	sharedKey1 := new(big.Int).Exp(bigB, big.NewInt(a), bigP)
	sharedKey2 := new(big.Int).Exp(bigA, big.NewInt(b), bigP)
	fmt.Printf("5. Участник %d вычисляет общий ключ S1 = B^a mod p = %s^%d mod %d = %s\n", studentI, bigB.String(), a, p, sharedKey1.String())
	fmt.Printf("   Участник %d вычисляет общий ключ S2 = A^b mod p = %s^%d mod %d = %s\n", studentJ, bigA.String(), b, p, sharedKey2.String())

	fmt.Printf("\nРезультат: Общий секретный ключ равен: %s\n", sharedKey1.String())
	fmt.Println(strings.Repeat("-", 70))
}

// --- Задание 2: RSA ---

// Преобразование текста в числовые блоки
func textToBlocks(text string, n int64) []*big.Int {
	// Кодировка Z32: А=1, Б=2, ... Я=33, пробел=99
	alphabet := "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
	mapping := make(map[rune]int)
	for i, r := range alphabet {
		mapping[r] = i + 1
	}

	var numericStrings []string
	for _, char := range strings.ToUpper(text) {
		if val, ok := mapping[char]; ok {
			numericStrings = append(numericStrings, fmt.Sprintf("%02d", val))
		} else if char == ' ' {
			numericStrings = append(numericStrings, "99")
		} else if char == '.' {
			// Игнорируем точки в инициалах
		}
	}

	var blocks []*big.Int
	currentBlock := ""
	for _, numStr := range numericStrings {
		if len(currentBlock+numStr) >= len(fmt.Sprintf("%d", n)) {
			blockInt, _ := new(big.Int).SetString(currentBlock, 10)
			if blockInt.Cmp(big.NewInt(n)) < 0 {
				blocks = append(blocks, blockInt)
				currentBlock = numStr
			} else {
				panic("Ошибка: блок превышает n")
			}
		} else {
			currentBlock += numStr
		}
	}
	if len(currentBlock) > 0 {
		blockInt, _ := new(big.Int).SetString(currentBlock, 10)
		blocks = append(blocks, blockInt)
	}
	return blocks
}

func solveRSA(sender, receiver ParticipantParams) {
	fmt.Println("--- Задание 2: Реализация шифрования и цифровой подписи RSA ---")

	// --- 2.1. Шифрование сообщения ---
	fmt.Println("\n--- 2.1. Абонент", sender.ID, "отправляет зашифрованное сообщение абоненту", receiver.ID, "---")
	message := "ПЕТРОВ И А"
	fmt.Printf("Исходное сообщение: \"%s\"\n", message)

	// Шифруем с помощью ОТКРЫТОГО ключа получателя (receiver)
	blocks := textToBlocks(message, receiver.N)
	fmt.Println("Сообщение, разбитое на числовые блоки M:", blocks)

	encryptedBlocks := make([]*big.Int, len(blocks))
	bigNReceiver := big.NewInt(receiver.N)
	bigEReceiver := big.NewInt(receiver.E)

	for i, m := range blocks {
		c := new(big.Int).Exp(m, bigEReceiver, bigNReceiver)
		encryptedBlocks[i] = c
	}

	fmt.Printf("Шифрование с помощью открытого ключа получателя (e=%d, n=%d).\n", receiver.E, receiver.N)
	fmt.Println("Зашифрованные блоки C:", encryptedBlocks)

	// --- 2.2. Создание цифровой подписи ---
	fmt.Println("\n--- 2.2. Абонент", sender.ID, "подписывает сообщение для абонента", receiver.ID, "---")
	fmt.Printf("Исходное сообщение: \"%s\"\n", message)

	// Подписываем с помощью СЕКРЕТНОГО ключа отправителя (sender)
	// 1. Вычисляем секретный ключ d для отправителя
	p, q := factorize(sender.N)
	bigP := big.NewInt(p - 1)
	bigQ := big.NewInt(q - 1)
	phi := new(big.Int).Mul(bigP, bigQ)

	bigESender := big.NewInt(sender.E)
	d := new(big.Int).ModInverse(bigESender, phi)

	fmt.Printf("1. Вычисляем секретный ключ d для отправителя (ID=%d):\n", sender.ID)
	fmt.Printf("   n = %d, e = %d. Факторы: p=%d, q=%d.\n", sender.N, sender.E, p, q)
	fmt.Printf("   Функция Эйлера φ(n) = (p-1)*(q-1) = %s\n", phi.String())
	fmt.Printf("   Секретный ключ d (e*d ≡ 1 mod φ(n)) = %s\n", d.String())

	// 2. Подписываем каждый блок
	signatureBlocks := make([]*big.Int, len(blocks))
	bigNSender := big.NewInt(sender.N)
	for i, m := range blocks {
		s := new(big.Int).Exp(m, d, bigNSender)
		signatureBlocks[i] = s
	}
	fmt.Println("2. Подписываем сообщение с помощью секретного ключа отправителя d.")
	fmt.Println("Исходные блоки M:", blocks)
	fmt.Println("Блоки подписи S:", signatureBlocks)

	// 3. Проверка подписи (для демонстрации)
	fmt.Println("\n3. Получатель (ID=", receiver.ID, ") проверяет подпись с помощью открытого ключа отправителя (e,n).")
	fmt.Printf("   Ключ проверки: e=%d, n=%d\n", sender.E, sender.N)

	verified := true
	for i, s := range signatureBlocks {
		mPrime := new(big.Int).Exp(s, bigESender, bigNSender)
		fmt.Printf("   Проверка блока %d: S^e mod n = %s^%d mod %d = %s. Исходный блок M = %s. ", i+1, s.String(), sender.E, sender.N, mPrime.String(), blocks[i].String())
		if mPrime.Cmp(blocks[i]) == 0 {
			fmt.Println("-> Подпись верна.")
		} else {
			fmt.Println("-> ПОДПИСЬ НЕВЕРНА!")
			verified = false
		}
	}
	if verified {
		fmt.Println("Результат: Цифровая подпись всего сообщения подтверждена.")
	} else {
		fmt.Println("Результат: Цифровая подпись сообщения НЕ подтверждена.")
	}
	fmt.Println(strings.Repeat("-", 70))
}

func main() {
	// Данные из Таблицы 6
	allParams := map[int]ParticipantParams{
		15: {ID: 15, N: 437, E: 65, P: 37},
		20: {ID: 20, N: 551, E: 31, P: 29},
	}

	studentI := 15
	studentJ := 35 - studentI

	paramsI, okI := allParams[studentI]
	paramsJ, okJ := allParams[studentJ]

	if !okI || !okJ {
		fmt.Println("Ошибка: не найдены параметры для студентов", studentI, "или", studentJ)
		return
	}

	// Выполнение Задания 1
	solveDiffieHellman(paramsI, studentI, studentJ)

	// Выполнение Задания 2
	solveRSA(paramsI, paramsJ)
}