package com.example.parsekotlin.models

data class Lesson(
    val time: String?,
    val subject: String,
    val teacher: String?,
    val room: String?,
    val type: LessonType,
    val comment: String = ""
)