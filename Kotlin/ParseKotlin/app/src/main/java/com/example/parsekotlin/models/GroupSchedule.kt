package com.example.parsekotlin.models

data class GroupSchedule(
    val groupName: String,
    val lessonsByDay: Map<WeekDay, List<Lesson>> = emptyMap()
)
