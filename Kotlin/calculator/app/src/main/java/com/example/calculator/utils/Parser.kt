package com.example.calculator.utils

import com.example.calculator.models.TokenBase
import com.example.calculator.models.TokenOperator
import com.example.calculator.models.TokenValue

class Parser {
    fun parse(expression: String): Sequence<TokenBase> = sequence {
        var i = 0

        while (i < expression.length) {
            val ch = expression[i]

            if (ch.isWhitespace()) {
                i++
                continue
            }

            if (ch.isDigit() || ch == '.') {
                val start = i
                while (i < expression.length && (expression[i].isDigit() || expression[i] == '.')) {
                    i++
                }
                val numberStr = expression.substring(start, i)
                val number = numberStr.toDoubleOrNull()
                    ?: throw IllegalArgumentException("Неверный формат числа: $numberStr")
                yield(TokenValue(number))
                continue
            }

            if (ch in setOf('+', '-', '*', '/', '(', ')')) {
                yield(TokenOperator(ch))
                i++
                continue
            }

            throw IllegalArgumentException("Неизвестный символ: $ch")
        }
    }
}