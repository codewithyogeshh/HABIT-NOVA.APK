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
        const val KEY_LABEL = "widget_label"
        const val KEY_COUNT = "widget_count"
        const val KEY_PERCENTAGE = "widget_percentage"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val title = prefs.getString(KEY_TITLE, "HabbitNova") ?: "HabbitNova"
            val streak = prefs.getString(KEY_STREAK, "🔥 Active") ?: "🔥 Active"
            val label = prefs.getString(KEY_LABEL, "Today's Tasks") ?: "Today's Tasks"
            val count = prefs.getString(KEY_COUNT, "0 of 0 Done") ?: "0 of 0 Done"
            val percentage = prefs.getString(KEY_PERCENTAGE, "0%") ?: "0%"

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
                setTextViewText(R.id.widget_app_title, title)
                setTextViewText(R.id.widget_streak_badge, streak)
                setTextViewText(R.id.widget_habits_label, label)
                setTextViewText(R.id.widget_habits_count, count)
                setTextViewText(R.id.widget_percentage, percentage)
                setTextViewText(R.id.widget_action_text, "Tap to open HabbitNova ➔")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
