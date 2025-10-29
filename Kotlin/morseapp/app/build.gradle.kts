plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.morseapp" // Убедитесь, что здесь ваш пакет
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.morseapp"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    // Если используете ViewBinding (необязательно, но удобно)
    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    // --- ОСНОВНЫЕ ЗАВИСИМОСТИ, КОТОРЫЕ РЕШАЮТ ПРОБЛЕМУ 'appcompat' ---
    implementation("androidx.core:core-ktx:1.12.0") // Core Kotlin extensions
    implementation("androidx.appcompat:appcompat:1.6.1") // <--- ВОТ ЭТА СТРОКА РЕШАЕТ ОШИБКУ
    implementation("com.google.android.material:material:1.11.0") // Material Design компоненты
    implementation("androidx.constraintlayout:constraintlayout:2.1.4") // Для ConstraintLayout

    // Зависимости для корутин
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")

    // Зависимости для тестирования
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}