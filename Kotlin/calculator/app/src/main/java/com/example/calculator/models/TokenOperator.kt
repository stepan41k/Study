package com.example.calculator.models

class TokenOperator(val op: Char) : TokenBase(TokenType.Operator) {
    override fun toString(): String = "Operator($op)"
}