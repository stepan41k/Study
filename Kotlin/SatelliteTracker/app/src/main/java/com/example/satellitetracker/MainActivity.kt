package com.example.satellitetracker

import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.TextView
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.Observer
import com.example.satellitetracker.databinding.ActivityMainBinding
import com.google.android.material.snackbar.Snackbar
import com.yandex.mapkit.MapKitFactory
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Главная Activity приложения.
 *
 * Архитектура: MVVM (ViewModel + LiveData)
 *
 * Функциональность:
 * - Отображение спутника на карте Yandex MapKit
 * - Автообновление позиции каждые 5 секунд (Predict4Java)
 * - Построение и отображение траектории за 24ч + прогноз 4ч
 * - Загрузка актуальных TLE с Celestrak API
 * - Выбор спутника из списка
 *
 * ВАЖНО: Вставьте ваш Yandex MapKit API ключ в AndroidManifest.xml
 * и в метод initMapKit() ниже.
 */
class MainActivity : AppCompatActivity() {

    // ViewBinding — генерируется автоматически из activity_main.xml
    private lateinit var binding: ActivityMainBinding

    // ViewModel управляет логикой и данными
    private val viewModel: SatelliteViewModel by viewModels()

    // Менеджер карты
    private lateinit var mapManager: MapManager

    // Форматтер времени
    private val timeFormatter = SimpleDateFormat("HH:mm:ss", Locale.getDefault())

    override fun onCreate(savedInstanceState: Bundle?) {
        // Инициализация MapKit ДОЛЖНА быть ДО super.onCreate() и setContentView()
        initMapKit()

        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Инициализация менеджера карты
        mapManager = MapManager(this, binding.mapView)
        mapManager.setupMap()

        // Настройка спиннера выбора спутника
        setupSatelliteSpinner()

        // Подписка на LiveData из ViewModel
        observeViewModel()

        // Настройка кнопок
        setupButtons()

        // Запускаем загрузку TLE с сети при старте
        viewModel.fetchTleFromNetwork()
    }

    /**
     * Инициализация Yandex MapKit.
     * API ключ получить на: https://developer.tech.yandex.ru/
     */
    private fun initMapKit() {
        // Замените на ваш реальный ключ!
        MapKitFactory.setApiKey("YOUR_YANDEX_MAPKIT_API_KEY")
        MapKitFactory.initialize(this)
    }

    /**
     * Настройка выпадающего списка спутников
     */
    private fun setupSatelliteSpinner() {
        viewModel.satellites.observe(this) { satellites ->
            val names = satellites.map { it.name }
            val adapter = ArrayAdapter(
                this,
                android.R.layout.simple_spinner_item,
                names
            ).apply {
                setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
            }
            binding.satelliteSpinner.adapter = adapter

            // Восстанавливаем выбранный индекс
            val selectedName = viewModel.selectedSatellite.value?.name
            val idx = names.indexOfFirst { it == selectedName }
            if (idx >= 0) binding.satelliteSpinner.setSelection(idx)
        }

        binding.satelliteSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>, view: View?, pos: Int, id: Long) {
                val satellites = viewModel.satellites.value ?: return
                if (pos < satellites.size) {
                    viewModel.selectSatellite(satellites[pos])
                }
            }
            override fun onNothingSelected(parent: AdapterView<*>) {}
        }
    }

    /**
     * Подписка на данные ViewModel
     */
    private fun observeViewModel() {

        // Обновление позиции спутника на карте
        viewModel.currentPosition.observe(this) { pos ->
            pos ?: return@observe
            val satName = viewModel.selectedSatellite.value?.name ?: "Спутник"

            // Обновляем маркер на карте
            mapManager.updateSatellitePosition(pos, satName)

            // Обновляем текстовые поля
            binding.tvLatitude.text  = "Широта: %.4f°".format(pos.latitude)
            binding.tvLongitude.text = "Долгота: %.4f°".format(pos.longitude)
            binding.tvAltitude.text  = "Высота: ${pos.altitudeKm.toInt()} км"
            binding.tvVelocity.text  = "Скорость: ${pos.velocityKmH.toInt()} км/ч"
            binding.tvUpdateTime.text = "Обновлено: ${timeFormatter.format(Date())}"
        }

        // Отображение траектории
        viewModel.trajectory.observe(this) { pastPositions ->
            val futurePositions = viewModel.futureTrajectory.value ?: emptyList()
            if (pastPositions.isNotEmpty()) {
                mapManager.drawTrajectory(pastPositions, futurePositions)
                // Возвращаем маркер спутника поверх траектории
                viewModel.currentPosition.value?.let { pos ->
                    mapManager.updateSatellitePosition(
                        pos,
                        viewModel.selectedSatellite.value?.name ?: "Спутник"
                    )
                }
            }
        }

        // Состояние кнопки трекинга
        viewModel.isTracking.observe(this) { isTracking ->
            binding.btnTrack.text = if (isTracking) "⏹ Остановить" else "▶ Отслеживать"
            binding.btnTrack.backgroundTintList = android.content.res.ColorStateList.valueOf(
                if (isTracking) Color.parseColor("#8B0000") else Color.parseColor("#0F3460")
            )
        }

        // Индикатор загрузки
        viewModel.isLoading.observe(this) { loading ->
            binding.loadingOverlay.visibility = if (loading) View.VISIBLE else View.GONE
        }

        // Ошибки
        viewModel.errorMessage.observe(this) { message ->
            message ?: return@observe
            Snackbar.make(binding.root, message, Snackbar.LENGTH_LONG)
                .setBackgroundTint(Color.parseColor("#8B0000"))
                .setTextColor(Color.WHITE)
                .show()
            viewModel.clearError()
        }
    }

    /**
     * Настройка обработчиков кнопок
     */
    private fun setupButtons() {

        // Кнопка "Отслеживать / Остановить"
        binding.btnTrack.setOnClickListener {
            if (viewModel.isTracking.value == true) {
                viewModel.stopTracking()
            } else {
                viewModel.startTracking()
            }
        }

        // Кнопка "Траектория"
        binding.btnShowTrajectory.setOnClickListener {
            viewModel.computeTrajectory()
        }

        // Кнопка "Центрировать"
        binding.btnCenterMap.setOnClickListener {
            val pos = viewModel.currentPosition.value
            if (pos != null) {
                mapManager.centerOnSatellite(pos)
            } else {
                mapManager.resetCamera()
            }
        }
    }

    // ---- Жизненный цикл MapKit ----

    override fun onStart() {
        super.onStart()
        MapKitFactory.getInstance().onStart()
        binding.mapView.onStart()
    }

    override fun onStop() {
        binding.mapView.onStop()
        MapKitFactory.getInstance().onStop()
        super.onStop()
    }
}
