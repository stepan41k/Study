package com.example.morseapp

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.camera2.CameraManager
import android.os.Bundle
import android.speech.RecognizerIntent
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.isVisible
import kotlinx.coroutines.*
import java.util.*

class MainActivity : AppCompatActivity() {

    private lateinit var cameraManager: CameraManager
    private var cameraId: String? = null
    private var morsePlaybackJob: Job? = null

    private lateinit var startButton: Button
    private lateinit var stopButton: Button
    private lateinit var recognizedTextView: TextView

    private val morseCodeMap = mapOf(
        'А' to ".-", 'Б' to "-...", 'В' to ".--", 'Г' to "--.", 'Д' to "-..", 'Е' to ".",
        'Ж' to "...-", 'З' to "--..", 'И' to "..", 'Й' to ".---", 'К' to "-.-", 'Л' to ".-..",
        'М' to "--", 'Н' to "-.", 'О' to "---", 'П' to ".--.", 'Р' to ".-.", 'С' to "...",
        'Т' to "-", 'У' to "..-", 'Ф' to "..-.", 'Х' to "....", 'Ц' to "-.-.", 'Ч' to "---.",
        'Ш' to "----", 'Щ' to "--.-", 'Ъ' to ".--.-.", 'Ы' to "-.--", 'Ь' to "-..-",
        'Э' to "..-..", 'Ю' to "..--", 'Я' to ".-.-", '0' to "-----", '1' to ".----",
        '2' to "..---", '3' to "...--", '4' to "....-", '5' to ".....", '6' to "-....",
        '7' to "--...", '8' to "---..", '9' to "----."
    )

    private val dotDuration = 200L
    private val dashDuration = dotDuration * 3
    private val pauseBetweenElements = dotDuration
    private val pauseBetweenLetters = dotDuration * 3
    private val pauseBetweenWords = dotDuration * 7

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        startButton = findViewById(R.id.startButton)
        stopButton = findViewById(R.id.stopButton)
        recognizedTextView = findViewById(R.id.recognizedTextView)

        setupCamera()

        startButton.setOnClickListener {
            requestAudioPermission()
        }

        stopButton.setOnClickListener {
            stopMorsePlayback()
        }
    }

    private fun setupCamera() {
        cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        try {
            cameraId = cameraManager.cameraIdList.firstOrNull { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
            if (cameraId == null) {
                startButton.isEnabled = false
                Toast.makeText(this, "Фонарик не найден на этом устройстве", Toast.LENGTH_SHORT).show()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            Toast.makeText(this, "Ошибка доступа к камере", Toast.LENGTH_SHORT).show()
        }
    }

    private val speechLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK && result.data != null) {
            val matches = result.data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
            val spokenText = matches?.firstOrNull() ?: ""

            if (spokenText.isNotBlank()) {
                recognizedTextView.text = "Распознано: $spokenText"
                playMorseCode(spokenText)
            } else {
                recognizedTextView.text = "Не удалось распознать речь"
            }
        }
    }

    private fun startSpeechRecognition() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ru-RU")
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Говорите текст для преобразования в морзянку")
        }
        try {
            speechLauncher.launch(intent)
        } catch (e: Exception) {
            Toast.makeText(this, "Распознавание речи не поддерживается", Toast.LENGTH_SHORT).show()
        }
    }


    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            startSpeechRecognition()
        } else {
            Toast.makeText(this, "Разрешение на использование микрофона необходимо", Toast.LENGTH_SHORT).show()
        }
    }

    private fun requestAudioPermission() {
        when {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO
            ) == PackageManager.PERMISSION_GRANTED -> {
                startSpeechRecognition()
            }
            else -> {
                permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
            }
        }
    }

    private fun playMorseCode(text: String) {
        morsePlaybackJob?.cancel()

        morsePlaybackJob = CoroutineScope(Dispatchers.Main).launch {
            updateUi(isPlaying = true)
            try {
                val morseString = textToMorse(text.uppercase(Locale.getDefault()))

                for (char in morseString) {
                    ensureActive()
                    when (char) {
                        '.' -> flashLight(dotDuration)
                        '-' -> flashLight(dashDuration)
                        ' ' -> delay(pauseBetweenLetters - pauseBetweenElements)
                        '/' -> delay(pauseBetweenWords - pauseBetweenLetters)
                    }
                    delay(pauseBetweenElements)
                }
            } catch (e: CancellationException) {
                recognizedTextView.text = "Воспроизведение остановлено"
            } finally {
                turnOffFlashlight()
                updateUi(isPlaying = false)
            }
        }
    }

    private fun textToMorse(text: String): String {
        val builder = StringBuilder()
        for (char in text) {
            when {
                morseCodeMap.containsKey(char) -> {
                    builder.append(morseCodeMap[char]).append(" ")
                }
                char == ' ' -> {
                    builder.append("/ ")
                }
            }
        }
        return builder.toString().trim()
    }

    private suspend fun flashLight(duration: Long) {
        val currentCameraId = cameraId ?: return
        try {
            cameraManager.setTorchMode(currentCameraId, true)
            delay(duration)
            cameraManager.setTorchMode(currentCameraId, false)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun turnOffFlashlight() {
        val currentCameraId = cameraId ?: return
        try {
            cameraManager.setTorchMode(currentCameraId, false)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopMorsePlayback() {
        morsePlaybackJob?.cancel()
    }

    private fun updateUi(isPlaying: Boolean) {
        startButton.isEnabled = !isPlaying
        stopButton.isVisible = isPlaying
    }

    override fun onStop() {
        super.onStop()
        stopMorsePlayback()
    }
}