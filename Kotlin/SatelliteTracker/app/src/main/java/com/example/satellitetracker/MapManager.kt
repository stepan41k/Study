package com.example.satellitetracker

import android.content.Context
import android.graphics.Color
import com.yandex.mapkit.MapKitFactory
import com.yandex.mapkit.geometry.LinearRing
import com.yandex.mapkit.geometry.Point
import com.yandex.mapkit.geometry.Polyline
import com.yandex.mapkit.map.CameraPosition
import com.yandex.mapkit.map.IconStyle
import com.yandex.mapkit.map.Map
import com.yandex.mapkit.map.MapObjectCollection
import com.yandex.mapkit.map.PlacemarkMapObject
import com.yandex.mapkit.map.PolylineMapObject
import com.yandex.mapkit.mapview.MapView
import com.yandex.runtime.image.ImageProvider

/**
 * Менеджер для работы с картой Yandex MapKit.
 *
 * Документация: https://yandex.ru/maps-api/docs/mapkit/android/generated/getting_started.html
 * Примеры: https://github.com/yandex/mapkit-android-demo
 */
class MapManager(private val context: Context, private val mapView: MapView) {

    private val map: Map get() = mapView.mapWindow.map
    private val mapObjects: MapObjectCollection get() = map.mapObjects

    // Маркер текущей позиции спутника
    private var satellitePlacemark: PlacemarkMapObject? = null

    // Полилинии траектории
    private var pastPolyline: PolylineMapObject? = null
    private var futurePolyline: PolylineMapObject? = null

    // Маркеры временных точек на траектории
    private val waypointPlacemarks = mutableListOf<PlacemarkMapObject>()

    /**
     * Инициализация карты: настройка вида и слоёв
     */
    fun setupMap() {
        // Ночная тема / спутниковый вид
        map.isNightModeEnabled = true

        // Начальный zoom и центр (вид на всю Землю)
        map.move(
            CameraPosition(
                Point(0.0, 0.0),
                /* zoom     = */ 2f,
                /* azimuth  = */ 0f,
                /* tilt     = */ 0f
            )
        )
    }

    /**
     * Обновление позиции спутника на карте.
     * Если маркер ещё не создан — создаём, иначе перемещаем.
     */
    fun updateSatellitePosition(position: SatellitePosition, satelliteName: String) {
        val point = Point(position.latitude, position.longitude)

        if (satellitePlacemark == null) {
            // Создаём маркер спутника
            satellitePlacemark = mapObjects.addPlacemark().apply {
                geometry = point
                setIcon(
                    ImageProvider.fromResource(context, R.drawable.ic_satellite),
                    IconStyle().apply {
                        scale = 2.5f
                        zIndex = 100f
                    }
                )
                // Текстовая метка с названием и высотой
                setText("$satelliteName\n${position.altitudeKm.toInt()} км")
            }
        } else {
            // Перемещаем существующий маркер
            satellitePlacemark?.geometry = point
            satellitePlacemark?.setText("$satelliteName\n${position.altitudeKm.toInt()} км")
        }
    }

    /**
     * Центрирование камеры на текущей позиции спутника
     */
    fun centerOnSatellite(position: SatellitePosition, animated: Boolean = true) {
        val cameraPosition = CameraPosition(
            Point(position.latitude, position.longitude),
            /* zoom     = */ 4f,
            /* azimuth  = */ 0f,
            /* tilt     = */ 0f
        )

        if (animated) {
            map.move(
                cameraPosition,
                com.yandex.mapkit.Animation(
                    com.yandex.mapkit.Animation.Type.SMOOTH,
                    1.5f
                ),
                null
            )
        } else {
            map.move(cameraPosition)
        }
    }

    /**
     * Отрисовка прошедшей траектории (синяя линия) и будущей (зелёная пунктирная)
     */
    fun drawTrajectory(
        pastPositions: List<SatellitePosition>,
        futurePositions: List<SatellitePosition>
    ) {
        // Очищаем старые траектории
        clearTrajectory()

        // --- Прошедшая траектория (синяя) ---
        if (pastPositions.size >= 2) {
            val pastPoints = splitByDateline(pastPositions.map { Point(it.latitude, it.longitude) })
            pastPoints.forEach { segment ->
                if (segment.size >= 2) {
                    mapObjects.addPolyline(Polyline(segment)).apply {
                        strokeColor = Color.argb(200, 0, 150, 255)
                        strokeWidth = 2f
                        zIndex = 10f
                    }.also {
                        // Сохраняем только первый сегмент как ссылку
                        if (pastPolyline == null) pastPolyline = it
                    }
                }
            }
        }

        // --- Будущая траектория (зелёная) ---
        if (futurePositions.size >= 2) {
            val futurePoints = splitByDateline(futurePositions.map { Point(it.latitude, it.longitude) })
            futurePoints.forEach { segment ->
                if (segment.size >= 2) {
                    mapObjects.addPolyline(Polyline(segment)).apply {
                        strokeColor = Color.argb(200, 100, 255, 100)
                        strokeWidth = 2f
                        dashLength = 10f
                        gapLength = 5f
                        zIndex = 10f
                    }
                }
            }
        }

        // Добавляем временные метки каждые 2 часа на будущей траектории
        addTimeWaypoints(futurePositions)
    }

    /**
     * Добавление меток с временем на траектории (каждые ~40 точек при шаге 3 мин = 2 часа)
     */
    private fun addTimeWaypoints(positions: List<SatellitePosition>) {
        val step = 40 // каждые ~2 часа при шаге 3 мин
        positions.forEachIndexed { index, pos ->
            if (index > 0 && index % step == 0) {
                val time = java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault())
                    .format(java.util.Date(pos.timestamp))

                val placemark = mapObjects.addPlacemark().apply {
                    geometry = Point(pos.latitude, pos.longitude)
                    setIcon(
                        ImageProvider.fromResource(context, R.drawable.ic_waypoint),
                        IconStyle().apply { scale = 1.2f; zIndex = 20f }
                    )
                    setText(time)
                }
                waypointPlacemarks.add(placemark)
            }
        }
    }

    /**
     * Разбивает список точек на сегменты, если пересекается линия перемены дат.
     * Это нужно, чтобы траектория не рисовалась через весь экран.
     */
    private fun splitByDateline(points: List<Point>): List<List<Point>> {
        if (points.isEmpty()) return emptyList()

        val segments = mutableListOf<MutableList<Point>>()
        var current = mutableListOf(points[0])

        for (i in 1 until points.size) {
            val prev = points[i - 1]
            val curr = points[i]

            // Если разница по долготе > 180° — это пересечение линии дат
            if (Math.abs(curr.longitude - prev.longitude) > 180.0) {
                segments.add(current)
                current = mutableListOf(curr)
            } else {
                current.add(curr)
            }
        }
        segments.add(current)

        return segments
    }

    /**
     * Очистка траекторий и меток с карты
     */
    fun clearTrajectory() {
        pastPolyline = null
        futurePolyline = null
        waypointPlacemarks.forEach { mapObjects.remove(it) }
        waypointPlacemarks.clear()
        // Удаляем все полилинии кроме маркера спутника
        mapObjects.clear()
        satellitePlacemark = null
    }

    /**
     * Сброс карты до начального вида
     */
    fun resetCamera() {
        map.move(
            CameraPosition(Point(0.0, 0.0), 2f, 0f, 0f),
            com.yandex.mapkit.Animation(com.yandex.mapkit.Animation.Type.SMOOTH, 1.0f),
            null
        )
    }
}
