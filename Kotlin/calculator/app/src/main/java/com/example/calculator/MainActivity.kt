package com.example.calculator

import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.example.calculator.models.TokenOperator
import com.example.calculator.models.TokenType
import com.example.calculator.models.TokenValue
import com.example.calculator.utils.Calculator
import com.example.calculator.utils.Parser
import com.example.calculator.utils.ReversePolishNotationConverter

class MainActivity : AppCompatActivity() {
    private lateinit var expressionInput: EditText
    private lateinit var rpnText: TextView
    private lateinit var resultText: TextView
    private lateinit var calculateButton: Button

    private val parser = Parser()
    private val converter = ReversePolishNotationConverter()
    private val calculator = Calculator()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        expressionInput = findViewById(R.id.expressionInput)
        rpnText = findViewById(R.id.rpnText)
        resultText = findViewById(R.id.resultText)
        calculateButton = findViewById(R.id.calculateButton)

        calculateButton.setOnClickListener {
            calculateExpression()
        }

        runTests()
    }

    private fun calculateExpression() {
        try {
            val expression = expressionInput.text.toString()

            val tokens = parser.parse(expression)

            val rpnTokens = converter.convert(tokens)

            val rpnList = rpnTokens.toList()

            val rpnString = rpnList.joinToString(" ") { token ->
                when (token.tokenType) {
                    TokenType.Value -> (token as TokenValue).value.toString()
                    TokenType.Operator -> (token as TokenOperator).op.toString()
                }
            }

            val result = calculator.evaluate(rpnList)

            rpnText.text = "ОПН: $rpnString"
            resultText.text = "Результат: $result"
        } catch (e: Exception) {
            rpnText.text = ""
            resultText.text = "Ошибка: ${e.message}"
        }
    }

    private fun runTests() {
        val testCases = listOf(
            "(5+5)*25/12" to 20.833333333333332,
            "7+3*2" to 13.0,
            "(8-3)*(2+1)" to 15.0,
            "10/2+3" to 8.0,
            "2+2*2" to 6.0,
            "((2+3)*4)/2" to 10.0
        )

        println("=== Запуск тестов ===")
        testCases.forEach { (expr, expected) ->
            try {
                val tokens = parser.parse(expr)
                val rpnTokens = converter.convert(tokens)
                val rpnList = rpnTokens.toList()

                // Выводим ОПН
                val rpnString = rpnList.joinToString(" ") { token ->
                    when (token.tokenType) {
                        TokenType.Value -> (token as TokenValue).value.toString()
                        TokenType.Operator -> (token as TokenOperator).op.toString()
                    }
                }

                val result = calculator.evaluate(rpnList)
                val status = if (kotlin.math.abs(result - expected) < 0.0001) "✓" else "✗"
                println("$status $expr => ОПН: $rpnString = $result")
            } catch (e: Exception) {
                println("✗ $expr: ${e.message}")
            }
        }

        println("\n=== Тесты на ошибки ===")
        val errorCases = listOf(
            "(5+5" to "Несогласованные скобки",
            "5+5)" to "Несогласованные скобки",
            "10/0" to "Деление на ноль",
            "5 & 3" to "Неизвестный символ"
        )

        errorCases.forEach { (expr, expectedError) ->
            try {
                val tokens = parser.parse(expr)
                val rpnTokens = converter.convert(tokens)
                calculator.evaluate(rpnTokens.toList())
                println("✗ $expr: ошибка не обнаружена")
            } catch (e: Exception) {
                println("✓ $expr: ${e.message}")
            }
        }
    }
}