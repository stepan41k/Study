package com.example.parsekotlin

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.*
import com.example.parsekotlin.databinding.ActivityScheduleBinding
import com.example.parsekotlin.models.*

class ScheduleActivity : AppCompatActivity() {
    private lateinit var binding: ActivityScheduleBinding
    private val parser = Parser()
    private val coroutineScope = CoroutineScope(Dispatchers.Main)
    private lateinit var adapter: ScheduleAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityScheduleBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val groupName = intent.getStringExtra("groupName") ?: ""
        val groupUrl = intent.getStringExtra("groupUrl") ?: ""

        supportActionBar?.title = "Расписание: $groupName"
        binding.title.text = "Расписание: $groupName"

        setupRecyclerView()
        loadSchedule(groupName, groupUrl)
    }

    private fun setupRecyclerView() {
        adapter = ScheduleAdapter(emptyList())
        binding.scheduleRecyclerView.layoutManager = LinearLayoutManager(this)
        binding.scheduleRecyclerView.adapter = adapter
    }

    private fun loadSchedule(groupName: String, groupUrl: String) {
        coroutineScope.launch {
            try {
                binding.progressBar.visibility = View.VISIBLE
                binding.scheduleRecyclerView.visibility = View.GONE
                binding.emptyState.visibility = View.GONE

                val schedule = withContext(Dispatchers.IO) {
                    parser.fetchGroupSchedule(GroupLink(groupName, groupUrl))
                }

                displaySchedule(schedule)

            } catch (e: Exception) {
                binding.emptyState.text = "Ошибка загрузки расписания: ${e.message}"
                binding.emptyState.visibility = View.VISIBLE
                binding.scheduleRecyclerView.visibility = View.GONE
                e.printStackTrace()
            } finally {
                binding.progressBar.visibility = View.GONE
            }
        }
    }

    private fun displaySchedule(schedule: GroupSchedule) {
        if (schedule.lessonsByDay.isEmpty()) {
            binding.emptyState.visibility = View.VISIBLE
            binding.scheduleRecyclerView.visibility = View.GONE
        } else {
            val scheduleItems = convertToScheduleItems(schedule)
            adapter.updateData(scheduleItems)
            binding.scheduleRecyclerView.visibility = View.VISIBLE
            binding.emptyState.visibility = View.GONE
        }
    }

    private fun convertToScheduleItems(schedule: GroupSchedule): List<ScheduleItem> {
        val items = mutableListOf<ScheduleItem>()

        val sortedDays = schedule.lessonsByDay.entries.sortedBy { (day, _) ->
            when (day) {
                WeekDay.MONDAY -> 0
                WeekDay.TUESDAY -> 1
                WeekDay.WEDNESDAY -> 2
                WeekDay.THURSDAY -> 3
                WeekDay.FRIDAY -> 4
                WeekDay.SATURDAY -> 5
                WeekDay.SUNDAY -> 6
            }
        }

        for ((day, lessons) in sortedDays) {
            items.add(ScheduleItem.DayHeader(day))

            if (lessons.isEmpty()) {
                items.add(ScheduleItem.EmptyDay(day))
            } else {
                lessons.forEach { lesson ->
                    items.add(ScheduleItem.LessonItem(day, lesson))
                }
            }
        }

        return items
    }

    override fun onDestroy() {
        super.onDestroy()
        coroutineScope.cancel()
    }
}

sealed class ScheduleItem {
    data class DayHeader(val day: WeekDay) : ScheduleItem()
    data class EmptyDay(val day: WeekDay) : ScheduleItem()
    data class LessonItem(val day: WeekDay, val lesson: com.example.parsekotlin.models.Lesson) : ScheduleItem()
}

