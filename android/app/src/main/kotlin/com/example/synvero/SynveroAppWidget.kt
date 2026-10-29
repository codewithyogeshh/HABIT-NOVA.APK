package com.example.synvero

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class SynveroAppWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        const val PREFS_NAME = "HabbitNovaWidgetPrefs"
        const val KEY_USERNAME = "widget_username"
        const val KEY_STREAK = "widget_streak"
        const val KEY_HABITS_COUNT = "widget_habits_count"
        const val KEY_HABITS_TOTAL = "widget_habits_total"
        const val KEY_HABITS_DONE = "widget_habits_done"
        const val KEY_HABITS_JSON = "widget_habits_json"

        const val KEY_TASKS_COUNT = "widget_tasks_count"
        const val KEY_TASKS_TOTAL = "widget_tasks_total"
        const val KEY_TASKS_DONE = "widget_tasks_done"
        const val KEY_TASKS_JSON = "widget_tasks_json"

        const val KEY_BANNER_TITLE = "widget_banner_title"
        const val KEY_BANNER_SUBTITLE = "widget_banner_subtitle"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val username = prefs.getString(KEY_USERNAME, "Yogesh") ?: "Yogesh"
            val streak = prefs.getString(KEY_STREAK, "1d") ?: "1d"

            val habitsCount = prefs.getString(KEY_HABITS_COUNT, "5 of 5") ?: "5 of 5"
            val habitsTotal = prefs.getInt(KEY_HABITS_TOTAL, 5)
            val habitsDone = prefs.getInt(KEY_HABITS_DONE, 5)

            val tasksCount = prefs.getString(KEY_TASKS_COUNT, "2 of 4") ?: "2 of 4"
            val tasksTotal = prefs.getInt(KEY_TASKS_TOTAL, 4)
            val tasksDone = prefs.getInt(KEY_TASKS_DONE, 2)

            val bannerTitle = prefs.getString(KEY_BANNER_TITLE, "You're doing great!") ?: "You're doing great!"
            val bannerSubtitle = prefs.getString(KEY_BANNER_SUBTITLE, "Discipline today builds the freedom of tomorrow.") ?: "Discipline today builds the freedom of tomorrow."

            // Date calculations
            val now = Date()
            val dateStr = SimpleDateFormat("MMM d, yyyy", Locale.ENGLISH).format(now)
            val dayStr = SimpleDateFormat("EEEE", Locale.ENGLISH).format(now)

            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val views = RemoteViews(context.packageName, R.layout.synvero_app_widget).apply {
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                // Header
                setTextViewText(R.id.widget_username_tagline, "$username • Small Steps, Big Changes")
                setTextViewText(R.id.widget_date_text, dateStr)
                setTextViewText(R.id.widget_date_day, dayStr)
                setTextViewText(R.id.widget_streak_days, streak)

                // Habits Progress & Count
                setTextViewText(R.id.widget_habits_count, habitsCount)
                setProgressBar(
                    R.id.widget_habits_bar,
                    habitsTotal.coerceAtLeast(1),
                    habitsDone,
                    false
                )

                // Tasks Progress & Count
                setTextViewText(R.id.widget_tasks_count, tasksCount)
                setProgressBar(
                    R.id.widget_tasks_bar,
                    tasksTotal.coerceAtLeast(1),
                    tasksDone,
                    false
                )

                // Bottom Banner
                setTextViewText(R.id.widget_banner_title, bannerTitle)
                setTextViewText(R.id.widget_banner_subtitle, bannerSubtitle)

                // Populate Habit rows
                val habitsJson = prefs.getString(KEY_HABITS_JSON, null)
                val habitsArray = if (!habitsJson.isNullOrEmpty()) {
                    try { JSONArray(habitsJson) } catch (e: Exception) { getDefaultHabitsJson() }
                } else {
                    getDefaultHabitsJson()
                }

                for (i in 0 until 5) {
                    val rowId = context.resources.getIdentifier("widget_habit_row_${i + 1}", "id", context.packageName)
                    val checkId = context.resources.getIdentifier("widget_habit_check_${i + 1}", "id", context.packageName)
                    val iconId = context.resources.getIdentifier("widget_habit_icon_${i + 1}", "id", context.packageName)
                    val titleId = context.resources.getIdentifier("widget_habit_title_${i + 1}", "id", context.packageName)
                    val divId = if (i < 4) context.resources.getIdentifier("widget_habit_div_${i + 1}", "id", context.packageName) else 0

                    if (i < habitsArray.length()) {
                        val obj = habitsArray.getJSONObject(i)
                        val title = obj.optString("title", "Habit ${i + 1}")
                        val icon = obj.optString("icon", "🌿")
                        val done = obj.optBoolean("done", false)

                        setViewVisibility(rowId, View.VISIBLE)
                        setImageViewResource(checkId, if (done) R.drawable.ic_check_green else R.drawable.ic_check_empty)
                        setTextViewText(iconId, icon)
                        setTextViewText(titleId, title)
                        if (divId != 0) setViewVisibility(divId, if (i == habitsArray.length() - 1) View.GONE else View.VISIBLE)
                    } else {
                        setViewVisibility(rowId, View.GONE)
                        if (divId != 0) setViewVisibility(divId, View.GONE)
                    }
                }

                // Populate Task rows
                val tasksJson = prefs.getString(KEY_TASKS_JSON, null)
                val tasksArray = if (!tasksJson.isNullOrEmpty()) {
                    try { JSONArray(tasksJson) } catch (e: Exception) { getDefaultTasksJson() }
                } else {
                    getDefaultTasksJson()
                }

                for (i in 0 until 4) {
                    val rowId = context.resources.getIdentifier("widget_task_row_${i + 1}", "id", context.packageName)
                    val checkId = context.resources.getIdentifier("widget_task_check_${i + 1}", "id", context.packageName)
                    val titleId = context.resources.getIdentifier("widget_task_title_${i + 1}", "id", context.packageName)
                    val divId = if (i < 3) context.resources.getIdentifier("widget_task_div_${i + 1}", "id", context.packageName) else 0

                    if (i < tasksArray.length()) {
                        val obj = tasksArray.getJSONObject(i)
                        val title = obj.optString("title", "Task ${i + 1}")
                        val done = obj.optBoolean("done", false)

                        setViewVisibility(rowId, View.VISIBLE)
                        setImageViewResource(checkId, if (done) R.drawable.ic_check_purple else R.drawable.ic_check_empty)
                        setTextViewText(titleId, title)
                        if (divId != 0) setViewVisibility(divId, if (i == tasksArray.length() - 1) View.GONE else View.VISIBLE)
                    } else {
                        setViewVisibility(rowId, View.GONE)
                        if (divId != 0) setViewVisibility(divId, View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun getDefaultHabitsJson(): JSONArray {
            return JSONArray().apply {
                put(org.json.JSONObject().put("title", "Drink Water").put("icon", "💧").put("done", true))
                put(org.json.JSONObject().put("title", "Workout").put("icon", "🏋️").put("done", true))
                put(org.json.JSONObject().put("title", "Read Book").put("icon", "📖").put("done", true))
                put(org.json.JSONObject().put("title", "Meditate").put("icon", "🧘").put("done", true))
                put(org.json.JSONObject().put("title", "Sleep Early").put("icon", "🌙").put("done", true))
            }
        }

        private fun getDefaultTasksJson(): JSONArray {
            return JSONArray().apply {
                put(org.json.JSONObject().put("title", "Complete Project").put("done", true))
                put(org.json.JSONObject().put("title", "Learn Java").put("done", true))
                put(org.json.JSONObject().put("title", "Design Portfolio").put("done", false))
                put(org.json.JSONObject().put("title", "Workout Plan").put("done", false))
            }
        }
    }
}
