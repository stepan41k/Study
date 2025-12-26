package com.example.parsekotlin

import android.util.Log
import org.jsoup.Jsoup
import com.example.parsekotlin.models.*
import kotlin.text.replace

class Parser {

    fun fetchInstitutesByCourse(grade: Int): List<Institute> {
        val url = "https://portal.novsu.ru/univer/timetable/ochn/"
        Log.d("Parser", "!!!Загружаем данные для $grade курса с портала")

        val doc = try {
            Jsoup.connect(url)
                .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                .timeout(15000)
                .get()
        } catch (e: Exception) {
            Log.e("Parser", "Ошибка загрузки с портала: ${e.message}")
            return emptyList()
        }

        return parseInstitutesFromTable(doc, grade)
    }

    private fun parseInstitutesFromTable(doc: org.jsoup.nodes.Document, targetGrade: Int): List<Institute> {
        val institutes = mutableListOf<Institute>()

        val tables = doc.select("table.viewtable")
        Log.d("Parser", "Найдено таблиц viewtable: ${tables.size}")

        var currentInstitute = "Неизвестный институт"

        for (table in tables) {
            val instituteHeader = table.select("th")
            if (instituteHeader.isNotEmpty()) {
                currentInstitute = instituteHeader.text().trim()
                Log.d("Parser", "Найден институт: $currentInstitute")
                continue
            }

            val courseRows = table.select("tr:has(td:contains(курс))")
            if (courseRows.isEmpty()) continue

            for (courseRow in courseRows) {
                val courseCells = courseRow.select("td")

                for ((cellIndex, cell) in courseCells.withIndex()) {
                    val cellText = cell.text().trim()

                    if (cellText.contains("$targetGrade курс") ||
                        (cellText == targetGrade.toString() && cellIndex == targetGrade - 1)) {

                        val nextRow = courseRow.nextElementSibling()
                        if (nextRow != null && nextRow.tagName() == "tr") {
                            val groupCells = nextRow.select("td")
                            if (cellIndex < groupCells.size) {
                                val groupCell = groupCells[cellIndex]
                                val groups = parseGroupsFromCell(groupCell, currentInstitute)

                                if (groups.isNotEmpty()) {
                                    institutes.add(Institute(currentInstitute, groups))
                                    Log.d("Parser", "Добавлен институт '$currentInstitute' с ${groups.size} группами для $targetGrade курса")
                                }
                            }
                        }
                    }
                }
            }
        }

        if (institutes.isEmpty()) {
            Log.d("Parser", "Не найдено данных для $targetGrade курса")
        }

        return institutes
    }

    private fun parseGroupsFromCell(cell: org.jsoup.nodes.Element, instituteName: String): List<GroupLink> {
        val groups = mutableListOf<GroupLink>()

        val links = cell.select("a[href*='EditViewGroup']")

        for (link in links) {
            val groupName = link.text().trim()
            var href = link.attr("href")

            val fullUrl = if (href.startsWith("/")) {
                "https://portal.novsu.ru$href"
            } else {
                href
            }

            groups.add(GroupLink(groupName, fullUrl))
            Log.d("Parser", "Найдена группа: $groupName -> $fullUrl")
        }

        return groups
    }

    fun fetchGroupSchedule(group: GroupLink): GroupSchedule {
        Log.d("Parser", "!!! Загружаем расписание для ${group.name} по URL: ${group.href}")

        val doc = try {
            Jsoup.connect(group.href)
                .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                .timeout(10000)
                .get()
        } catch (e: Exception) {
            Log.e("Parser", "Ошибка загрузки расписания: ${e.message}")
            return GroupSchedule(group.name)
        }

        val lessonsByDay = parseRealSchedule(doc)

        Log.d("Parser", "Расписание загружено: ${lessonsByDay.size} дней")
        return GroupSchedule(group.name, lessonsByDay)
    }

