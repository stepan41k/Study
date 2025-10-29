package com.example.convertercurrency.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.SerialName
import kotlinx.serialization.InternalSerializationApi
@OptIn(InternalSerializationApi::class)
@Serializable
data class CurrencyResponse(
    @SerialName("Date") val date: String,
    @SerialName("PreviousDate") val previousDate: String,
    @SerialName("PreviousURL") val previousURL: String,
    @SerialName("Timestamp") val timestamp: String,
    @SerialName("Valute") val valute: Map<String, Currency>
)
@OptIn(InternalSerializationApi::class)
@Serializable
data class Currency(
    @SerialName("ID") val id: String,
    @SerialName("NumCode") val numCode: String,
    @SerialName("CharCode") val charCode: String,
    @SerialName("Nominal") val nominal: Int,
    @SerialName("Name") val name: String,
    @SerialName("Value") val value: Double,
    @SerialName("Previous") val previous: Double
)