package com.example.synvero

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
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

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_TOGGLE_HABIT -> {
                val index = intent.getIntExtra(EXTRA_ITEM_INDEX, -1)
                if (index >= 0) {
                    handleToggleHabit(context, index)
                }
            }
            ACTION_TOGGLE_TASK -> {
                val index = intent.getIntExtra(EXTRA_ITEM_INDEX, -1)
                if (index >= 0) {
                    handleToggleTask(context, index)
                }
            }
        }
    }

    private fun handleToggleHabit(context: Context, index: Int) {
        try {
            val widgetPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val habitsJson = widgetPrefs.getString(KEY_HABITS_JSON, null)
            val habitsArray = if (!habitsJson.isNullOrEmpty()) {
                try { JSONArray(habitsJson) } catch (e: Exception) { getDefaultHabitsJson() }
            } else {
                getDefaultHabitsJson()
            }

            if (index < habitsArray.length()) {
                val obj = habitsArray.getJSONObject(index)
                val currentDone = obj.optBoolean("done", false)
                val newDone = !currentDone
                obj.put("done", newDone)

                // Recount habits done
                var doneCount = 0
                for (i in 0 until habitsArray.length()) {
                    if (habitsArray.getJSONObject(i).optBoolean("done", false)) {
                        doneCount++
                    }
                }
                val totalCount = habitsArray.length()

                // Save to widget SharedPreferences
                widgetPrefs.edit()
                    .putString(KEY_HABITS_JSON, habitsArray.toString())
                    .putInt(KEY_HABITS_DONE, doneCount)
                    .putInt(KEY_HABITS_TOTAL, totalCount)
                    .putString(KEY_HABITS_COUNT, "$doneCount of $totalCount")
                    .apply()

                // Sync directly to FlutterSharedPreferences so app reflects the change!
                try {
                    val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val userId = widgetPrefs.getString(KEY_USER_ID, "guest") ?: "guest"
                    val dateStr = SimpleDateFormat("yyyy-MM-dd", Locale.ENGLISH).format(Date())
                    val habitId = "def-${index + 1}"

                    flutterPrefs.edit()
                        .putBoolean("flutter.user_${userId}_habit_${habitId}_completed_$dateStr", newDone)
                        .putBoolean("flutter.user_${userId}_habit_${habitId}_completed", newDone)
                        .putString("flutter.user_${userId}_last_habit_date", dateStr)
                        .apply()
                } catch (e: Exception) {
                    // Ignored
                }

                // Immediately update all home screen widget instances!
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisWidget = ComponentName(context, SynveroAppWidget::class.java)
                val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                for (id in allWidgetIds) {
                    updateAppWidget(context, appWidgetManager, id)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun handleToggleTask(context: Context, index: Int) {
        try {
            val widgetPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val tasksJson = widgetPrefs.getString(KEY_TASKS_JSON, null)
            val tasksArray = if (!tasksJson.isNullOrEmpty()) {
                try { JSONArray(tasksJson) } catch (e: Exception) { getDefaultTasksJson() }
            } else {
                getDefaultTasksJson()
            }

            if (index < tasksArray.length()) {
                val obj = tasksArray.getJSONObject(index)
                val currentDone = obj.optBoolean("done", false)
                val newDone = !currentDone
                obj.put("done", newDone)

                // Recount tasks done
                var doneCount = 0
                for (i in 0 until tasksArray.length()) {
                    if (tasksArray.getJSONObject(i).optBoolean("done", false)) {
                        doneCount++
                    }
                }
                val totalCount = tasksArray.length()

                widgetPrefs.edit()
                    .putString(KEY_TASKS_JSON, tasksArray.toString())
                    .putInt(KEY_TASKS_DONE, doneCount)
                    .putInt(KEY_TASKS_TOTAL, totalCount)
                    .putString(KEY_TASKS_COUNT, "$doneCount of $totalCount")
                    .apply()

                // Immediately update all home screen widget instances!
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisWidget = ComponentName(context, SynveroAppWidget::class.java)
                val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                for (id in allWidgetIds) {
                    updateAppWidget(context, appWidgetManager, id)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    companion object {
        const val PREFS_NAME = "HabbitNovaWidgetPrefs"
        const val KEY_USER_ID = "widget_user_id"
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

        const val ACTION_TOGGLE_HABIT = "com.example.synvero.ACTION_TOGGLE_HABIT"
        const val ACTION_TOGGLE_TASK = "com.example.synvero.ACTION_TOGGLE_TASK"
        const val EXTRA_ITEM_INDEX = "extra_item_index"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val username = prefs.getString(KEY_USERNAME, "Yogesh") ?: "Yogesh"
            val streak = prefs.getString(KEY_STREAK, "1d") ?: "1d"

            val habitsTotal = prefs.getInt(KEY_HABITS_TOTAL, 5)
            val habitsDone = prefs.getInt(KEY_HABITS_DONE, 5)
            val habitsCount = prefs.getString(KEY_HABITS_COUNT, "$habitsDone of $habitsTotal") ?: "$habitsDone of $habitsTotal"

            val tasksTotal = prefs.getInt(KEY_TASKS_TOTAL, 4)
            val tasksDone = prefs.getInt(KEY_TASKS_DONE, 2)
            val tasksCount = prefs.getString(KEY_TASKS_COUNT, "$tasksDone of $tasksTotal") ?: "$tasksDone of $tasksTotal"

            val bannerTitle = prefs.getString(KEY_BANNER_TITLE, "You're doing great!") ?: "You're doing great!"
            val bannerSubtitle = prefs.getString(KEY_BANNER_SUBTITLE, "Discipline today builds the freedom of tomorrow.") ?: "Discipline today builds the freedom of tomorrow."

            // Date calculations
            val now = Date()
            val dateStr = SimpleDateFormat("MMM d, yyyy", Locale.ENGLISH).format(now)
            val dayStr = SimpleDateFormat("EEEE", Locale.ENGLISH).format(now)

            // App launch intent for header and background
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

                        // Attach 1-tap toggle PendingIntent directly to check icon and row!
                        val toggleIntent = Intent(context, SynveroAppWidget::class.java).apply {
                            action = ACTION_TOGGLE_HABIT
                            putExtra(EXTRA_ITEM_INDEX, i)
                        }
                        val togglePendingIntent = PendingIntent.getBroadcast(
                            context,
                            100 + i,
                            toggleIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        setOnClickPendingIntent(checkId, togglePendingIntent)
                        setOnClickPendingIntent(rowId, togglePendingIntent)
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

                        // Attach 1-tap toggle PendingIntent directly to check icon and row!
                        val toggleIntent = Intent(context, SynveroAppWidget::class.java).apply {
                            action = ACTION_TOGGLE_TASK
                            putExtra(EXTRA_ITEM_INDEX, i)
                        }
                        val togglePendingIntent = PendingIntent.getBroadcast(
                            context,
                            200 + i,
                            toggleIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        setOnClickPendingIntent(checkId, togglePendingIntent)
                        setOnClickPendingIntent(rowId, togglePendingIntent)
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
                put(JSONObject().put("title", "Drink Water").put("icon", "💧").put("done", false))
                put(JSONObject().put("title", "Workout").put("icon", "🏋️").put("done", false))
                put(JSONObject().put("title", "Read Book").put("icon", "📖").put("done", false))
                put(JSONObject().put("title", "Meditate").put("icon", "🧘").put("done", false))
                put(JSONObject().put("title", "Sleep Early").put("icon", "🌙").put("done", false))
            }
        }

        private fun getDefaultTasksJson(): JSONArray {
            return JSONArray().apply {
                put(JSONObject().put("title", "Complete Project").put("done", false))
                put(JSONObject().put("title", "Learn Java").put("done", false))
                put(JSONObject().put("title", "Design Portfolio").put("done", false))
                put(JSONObject().put("title", "Workout Plan").put("done", false))
            }
        }
    }
}
