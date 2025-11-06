package com.example.convertercurrency

import io.ktor.http.ContentType
import android.os.Bundle
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.convertercurrency.databinding.ActivityMainBinding
import com.example.convertercurrency.model.Currency
import com.example.convertercurrency.model.CurrencyResponse
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.serialization.kotlinx.json.json
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import android.util.Log

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private val httpClient = HttpClient(CIO) {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
            }, contentType = ContentType.Application.JavaScript)
        }
    }

    private var currencyData: Map<String, Currency> = emptyMap()
    private var selectedFromCurrency: Currency? = null
    private var selectedToCurrency: Currency? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        fetchCurrencyData()

        binding.btnConvert.setOnClickListener {
            convertCurrency()
        }
    }

    private fun fetchCurrencyData() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val response: CurrencyResponse = httpClient.get("https://www.cbr-xml-daily.ru/daily_json.js").body()
                currencyData = response.valute

                val ruble = Currency(
                    id = "R00000", numCode = "643", charCode = "RUB",
                    nominal = 1, name = "Российский рубль", value = 1.0, previous = 1.0
                )
                val mutableCurrencyData = currencyData.toMutableMap()
                mutableCurrencyData["RUB"] = ruble
                currencyData = mutableCurrencyData.toMap()

                withContext(Dispatchers.Main) {
                    val currencyNames = currencyData.map { "${it.value.name} (${it.key})" }.toMutableList()
                    currencyNames.sortBy { it }

                    val adapter = ArrayAdapter(
                        this@MainActivity,
                        android.R.layout.simple_spinner_item,
                        currencyNames
                    ).apply {
                        setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
                    }

                    binding.spinnerFromCurrency.adapter = adapter
                    binding.spinnerToCurrency.adapter = adapter

                    binding.spinnerFromCurrency.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                        override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                            val selectedNameWithCode = parent?.getItemAtPosition(position).toString()
                            val charCode = selectedNameWithCode.substringAfterLast('(').substringBeforeLast(')')
                            selectedFromCurrency = currencyData[charCode]
                        }
                        override fun onNothingSelected(parent: AdapterView<*>?) { selectedFromCurrency = null }
                    }

                    binding.spinnerToCurrency.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                        override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                            val selectedNameWithCode = parent?.getItemAtPosition(position).toString()
                            val charCode = selectedNameWithCode.substringAfterLast('(').substringBeforeLast(')')
                            selectedToCurrency = currencyData[charCode]
                            Log.d("CurrencyConverter", "Selected TO: ${selectedToCurrency?.name} (${selectedToCurrency?.charCode})")
                        }
                        override fun onNothingSelected(parent: AdapterView<*>?) { selectedToCurrency = null }
                    }

                    val usdPosition = currencyNames.indexOfFirst { it.contains("USD") }
                    val rubPosition = currencyNames.indexOfFirst { it.contains("RUB") }

                    if (usdPosition != -1) binding.spinnerFromCurrency.setSelection(usdPosition)
                    if (rubPosition != -1) binding.spinnerToCurrency.setSelection(rubPosition)

                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Toast.makeText(this@MainActivity, "Ошибка загрузки данных: ${e.message}", Toast.LENGTH_LONG).show()
                    Log.e("CurrencyConverter", "Error fetching currency data", e)
                    e.printStackTrace()
                }
            }
        }
    }

    private fun convertCurrency() {
        val amountString = binding.etAmount.text.toString()
        if (amountString.isEmpty()) {
            Toast.makeText(this, "Пожалуйста, введите сумму для конвертации.", Toast.LENGTH_SHORT).show()
            return
        }

        val inputAmount = amountString.toDoubleOrNull()
        if (inputAmount == null || inputAmount <= 0) {
            Toast.makeText(this, "Пожалуйста, введите корректную сумму.", Toast.LENGTH_SHORT).show()
            return
        }

        val fromCurrency = selectedFromCurrency
        val toCurrency = selectedToCurrency

        if (fromCurrency == null || toCurrency == null) {
            Toast.makeText(this, "Пожалуйста, выберите обе валюты.", Toast.LENGTH_SHORT).show()
            return
        }

        try {
            val amountInRubles = inputAmount * (fromCurrency.value / fromCurrency.nominal)

            val result = amountInRubles / (toCurrency.value / toCurrency.nominal)

            binding.tvResult.text = String.format("Результат: %.2f %s", result, toCurrency.charCode)
        } catch (e: Exception) {
            Toast.makeText(this, "Ошибка конвертации: ${e.message}", Toast.LENGTH_SHORT).show()
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        httpClient.close()
    }
}