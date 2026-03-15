package com.example.satellitetracker

import com.github.amsacode.predict4java.GroundStationPosition
import com.github.amsacode.predict4java.SatPos
import com.github.amsacode.predict4java.Satellite
import com.github.amsacode.predict4java.SatelliteFactory
import com.github.amsacode.predict4java.TLE
import java.util.Calendar
import java.util.TimeZone
import kotlin.math.PI

/**
 * Позиция спутника в заданный момент времени
 */
data class SatellitePosition(
    val latitude: Double,       // градусы
    val longitude: Double,      // градусы
    val altitudeKm: Double,     // высота над поверхностью, км
    val velocityKmH: Double,    // скорость, км/ч
    val azimuth: Double,        // азимут (направление), градусы
    val elevation: Double,      // угол места, градусы
    val timestamp: Long         // unix timestamp
)

/**
 * Класс для вычисления положения спутника на орбите.
 * Использует библиотеку Predict4Java (порт Predict для Java/Kotlin).
 *
 * Подключение в build.gradle:
 * implementation("com.github.davidmoten:predict4java:1.3.1")
 */
class SatelliteCalculator {

    // Наземная станция наблюдения (по умолчанию — центр Земли 0,0,0)
    private val defaultGroundStation = GroundStationPosition(
        /* latitude  = */ 0.0,
        /* longitude = */ 0.0,
        /* heightAMSL= */ 0.0
    )

    /**
     * Создаёт объект спутника из TLE данных
     */
    fun createSatellite(tleData: TleData): Satellite? {
        return try {
            val tleLines = arrayOf(tleData.name, tleData.line1, tleData.line2)
            val tle = TLE(tleLines)
            SatelliteFactory.createSatellite(tle)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    /**
     * Вычисляет текущее положение спутника
     */
    fun getCurrentPosition(satellite: Satellite): SatellitePosition? {
        return getPositionAtTime(satellite, Calendar.getInstance(TimeZone.getTimeZone("UTC")))
    }

    /**
     * Вычисляет положение спутника в заданное время
     */
    fun getPositionAtTime(satellite: Satellite, time: Calendar): SatellitePosition? {
        return try {
            val satPos: SatPos = satellite.getPosition(defaultGroundStation, time.time)

            // Конвертируем радианы в градусы
            val latDeg = Math.toDegrees(satPos.latitude)
            val lonDeg = Math.toDegrees(satPos.longitude)
            val altKm = satPos.altitude

            // Скорость в км/ч из км/с
            val velocityKmH = satPos.velocity * 3600.0

            val azimuthDeg = Math.toDegrees(satPos.azimuth)
            val elevationDeg = Math.toDegrees(satPos.elevation)

            SatellitePosition(
                latitude = latDeg,
                longitude = lonDeg,
                altitudeKm = altKm,
                velocityKmH = velocityKmH,
                azimuth = azimuthDeg,
                elevation = elevationDeg,
                timestamp = time.timeInMillis
            )
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    /**
     * Строит траекторию спутника за последние N часов
     * @param satellite  объект спутника
     * @param hours      количество часов (по умолчанию 24)
     * @param stepMinutes шаг в минутах
     * @return список позиций
     */
    fun buildTrajectory(
        satellite: Satellite,
        hours: Int = 24,
        stepMinutes: Int = 5
    ): List<SatellitePosition> {
        val positions = mutableListOf<SatellitePosition>()
        val now = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
        val totalSteps = (hours * 60) / stepMinutes

        // Начинаем от (hours) часов назад
        val startTime = now.clone() as Calendar
        startTime.add(Calendar.HOUR, -hours)

        for (i in 0..totalSteps) {
            val time = startTime.clone() as Calendar
            time.add(Calendar.MINUTE, i * stepMinutes)

            val pos = getPositionAtTime(satellite, time)
            if (pos != null) {
                positions.add(pos)
            }
        }

        return positions
    }

    /**
     * Строит прогнозную траекторию вперёд на N часов
     */
    fun buildFutureTrajectory(
        satellite: Satellite,
        hours: Int = 4,
        stepMinutes: Int = 3
    ): List<SatellitePosition> {
        val positions = mutableListOf<SatellitePosition>()
        val now = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
        val totalSteps = (hours * 60) / stepMinutes

        for (i in 0..totalSteps) {
            val time = now.clone() as Calendar
            time.add(Calendar.MINUTE, i * stepMinutes)

            val pos = getPositionAtTime(satellite, time)
            if (pos != null) {
                positions.add(pos)
            }
        }

        return positions
    }
}
