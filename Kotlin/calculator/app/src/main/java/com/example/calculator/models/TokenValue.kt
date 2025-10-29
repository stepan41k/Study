package com.example.calculator.models

class TokenValue(val value: Double) : TokenBase(TokenType.Value) {
    override fun toString(): String = "Value($value)"
}