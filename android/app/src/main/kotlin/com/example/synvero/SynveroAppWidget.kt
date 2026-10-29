package com.example.synvero

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

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
        const val KEY_TITLE = "widget_title"
        const val KEY_STREAK = "widget_streak"
        const val KEY_OVERALL_PCT = "widget_overall_pct"
        const val KEY_OVERALL_TOTAL = "widget_overall_total"
        const val KEY_OVERALL_DONE = "widget_overall_done"

        const val KEY_HABITS_COUNT = "widget_habits_count"
        const val KEY_HABITS_PCT = "widget_habits_pct"
        const val KEY_HABITS_TOTAL = "widget_habits_total"
        const val KEY_HABITS_DONE = "widget_habits_done"

        const val KEY_TASKS_COUNT = "widget_tasks_count"
        const val KEY_TASKS_PCT = "widget_tasks_pct"
        const val KEY_TASKS_TOTAL = "widget_tasks_total"
        const val KEY_TASKS_DONE = "widget_tasks_done"

        const val KEY_FLIP_1 = "widget_flip_1"
        const val KEY_FLIP_2 = "widget_flip_2"
        const val KEY_FLIP_3 = "widget_flip_3"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val title = prefs.getString(KEY_TITLE, "✨ HabbitNova") ?: "✨ HabbitNova"
            val streak = prefs.getString(KEY_STREAK, "🔥 0d Streak") ?: "🔥 0d Streak"
            val overallPct = prefs.getString(KEY_OVERALL_PCT, "0%") ?: "0%"
            val overallTotal = prefs.getInt(KEY_OVERALL_TOTAL, 0)
            val overallDone = prefs.getInt(KEY_OVERALL_DONE, 0)

            val habitsCount = prefs.getString(KEY_HABITS_COUNT, "0 of 0") ?: "0 of 0"
            val habitsPct = prefs.getString(KEY_HABITS_PCT, "0%") ?: "0%"
            val habitsTotal = prefs.getInt(KEY_HABITS_TOTAL, 0)
            val habitsDone = prefs.getInt(KEY_HABITS_DONE, 0)

            val tasksCount = prefs.getString(KEY_TASKS_COUNT, "0 of 0") ?: "0 of 0"
            val tasksPct = prefs.getString(KEY_TASKS_PCT, "0%") ?: "0%"
            val tasksTotal = prefs.getInt(KEY_TASKS_TOTAL, 0)
            val tasksDone = prefs.getInt(KEY_TASKS_DONE, 0)

            val flip1 = prefs.getString(KEY_FLIP_1, "⚡ Daily Focus: Keep crushing goals!")
                ?: "⚡ Daily Focus: Keep crushing goals!"
            val flip2 = prefs.getString(KEY_FLIP_2, "✨ $overallPct Completed — Tap to continue!")
                ?: "✨ $overallPct Completed — Tap to continue!"
            val flip3 = prefs.getString(KEY_FLIP_3, "🔥 Streak Active! Consistency builds success ➔")
                ?: "🔥 Streak Active! Consistency builds success ➔"

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
                setTextViewText(R.id.widget_app_title, title)
                setTextViewText(R.id.widget_streak_badge, streak)
                setTextViewText(R.id.widget_overall_pct, overallPct)
                setProgressBar(
                    R.id.widget_overall_bar,
                    overallTotal.coerceAtLeast(1),
                    overallDone,
                    false
                )

                // Habits Section
                setTextViewText(R.id.widget_habits_pct, habitsPct)
                setTextViewText(R.id.widget_habits_count, habitsCount)
                setProgressBar(
                    R.id.widget_habits_bar,
                    habitsTotal.coerceAtLeast(1),
                    habitsDone,
                    false
                )

                // Tasks Section
                setTextViewText(R.id.widget_tasks_pct, tasksPct)
                setTextViewText(R.id.widget_tasks_count, tasksCount)
                setProgressBar(
                    R.id.widget_tasks_bar,
                    tasksTotal.coerceAtLeast(1),
                    tasksDone,
                    false
                )

                // Animated Flipper
                setTextViewText(R.id.widget_flip_msg1, flip1)
                setTextViewText(R.id.widget_flip_msg2, flip2)
                setTextViewText(R.id.widget_flip_msg3, flip3)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
