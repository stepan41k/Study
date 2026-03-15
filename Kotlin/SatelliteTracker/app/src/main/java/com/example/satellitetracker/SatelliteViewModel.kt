package com.example.satellitetracker

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.github.amsacode.predict4java.Satellite
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * ViewModel для управления состоянием трекинга спутника.
 * Следит за жизненным циклом Activity и останавливает обновления при уничтожении.
 */
class SatelliteViewModel : ViewModel() {

    private val calculator = SatelliteCalculator()
    private val networkFetcher = TleNetworkFetcher()

    // ---- LiveData ----

    private val _satellites = MutableLiveData<List<TleData>>(TleRepository.presetSatellites)
    val satellites: LiveData<List<TleData>> = _satellites

    private val _selectedSatellite = MutableLiveData<TleData?>(TleRepository.presetSatellites.first())
    val selectedSatellite: LiveData<TleData?> = _selectedSatellite

    private val _currentPosition = MutableLiveData<SatellitePosition?>()
    val currentPosition: LiveData<SatellitePosition?> = _currentPosition

    private val _trajectory = MutableLiveData<List<SatellitePosition>>(emptyList())
    val trajectory: LiveData<List<SatellitePosition>> = _trajectory

    private val _futureTrajectory = MutableLiveData<List<SatellitePosition>>(emptyList())
    val futureTrajectory: LiveData<List<SatellitePosition>> = _futureTrajectory

    private val _isTracking = MutableLiveData(false)
    val isTracking: LiveData<Boolean> = _isTracking

    private val _isLoading = MutableLiveData(false)
    val isLoading: LiveData<Boolean> = _isLoading

    private val _errorMessage = MutableLiveData<String?>()
    val errorMessage: LiveData<String?> = _errorMessage

    // ---- Tracking job ----
    private var trackingJob: Job? = null

    // Интервал обновления позиции спутника (5 секунд)
    private val UPDATE_INTERVAL_MS = 5_000L

    /**
     * Выбор спутника для отслеживания
     */
    fun selectSatellite(tleData: TleData) {
        _selectedSatellite.value = tleData
        // Если уже идёт трекинг — перезапускаем с новым спутником
        if (_isTracking.value == true) {
            stopTracking()
            startTracking()
        }
    }

    /**
     * Запуск автоматического обновления позиции
     */
    fun startTracking() {
        if (_isTracking.value == true) return

        val tleData = _selectedSatellite.value ?: run {
            _errorMessage.value = "Спутник не выбран"
            return
        }

        val satellite = calculator.createSatellite(tleData) ?: run {
            _errorMessage.value = "Ошибка парсинга TLE данных"
            return
        }

        _isTracking.value = true

        trackingJob = viewModelScope.launch {
            while (isActive) {
                val pos = calculator.getCurrentPosition(satellite)
                _currentPosition.postValue(pos)
                delay(UPDATE_INTERVAL_MS)
            }
        }
    }

    /**
     * Остановка отслеживания
     */
    fun stopTracking() {
        trackingJob?.cancel()
        trackingJob = null
        _isTracking.value = false
    }

    /**
     * Построение траектории за последние 24 часа + прогноз на 4 часа вперёд
     */
    fun computeTrajectory() {
        val tleData = _selectedSatellite.value ?: return
        val satellite = calculator.createSatellite(tleData) ?: return

        viewModelScope.launch {
            _isLoading.value = true
            try {
                // Прошедшая траектория (24ч, шаг 5 мин)
                val past = calculator.buildTrajectory(satellite, hours = 24, stepMinutes = 5)
                _trajectory.postValue(past)

                // Будущая траектория (4ч, шаг 3 мин)
                val future = calculator.buildFutureTrajectory(satellite, hours = 4, stepMinutes = 3)
                _futureTrajectory.postValue(future)

            } finally {
                _isLoading.value = false
            }
        }
    }

    /**
     * Загрузка актуальных TLE с Celestrak
     */
    fun fetchTleFromNetwork() {
        viewModelScope.launch {
            _isLoading.value = true
            val result = networkFetcher.fetchSatellites(TleRepository.CELESTRAK_STATIONS_URL)
            result.fold(
                onSuccess = { list ->
                    if (list.isNotEmpty()) {
                        _satellites.postValue(list)
                        _selectedSatellite.postValue(list.first())
                    } else {
                        _errorMessage.postValue("Не удалось получить TLE данные")
                    }
                },
                onFailure = { e ->
                    _errorMessage.postValue("Ошибка сети: ${e.message}")
                }
            )
            _isLoading.value = false
        }
    }

    /**
     * Сброс ошибки после показа
     */
    fun clearError() {
        _errorMessage.value = null
    }

    override fun onCleared() {
        super.onCleared()
        stopTracking()
    }
}
