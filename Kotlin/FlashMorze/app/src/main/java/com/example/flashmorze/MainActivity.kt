package com.example.flashmorze

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Bundle
import android.speech.RecognizerIntent
import android.util.Log
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.*

class MainActivity : AppCompatActivity() {

    private lateinit var cameraManager: CameraManager
    private lateinit var speechLauncher: ActivityResultLauncher<Intent>
    private var cameraId: String? = null
    private var morseJob: Job? = null

    // UI элементы
    // private lateinit var tvStatus: TextView -> УДАЛЕНО
    private lateinit var tvResult: TextView
    private lateinit var btnStop: Button

    private val TAG = "FlashMorzeLog"

    private val requestPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted ->
            if (isGranted) startSpeechRecognition()
            else Toast.makeText(
                this,
                "Разрешение на микрофон необходимо для распознавания речи",
                Toast.LENGTH_SHORT
            ).show()
        }

    // (Карту Морзе оставляем без изменений, сократил для удобства чтения)
    private val morseCodeMapRu = mapOf(
        'А' to ".-", 'Б' to "-...", 'В' to ".--", 'Г' to "--.", 'Д' to "-..",
        'Е' to ".", 'Ё' to ".", 'Ж' to "...-", 'З' to "--..", 'И' to "..",
        'Й' to ".---", 'К' to "-.-", 'Л' to ".-..", 'М' to "--", 'Н' to "-.",
        'О' to "---", 'П' to ".--.", 'Р' to ".-.", 'С' to "...", 'Т' to "-",
        'У' to "..-", 'Ф' to "..-.", 'Х' to "....", 'Ц' to "-.-.", 'Ч' to "---.",
        'Ш' to "----", 'Щ' to "--.-", 'Ъ' to "--.--", 'Ы' to "-.--", 'Ь' to "-..-",
        'Э' to "..-..", 'Ю' to "..--", 'Я' to ".-.-", ' ' to " ", 'A' to ".-",'B' to "-...",
        'C' to "-.-.", 'D' to "-..", 'E' to "." , 'F' to "..-.", 'G' to "--.", 'H' to "....", 'I' to "..",
        'J' to ".---", 'K' to "-.-", 'L' to ".-..", 'M' to "--", 'N' to "-.", 'O' to "---",
        'P' to ".--.", 'Q' to "--.-", 'R' to ".-.", 'S' to "...", 'T' to "-", 'U' to "..-",
        'V' to "...-", 'W' to ".--", 'X' to "-..-", 'Y' to "-.--", 'Z' to "--.."
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Инициализация UI (tvStatus удален)
        tvResult = findViewById(R.id.tvResult)
        btnStop = findViewById(R.id.btnStop)

        initCamera()
        initSpeechRecognizer()

        findViewById<Button>(R.id.btnSpeak).setOnClickListener { startSpeechRecognition() }
        btnStop.setOnClickListener { stopMorse() }
    }

    private fun initCamera() {
        cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        cameraId = cameraManager.cameraIdList.firstOrNull { id ->
            cameraManager.getCameraCharacteristics(id)
                .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        }
        if (cameraId == null) {
            Log.e(TAG, "Камера с вспышкой не найдена!")
        }
    }

    private fun initSpeechRecognizer() {
        speechLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            val matches = result.data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
            val spokenText = matches?.firstOrNull()?.uppercase().orEmpty()

            if (spokenText.isNotEmpty()) {
                tvResult.text = spokenText
                convertAndFlashMorse(spokenText)
            } else {
                tvResult.text = "Не распознано" // Выводим инфо в основное поле
            }
        }
    }

    private fun startSpeechRecognition() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
            return
        }

        // tvStatus.text = "Слушаю..." -> УДАЛЕНО

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ru-RU")
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Говорите фразу для Морзе...")
        }
        try {
            speechLauncher.launch(intent)
        } catch (e: Exception) {
            Toast.makeText(this, "Ошибка запуска распознавания речи", Toast.LENGTH_SHORT).show()
        }
    }

    private fun convertAndFlashMorse(text: String) {
        if (cameraId == null) {
            Toast.makeText(this, "Фонарик недоступен", Toast.LENGTH_SHORT).show()
            return
        }

        stopMorse()
        btnStop.isEnabled = true
        btnStop.alpha = 1.0f
        // tvStatus.text = "Транслирую Морзе..." -> УДАЛЕНО

        morseJob = lifecycleScope.launch {
            Log.i(TAG, "Начало трансляции: $text")

            for (char in text) {
                if (!isActive) break
                val morse = morseCodeMapRu[char]
                if (morse != null) {
                    Log.d(TAG, "Символ: $char -> Код: $morse")
                    if (morse == " ") {
                        delay(700)
                    } else {
                        flashMorseSymbol(morse)
                        delay(300)
                    }
                }
            }
            stopMorseUI()
            // tvStatus.text = "Передача завершена" -> УДАЛЕНО
            Log.i(TAG, "Конец трансляции")
        }
    }

    private suspend fun flashMorseSymbol(morse: String) {
        for (i in morse.indices) {
            val duration = if (morse[i] == '.') 200L else 600L
            try {
                cameraManager.setTorchMode(cameraId!!, true)
                Log.d(TAG, "Torch ON ($duration ms)")
                delay(duration)

                cameraManager.setTorchMode(cameraId!!, false)
                Log.d(TAG, "Torch OFF")

            } catch (e: CameraAccessException) {
                Log.e(TAG, "Ошибка доступа к камере: ${e.message}")
                withContext(Dispatchers.Main) {
                    Toast.makeText(this@MainActivity, "Ошибка фонарика", Toast.LENGTH_SHORT).show()
                }
                break
            }

            if (i < morse.lastIndex) delay(200)
        }
    }

    private fun stopMorse() {
        morseJob?.cancel()
        morseJob = null
        try {
            cameraId?.let {
                cameraManager.setTorchMode(it, false)
                Log.d(TAG, "Torch OFF (Forced Stop)")
            }
        } catch (e: CameraAccessException) {
            e.printStackTrace()
        }
        stopMorseUI()
    }

    private fun stopMorseUI() {
        btnStop.isEnabled = false
        btnStop.alpha = 0.5f
        // Логика обновления статуса удалена
    }

    override fun onPause() {
        super.onPause()
        stopMorse()
    }
}