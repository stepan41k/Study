package com.example.parsekotlin

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import androidx.annotation.RequiresApi
import com.example.parsekotlin.models.GroupLink
import com.example.parsekotlin.models.GroupSchedule
import com.example.parsekotlin.models.LessonType
import com.example.parsekotlin.models.WeekDay
import kotlinx.coroutines.*
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

class AppWidget : AppWidgetProvider() {

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateWidget(context, id)
        }
    }

    companion object {

        @RequiresApi(Build.VERSION_CODES.O)
        fun refreshAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, AppWidget::class.java))
            for (id in ids) {
                updateWidget(context, id)
            }
        }

        @RequiresApi(Build.VERSION_CODES.O)
        fun updateWidget(context: Context, widgetId: Int) {
            val prefs = context.getSharedPreferences("last_group", Context.MODE_PRIVATE)
            val name = prefs.getString("name", "ГРУППА")
            val url = prefs.getString("url", "")

            val views = RemoteViews(context.packageName, R.layout.app_widget)
            views.setTextViewText(R.id.widgetGroupName, name ?: "Группа")
            
            val todayDate = LocalDate.now().format(DateTimeFormatter.ofPattern("d MMM", Locale("ru")))
            views.setTextViewText(R.id.widgetDate, todayDate)

            views.setViewVisibility(R.id.widgetEmptyText, View.VISIBLE)
            views.setTextViewText(R.id.widgetEmptyText, "Загрузка...")
            views.removeAllViews(R.id.widgetScheduleContainer)

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widgetRoot, pendingIntent) // widgetRoot должен быть ID корневого Layout в app_widget.xml

            val manager = AppWidgetManager.getInstance(context)
            manager.updateAppWidget(widgetId, views)

            if (!name.isNullOrEmpty() && !url.isNullOrEmpty()) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val parser = Parser()
                        val schedule: GroupSchedule = parser.fetchGroupSchedule(GroupLink(name, url))

                        withContext(Dispatchers.Main) {
                            renderSchedule(context, views, schedule, widgetId, manager)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        withContext(Dispatchers.Main) {
                            views.setTextViewText(R.id.widgetEmptyText, "Ошибка")
                            manager.updateAppWidget(widgetId, views)
                        }
                    }
                }
            } else {
                views.setTextViewText(R.id.widgetEmptyText, "Группа не выбрана")
                manager.updateAppWidget(widgetId, views)
            }
        }

        @RequiresApi(Build.VERSION_CODES.O)
        private fun renderSchedule(
            context: Context,
            views: RemoteViews,
            schedule: GroupSchedule,
            widgetId: Int,
            manager: AppWidgetManager
        ) {
            views.removeAllViews(R.id.widgetScheduleContainer)

            val today = LocalDate.now().dayOfWeek
            val day = when (today) {
                DayOfWeek.MONDAY -> WeekDay.MONDAY
                DayOfWeek.TUESDAY -> WeekDay.TUESDAY
                DayOfWeek.WEDNESDAY -> WeekDay.WEDNESDAY
                DayOfWeek.THURSDAY -> WeekDay.THURSDAY
                DayOfWeek.FRIDAY -> WeekDay.FRIDAY
                DayOfWeek.SATURDAY -> WeekDay.SATURDAY
                else -> WeekDay.SUNDAY
            }

            val lessons = schedule.lessonsByDay[day] ?: emptyList()

            if (lessons.isEmpty()) {
                views.setViewVisibility(R.id.widgetEmptyText, View.VISIBLE)
                views.setTextViewText(R.id.widgetEmptyText, "Сегодня нет пар 🎉")
            } else {
                views.setViewVisibility(R.id.widgetEmptyText, View.GONE)

                for (lesson in lessons) {
                    val row = RemoteViews(context.packageName, R.layout.item_widget_row)

                    val times = lesson.time?.split(" ") ?: listOf("", "")
                    val startTime = times.getOrElse(0) { "" }
                    val endTime = times.getOrElse(1) { "" }

                    row.setTextViewText(R.id.rowTimeStart, startTime)
                    row.setTextViewText(R.id.rowTimeEnd, endTime)

                    row.setTextViewText(R.id.rowSubject, lesson.subject)
                    row.setTextViewText(R.id.rowRoom, lesson.room ?: "")
                    row.setTextViewText(R.id.rowTeacher, lesson.teacher ?: "")

                    val colorRes = when (lesson.type) {
                        LessonType.LECTURE -> R.color.lecture_color
                        LessonType.PRACTICE -> R.color.practice_color
                        LessonType.LAB -> R.color.lab_color
                        LessonType.SEMINAR -> R.color.seminar_color
                        else -> R.color.other_color
                    }
                    // В RemoteViews нельзя просто передать colorRes, нужно достать цвет
                    // Но setInt для setBackgroundColor требует цвет, а не ресурс.
                    // Проще использовать ImageView и setImageViewResource, но у нас View.
                    // Трюк: используем setInt с методом "setBackgroundColor" и достаем цвет из ресурсов:
                    val color = context.getColor(colorRes)
                    row.setInt(R.id.rowTypeIndicator, "setBackgroundColor", color)

                    views.addView(R.id.widgetScheduleContainer, row)
                }
            }
            manager.updateAppWidget(widgetId, views)
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            refreshAllWidgets(context)
        }
    }
}