    private fun parseRealSchedule(doc: org.jsoup.nodes.Document): Map<WeekDay, List<Lesson>> {
        val lessonsByDay = mutableMapOf<WeekDay, MutableList<Lesson>>()

        val scheduleTable = doc.select("table.shedultable").first()
        if (scheduleTable == null) {
            Log.d("Parser", "Таблица shedultable не найдена")
            return emptyMap()
        }

        val rows = scheduleTable.select("tr")
        var currentDay: WeekDay? = null

        Log.d("Parser", "Найдено строк в таблице: ${rows.size}")

        for (row in rows) {
            if (row.select("th").isNotEmpty()) continue

            val cells = row.select("td")
            if (cells.isEmpty()) continue

            val cellTexts = cells.map { it.text().trim() }
            Log.d("Parser", "Строка: $cellTexts")

            val firstCellText = cells[0].text().trim()
            val day = parseDayOfWeek(firstCellText)

            if (day != null) {
                currentDay = day
                Log.d("Parser", "Найден день: $currentDay")

                parseAndAddLesson(cells, currentDay, lessonsByDay, isFirstInDay = true)
            } else if (currentDay != null) {
                parseAndAddLesson(cells, currentDay, lessonsByDay, isFirstInDay = false)
            }
        }

        Log.d("Parser", "Распарсено дней: ${lessonsByDay.size}")
        lessonsByDay.forEach { (day, lessons) ->
            Log.d("Parser", "$day: ${lessons.size} занятий")
            lessons.forEachIndexed { index, lesson ->
                Log.d("Parser", "  $index. ${lesson.time} - ${lesson.subject} (${lesson.teacher})")
            }
        }

        return lessonsByDay
    }

    private fun parseAndAddLesson(
        cells: org.jsoup.select.Elements,
        day: WeekDay,
        lessonsByDay: MutableMap<WeekDay, MutableList<Lesson>>,
        isFirstInDay: Boolean
    ) {
        val lesson = parseLessonFromCells(cells, isFirstInDay)
        if (lesson != null) {
            lessonsByDay.getOrPut(day) { mutableListOf() }.add(lesson)
            Log.d("Parser", "Добавлено занятие для $day: ${lesson.subject}")
        }
    }

    private fun parseLessonFromCells(cells: org.jsoup.select.Elements, isFirstInDay: Boolean): Lesson? {
        try {
            val startIndex = if (isFirstInDay) 1 else 0

            val timeIndex = startIndex
            val timeCell = cells.getOrNull(timeIndex)
            val time = timeCell?.text()?.trim() ?: ""

            val subjectIndex = startIndex + 2
            val subjectCell = cells.getOrNull(subjectIndex)
            var subjectText = subjectCell?.text()?.trim() ?: ""

            if (subjectText.isEmpty() && cells.size > subjectIndex + 1) {
                val altSubjectCell = cells.getOrNull(subjectIndex + 1)
                subjectText = altSubjectCell?.text()?.trim() ?: ""
            }

            if (subjectText.isEmpty()) return null

            val type = determineLessonType(subjectText)

            subjectText = subjectText.replace("(лаб.)", "")
                .replace("(пр.)", "")
                .replace("(лек/пр/лаб)", "")
                .replace("(лек/пр.)", "")
                .replace("(лек.)", "")
                .trim()

            val teacherIndex = startIndex + 3
            val teacherCell = cells.getOrNull(teacherIndex)
            val teacher = teacherCell?.text()?.trim() ?: ""

            val roomIndex = startIndex + 4
            val roomCell = cells.getOrNull(roomIndex)
            val room = roomCell?.text()?.trim() ?: ""

            val commentIndex = startIndex + 5
            val commentCell = cells.getOrNull(commentIndex)
            val comment = commentCell?.text()?.trim() ?: ""

            return Lesson(time, subjectText, teacher, room, type, comment)
        } catch (e: Exception) {
            Log.e("Parser", "Ошибка парсинга занятия: ${e.message}")
            return null
        }
    }

    private fun parseDayOfWeek(text: String): WeekDay? {
        return when (text) {
            "Пн" -> WeekDay.MONDAY
            "Вт" -> WeekDay.TUESDAY
            "Ср" -> WeekDay.WEDNESDAY
            "Чт" -> WeekDay.THURSDAY
            "Пт" -> WeekDay.FRIDAY
            "Сб" -> WeekDay.SATURDAY
            "Вс" -> WeekDay.SUNDAY
            else -> null
        }
    }

    private fun determineLessonType(subjectText: String): LessonType {
        return when {
            subjectText.contains("(лаб.)") -> LessonType.LAB
            subjectText.contains("(пр.)") -> LessonType.PRACTICE
            subjectText.contains("(лек.)") -> LessonType.LECTURE
            subjectText.contains("(лек/пр/лаб)") -> LessonType.ALL
            subjectText.contains("(лек/пр.)") -> LessonType.LECTUREANDPRACTICE
            subjectText.contains("(лек./пр.)") -> LessonType.LECTUREANDPRACTICE
            else -> LessonType.OTHER
        }
    }
}