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
                val title = call.argument<String>("title") ?: "HabbitNova"
                val streak = call.argument<String>("streak") ?: "🔥 Active"
                val label = call.argument<String>("label") ?: "Today's Progress"
                val countText = call.argument<String>("countText") ?: "0 of 0 Done"
                val percentageText = call.argument<String>("percentageText") ?: "0%"

                val prefs = getSharedPreferences(SynveroAppWidget.PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().apply {
                    putString(SynveroAppWidget.KEY_TITLE, title)
                    putString(SynveroAppWidget.KEY_STREAK, streak)
                    putString(SynveroAppWidget.KEY_LABEL, label)
                    putString(SynveroAppWidget.KEY_COUNT, countText)
                    putString(SynveroAppWidget.KEY_PERCENTAGE, percentageText)
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
