package com.example.satellitetracker

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.concurrent.TimeUnit

/**
 * Загрузка TLE данных с Celestrak API.
 *
 * Пример URL:
 * https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=tle
 */
class TleNetworkFetcher {

    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    /**
     * Загружает список спутников с указанного URL.
     * Возвращает список TleData или пустой список при ошибке.
     */
    suspend fun fetchSatellites(url: String): Result<List<TleData>> {
        return withContext(Dispatchers.IO) {
            try {
                val request = Request.Builder()
                    .url(url)
                    .header("User-Agent", "SatelliteTracker/1.0 Android")
                    .build()

                val response = httpClient.newCall(request).execute()

                if (!response.isSuccessful) {
                    return@withContext Result.failure(
                        Exception("HTTP ошибка: ${response.code}")
                    )
                }

                val body = response.body?.string()
                    ?: return@withContext Result.failure(Exception("Пустой ответ сервера"))

                val satellites = TleRepository.parseTleString(body)
                Result.success(satellites)

            } catch (e: Exception) {
                e.printStackTrace()
                Result.failure(e)
            }
        }
    }

    /**
     * Загружает TLE для конкретного NORAD-номера спутника.
     * Пример: https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=tle
     */
    suspend fun fetchSatelliteByNoradId(noradId: Int): Result<TleData?> {
        val url = "https://celestrak.org/NORAD/elements/gp.php?CATNR=$noradId&FORMAT=tle"
        return withContext(Dispatchers.IO) {
            try {
                val request = Request.Builder().url(url).build()
                val response = httpClient.newCall(request).execute()

                if (!response.isSuccessful) {
                    return@withContext Result.failure(Exception("HTTP ${response.code}"))
                }

                val body = response.body?.string() ?: return@withContext Result.success(null)
                val satellites = TleRepository.parseTleString(body)
                Result.success(satellites.firstOrNull())

            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }
}