class ScheduleAdapter(private var items: List<ScheduleItem>) :
    RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {
        private const val TYPE_DAY_HEADER = 0
        private const val TYPE_EMPTY_DAY = 1
        private const val TYPE_LESSON = 2
    }

    inner class DayHeaderViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        private val dayName: TextView = view.findViewById(R.id.dayName)

        fun bind(day: WeekDay) {
            val dayText = when (day) {
                WeekDay.MONDAY -> "ПОНЕДЕЛЬНИК"
                WeekDay.TUESDAY -> "ВТОРНИК"
                WeekDay.WEDNESDAY -> "СРЕДА"
                WeekDay.THURSDAY -> "ЧЕТВЕРГ"
                WeekDay.FRIDAY -> "ПЯТНИЦА"
                WeekDay.SATURDAY -> "СУББОТА"
                WeekDay.SUNDAY -> "ВОСКРЕСЕНЬЕ"
            }
            dayName.text = dayText
        }
    }

    inner class EmptyDayViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        fun bind(day: WeekDay) {
        }
    }

    inner class LessonViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        private val time: TextView = view.findViewById(R.id.timeText)
        private val subject: TextView = view.findViewById(R.id.subjectText)
        private val teacher: TextView = view.findViewById(R.id.teacherText)
        private val room: TextView = view.findViewById(R.id.roomText)
        private val type: TextView = view.findViewById(R.id.typeText)
        private val comment: TextView = view.findViewById(R.id.commentText)
        private val typeIndicator: View = view.findViewById(R.id.typeIndicator)

        fun bind(lesson: com.example.parsekotlin.models.Lesson) {
            time.text = lesson.time ?: "—"
            subject.text = lesson.subject
            teacher.text = lesson.teacher ?: ""
            room.text = lesson.room ?: ""
            comment.text = lesson.comment

            val (typeText, colorRes) = when (lesson.type) {
                LessonType.LECTURE -> "Лекция" to R.color.lecture_color
                LessonType.PRACTICE -> "Практика" to R.color.practice_color
                LessonType.LAB -> "Лабораторная" to R.color.lab_color
                LessonType.SEMINAR -> "Семинар" to R.color.seminar_color
                LessonType.LECTUREANDPRACTICE -> "Лекция/Практика" to R.color.lecpract_color
                LessonType.ALL -> "Лекция/Лаба/Практика" to R.color.all_color
                else -> "" to R.color.other_color
            }

            val color = itemView.context.getColor(colorRes)

            type.text = typeText
            if (typeText.isNotEmpty()) {
                type.visibility = View.VISIBLE
                typeIndicator.visibility = View.VISIBLE
                typeIndicator.setBackgroundColor(color)
            } else {
                type.visibility = View.GONE
                typeIndicator.visibility = View.GONE
            }

            type.background.setTint(color)

            teacher.visibility = if (lesson.teacher.isNullOrEmpty()) View.GONE else View.VISIBLE
            room.visibility = if (lesson.room.isNullOrEmpty()) View.GONE else View.VISIBLE
            comment.visibility = if (lesson.comment.isEmpty()) View.GONE else View.VISIBLE
        }
    }

    override fun getItemViewType(position: Int): Int {
        return when (items[position]) {
            is ScheduleItem.DayHeader -> TYPE_DAY_HEADER
            is ScheduleItem.EmptyDay -> TYPE_EMPTY_DAY
            is ScheduleItem.LessonItem -> TYPE_LESSON
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return when (viewType) {
            TYPE_DAY_HEADER -> {
                val view = LayoutInflater.from(parent.context)
                    .inflate(R.layout.item_day_header, parent, false)
                DayHeaderViewHolder(view)
            }
            TYPE_EMPTY_DAY -> {
                val view = LayoutInflater.from(parent.context)
                    .inflate(R.layout.item_empty_day, parent, false)
                EmptyDayViewHolder(view)
            }
            TYPE_LESSON -> {
                val view = LayoutInflater.from(parent.context)
                    .inflate(R.layout.item_lesson, parent, false)
                LessonViewHolder(view)
            }
            else -> throw IllegalArgumentException("Unknown view type")
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        when (val item = items[position]) {
            is ScheduleItem.DayHeader -> (holder as DayHeaderViewHolder).bind(item.day)
            is ScheduleItem.EmptyDay -> (holder as EmptyDayViewHolder).bind(item.day)
            is ScheduleItem.LessonItem -> (holder as LessonViewHolder).bind(item.lesson)
        }
    }

    override fun getItemCount(): Int = items.size

    fun updateData(newItems: List<ScheduleItem>) {
        items = newItems
        notifyDataSetChanged()
    }
}