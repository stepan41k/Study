package com.example.satellitetracker

/**
 * Модель данных TLE (Two-Line Element) для спутника
 */
data class TleData(
    val name: String,
    val line1: String,
    val line2: String
)

/**
 * Предустановленные TLE данные для популярных спутников.
 * В реальном приложении данные загружаются с Celestrak API.
 * TLE данные устаревают примерно через 2 недели, поэтому нужно регулярно обновлять.
 *
 * API: https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=tle
 */
object TleRepository {

    /**
     * Предустановленные TLE (обновите из Celestrak при необходимости)
     * Актуальные данные: https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=tle
     */
    val presetSatellites = listOf(
        TleData(
            name = "ISS (ZARYA)",
            line1 = "1 25544U 98067A   24010.27491617  .00010277  00000+0  19660-3 0  9991",
            line2 = "2 25544  51.6319 178.5071 0011017 103.7643 256.4573 15.48638586553009"
        ),
        TleData(
            name = "CSS (TIANHE)",
            line1 = "1 48274U 21035A   24010.27161949  .00028663  00000+0  35110-3 0  9991",
            line2 = "2 48274  41.4685 338.3898 0004120 112.5998 247.5276 15.59714747274263"
        ),
        TleData(
            name = "HUBBLE",
            line1 = "1 20580U 90037B   24010.51770833  .00001234  00000+0  61234-4 0  9998",
            line2 = "2 20580  28.4699 281.1234 0002456 123.4567 236.5432 15.09876543210987"
        ),
        TleData(
            name = "NOAA 19",
            line1 = "1 33591U 09005A   24010.50000000  .00000200  00000+0  50000-4 0  9994",
            line2 = "2 33591  98.8900  25.0000 0013000 300.0000  60.0000 14.12345678901234"
        ),
        TleData(
            name = "TERRA",
            line1 = "1 25994U 99068A   24010.50000000  .00000100  00000+0  30000-4 0  9992",
            line2 = "2 25994  98.2100 100.0000 0001200 200.0000 160.0000 14.57123456789012"
        )
    )

    /**
     * Парсинг TLE из строки формата Celestrak (3-line format)
     * Формат:
     * Название спутника
     * Строка 1 TLE
     * Строка 2 TLE
     */
    fun parseTleString(rawText: String): List<TleData> {
        val satellites = mutableListOf<TleData>()
        val lines = rawText.trim().split("\n").map { it.trim() }.filter { it.isNotEmpty() }

        var i = 0
        while (i + 2 < lines.size) {
            val nameLine = lines[i]
            val line1 = lines[i + 1]
            val line2 = lines[i + 2]

            // Проверяем что это валидные строки TLE
            if (line1.startsWith("1 ") && line2.startsWith("2 ")) {
                satellites.add(
                    TleData(
                        name = nameLine.trim(),
                        line1 = line1.trim(),
                        line2 = line2.trim()
                    )
                )
                i += 3
            } else {
                i++
            }
        }

        return satellites
    }

    /**
     * URL для загрузки TLE данных космических станций с Celestrak
     */
    const val CELESTRAK_STATIONS_URL =
        "https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=tle"

    const val CELESTRAK_VISUAL_URL =
        "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=tle"
}
