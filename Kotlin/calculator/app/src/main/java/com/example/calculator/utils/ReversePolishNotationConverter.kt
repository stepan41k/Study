package com.example.calculator.utils

import com.example.calculator.models.TokenBase
import com.example.calculator.models.TokenOperator
import com.example.calculator.models.TokenType
import com.example.calculator.models.TokenValue
import java.util.Stack

class ReversePolishNotationConverter {
    private fun getPriority(op: Char): Int = when (op) {
        '+', '-' -> 1
        '*', '/' -> 2
        else -> 0
    }

    fun convert(tokens: Sequence<TokenBase>): Sequence<TokenBase> = sequence {
        val operatorStack = Stack<Char>()

        for (token in tokens) {
            when (token.tokenType) {
                TokenType.Value -> {
                    yield(token)
                }
                TokenType.Operator -> {
                    val op = (token as TokenOperator).op

                    when (op) {
                        '(' -> {
                            operatorStack.push(op)
                        }
                        ')' -> {
                            while (operatorStack.isNotEmpty() && operatorStack.peek() != '(') {
                                yield(TokenOperator(operatorStack.pop()))
                            }

                            if (operatorStack.isEmpty()) {
                                throw IllegalArgumentException("Несогласованные скобки: лишняя закрывающая скобка")
                            }

                            operatorStack.pop()
                        }
                        else -> {
                            val currentPriority = getPriority(op)

                            while (operatorStack.isNotEmpty() &&
                                operatorStack.peek() != '(' &&
                                getPriority(operatorStack.peek()) >= currentPriority) {
                                yield(TokenOperator(operatorStack.pop()))
                            }

                            operatorStack.push(op)
                        }
                    }
                }
            }
        }


        while (operatorStack.isNotEmpty()) {
            val op = operatorStack.pop()
            if (op == '(') {
                throw IllegalArgumentException("Несогласованные скобки: лишняя открывающая скобка")
            }
            yield(TokenOperator(op))
        }
    }
}