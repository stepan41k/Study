package com.example.calculator.utils

import com.example.calculator.models.TokenBase
import com.example.calculator.models.TokenOperator
import com.example.calculator.models.TokenType
import com.example.calculator.models.TokenValue
import java.util.Stack

class Calculator {
    fun evaluate(tokens: Iterable<TokenBase>): Double {
        val stack = Stack<Double>()

        for (token in tokens) {
            when (token.tokenType) {
                TokenType.Value -> {
                    stack.push((token as TokenValue).value)
                }
                TokenType.Operator -> {
                    val op = (token as TokenOperator).op

                    if (stack.size < 2) {
                        throw IllegalArgumentException("Недостаточно операндов для операции $op")
                    }

                    val b = stack.pop()
                    val a = stack.pop()

                    val result = when (op) {
                        '+' -> a + b
                        '-' -> a - b
                        '*' -> a * b
                        '/' -> {
                            if (b == 0.0) {
                                throw ArithmeticException("Деление на ноль")
                            }
                            a / b
                        }
                        else -> throw IllegalArgumentException("Неизвестный оператор: $op")
                    }

                    stack.push(result)
                }
            }
        }

        if (stack.size != 1) {
            throw IllegalArgumentException("Неверное выражение: осталось ${stack.size} значений в стеке")
        }

        return stack.pop()
    }
}