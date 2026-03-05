// ЗАМЕНИ на свое имя пакета (написано в самом верху твоего старого файла)
package com.example.diplom1

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.diplom1.databinding.ActivityLoginBinding // замени diplom1 на свое название, если оно другое

class LoginActivity : AppCompatActivity() {

    // Эта переменная будет хранить ссылки на все элементы из XML
    private lateinit var binding: ActivityLoginBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Инициализация привязки (Binding)
        binding = ActivityLoginBinding.inflate(layoutInflater)

        // binding.root - это корневой элемент твоего XML (ConstraintLayout)
        setContentView(binding.root)

        // Теперь все кнопки и поля доступны через binding.ID_ИЗ_XML
        binding.loginButton.setOnClickListener {
            val email = binding.emailInput.text.toString()
            val password = binding.passwordInput.text.toString()

            if (email.isNotEmpty() && password.isNotEmpty()) {
                Toast.makeText(this, "Вход выполняется для: $email", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this, "Пожалуйста, заполните все поля", Toast.LENGTH_SHORT).show()
            }
        }
    }
}