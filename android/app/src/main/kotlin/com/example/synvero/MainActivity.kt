package com.example.synvero

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.example.synvero/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        } catch (e: Exception) {
            // Handled or already registered
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "updateWidgetData") {
                val title = call.argument<String>("title") ?: "✨ HabbitNova"
                val streak = call.argument<String>("streak") ?: "🔥 0d Streak"
                val overallPct = call.argument<String>("overallPct") ?: (call.argument<String>("percentageText") ?: "0%")
                val overallTotal = call.argument<Int>("overallTotal") ?: 0
                val overallDone = call.argument<Int>("overallDone") ?: 0

                val habitsCount = call.argument<String>("habitsCount") ?: "0 of 0"
                val habitsPct = call.argument<String>("habitsPct") ?: "0%"
                val habitsTotal = call.argument<Int>("habitsTotal") ?: 0
                val habitsDone = call.argument<Int>("habitsDone") ?: 0

                val tasksCount = call.argument<String>("tasksCount") ?: "0 of 0"
                val tasksPct = call.argument<String>("tasksPct") ?: "0%"
                val tasksTotal = call.argument<Int>("tasksTotal") ?: 0
                val tasksDone = call.argument<Int>("tasksDone") ?: 0

                val flip1 = call.argument<String>("flip1") ?: "⚡ Daily Focus: Keep crushing goals!"
                val flip2 = call.argument<String>("flip2") ?: "✨ $overallPct Completed — Tap to continue!"
                val flip3 = call.argument<String>("flip3") ?: "🔥 Streak Active! Consistency builds success ➔"

                val prefs = getSharedPreferences(SynveroAppWidget.PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().apply {
                    putString(SynveroAppWidget.KEY_TITLE, title)
                    putString(SynveroAppWidget.KEY_STREAK, streak)
                    putString(SynveroAppWidget.KEY_OVERALL_PCT, overallPct)
                    putInt(SynveroAppWidget.KEY_OVERALL_TOTAL, overallTotal)
                    putInt(SynveroAppWidget.KEY_OVERALL_DONE, overallDone)

                    putString(SynveroAppWidget.KEY_HABITS_COUNT, habitsCount)
                    putString(SynveroAppWidget.KEY_HABITS_PCT, habitsPct)
                    putInt(SynveroAppWidget.KEY_HABITS_TOTAL, habitsTotal)
                    putInt(SynveroAppWidget.KEY_HABITS_DONE, habitsDone)

                    putString(SynveroAppWidget.KEY_TASKS_COUNT, tasksCount)
                    putString(SynveroAppWidget.KEY_TASKS_PCT, tasksPct)
                    putInt(SynveroAppWidget.KEY_TASKS_TOTAL, tasksTotal)
                    putInt(SynveroAppWidget.KEY_TASKS_DONE, tasksDone)

                    putString(SynveroAppWidget.KEY_FLIP_1, flip1)
                    putString(SynveroAppWidget.KEY_FLIP_2, flip2)
                    putString(SynveroAppWidget.KEY_FLIP_3, flip3)
                    apply()
                }

                // Immediately refresh all active widgets on the home screen
                val appWidgetManager = AppWidgetManager.getInstance(this)
                val componentName = ComponentName(this, SynveroAppWidget::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
                for (id in appWidgetIds) {
                    SynveroAppWidget.updateAppWidget(this, appWidgetManager, id)
                }

                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
