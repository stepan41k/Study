# 🛰 Satellite Tracker — Android приложение

Практическая работа №1: Отслеживание спутников на карте

## Описание

Android-приложение на Kotlin, которое:
- Загружает и парсит TLE-данные спутников с Celestrak API
- Вычисляет координаты спутника в реальном времени (библиотека Predict4Java)
- Отображает спутник на карте Yandex MapKit
- Строит траекторию движения за последние 24 часа + прогноз на 4 часа
- Автоматически обновляет позицию каждые 5 секунд

---

## Структура проекта

```
app/src/main/
├── java/com/example/satellitetracker/
│   ├── MainActivity.kt          # Главный экран, UI логика
│   ├── SatelliteViewModel.kt    # ViewModel (MVVM), управление состоянием
│   ├── SatelliteCalculator.kt   # Вычисление орбиты (Predict4Java)
│   ├── MapManager.kt            # Работа с Yandex MapKit
│   ├── TleRepository.kt         # TLE данные и парсинг
│   └── TleNetworkFetcher.kt     # Загрузка TLE с Celestrak API
├── res/
│   ├── layout/activity_main.xml # Разметка главного экрана
│   ├── drawable/
│   │   ├── ic_satellite.xml     # Иконка спутника на карте
│   │   └── ic_waypoint.xml      # Метка на траектории
│   └── values/
│       ├── strings.xml
│       └── themes.xml
└── AndroidManifest.xml
```

---

## Быстрый старт

### 1. Получите Yandex MapKit API ключ

1. Зайдите на https://developer.tech.yandex.ru/
2. Создайте проект, добавьте сервис **MapKit Mobile SDK**
3. Скопируйте API ключ

### 2. Вставьте ключ в два места:

**AndroidManifest.xml:**
```xml
<meta-data
    android:name="com.yandex.android.maps.YANDEX_API_KEY"
    android:value="ВАШ_КЛЮЧ_ЗДЕСЬ" />
```

**MainActivity.kt** (метод `initMapKit`):
```kotlin
MapKitFactory.setApiKey("ВАШ_КЛЮЧ_ЗДЕСЬ")
```

### 3. Синхронизируйте Gradle и запустите

```
File → Sync Project with Gradle Files
Run → Run 'app'
```

---

## Зависимости (build.gradle)

```gradle
// Yandex MapKit
implementation 'com.yandex.android:maps.mobile:4.6.1-full'

// Predict4Java — расчёт орбит
implementation 'com.github.davidmoten:predict4java:1.3.1'

// Kotlin Coroutines
implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'

// OkHttp — сетевые запросы
implementation 'com.squareup.okhttp3:okhttp:4.12.0'
```

Репозиторий Predict4Java: https://github.com/g4dpz/predict4java

---

## Источники TLE данных

| Группа        | URL |
|---------------|-----|
| Космические станции | https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=tle |
| Наблюдаемые объекты | https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=tle |

### Проверка вычислений

Проверить корректность координат для спутника CSS (TIANHE) можно на:
https://www.n2yo.com/satellite/?s=48274

---

## Как использовать приложение

1. **При запуске** — автоматически загружаются TLE с Celestrak
2. **Спиннер сверху** — выбор спутника из списка
3. **▶ Отслеживать** — запуск автообновления позиции (каждые 5 сек)
4. **🛤 Траектория** — отрисовка пути за 24ч + прогноз 4ч
5. **🎯 Центр** — центрирование камеры на спутнике

---

## Архитектура (MVVM)

```
MainActivity ──observe──► SatelliteViewModel
                               │
                    ┌──────────┴──────────┐
                    ▼                     ▼
          SatelliteCalculator      TleNetworkFetcher
          (Predict4Java)           (OkHttp + Celestrak)
                    │
                    ▼
              MapManager
            (Yandex MapKit)
```

---

## Формат TLE

```
ISS (ZARYA)                          ← Название
1 25544U 98067A   24010.27  .00010  00000  19660-3 0  9991  ← Строка 1
2 25544  51.6319 178.5071  0011017 103.7643 256.4573 15.486  ← Строка 2
```

- **Строка 1**: номер NORAD, дата запуска, параметры орбиты
- **Строка 2**: наклонение, долгота восходящего узла, эксцентриситет, аргумент перигея, среднее движение

TLE устаревают примерно через 2 недели — обновляйте регулярно.
