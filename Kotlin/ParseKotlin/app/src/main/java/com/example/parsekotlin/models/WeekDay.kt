package com.example.parsekotlin.models


enum class WeekDay {
    MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY;

    companion object {
        fun fromDisplay(displayName: String): WeekDay? {
            return when {
                displayName.contains("понедельник", true) -> MONDAY
                displayName.contains("вторник", true) -> TUESDAY
                displayName.contains("среда", true) -> WEDNESDAY
                displayName.contains("четверг", true) -> THURSDAY
                displayName.contains("пятница", true) -> FRIDAY
                displayName.contains("суббота", true) -> SATURDAY
                displayName.contains("воскресенье", true) -> SUNDAY
                else -> null
            }
        }
    }
}