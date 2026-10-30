package com.example.synvero

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.example.synvero/widget"
    private val ALARM_CHANNEL = "com.example.synvero/alarm"
    private val FOCUS_SOUND_CHANNEL = "com.example.synvero/focus_sounds"
    private val SHARE_CHANNEL = "com.example.synvero/share"

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null

    // Ambient Focus Real Field Recording Player
    private var focusMediaPlayer: MediaPlayer? = null
    @Volatile private var focusVolume = 0.8f

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        } catch (e: Exception) {
            // Handled or already registered
        }

        // 1. Alarm Audio & Vibration Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAlarmRing" -> {
                    startAlarm()
                    result.success(true)
                }
                "stopAlarmRing" -> {
                    stopAlarm()
                    result.success(true)
                }
                "isAlarmRinging" -> {
                    result.success(mediaPlayer?.isPlaying == true)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Widget Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "updateWidgetData") {
                val username = call.argument<String>("username") ?: "Yogesh"
                val streak = call.argument<String>("streak") ?: "1d"

                val habitsCount = call.argument<String>("habitsCount") ?: "5 of 5"
                val habitsTotal = call.argument<Int>("habitsTotal") ?: 5
                val habitsDone = call.argument<Int>("habitsDone") ?: 5
                val habitsJson = call.argument<String>("habitsJson")

                val tasksCount = call.argument<String>("tasksCount") ?: "2 of 4"
                val tasksTotal = call.argument<Int>("tasksTotal") ?: 4
                val tasksDone = call.argument<Int>("tasksDone") ?: 2
                val tasksJson = call.argument<String>("tasksJson")

                val bannerTitle = call.argument<String>("bannerTitle") ?: "You're doing great!"
                val bannerSubtitle = call.argument<String>("bannerSubtitle") ?: "Discipline today builds the freedom of tomorrow."

                val prefs = getSharedPreferences(SynveroAppWidget.PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().apply {
                    putString(SynveroAppWidget.KEY_USERNAME, username)
                    putString(SynveroAppWidget.KEY_STREAK, streak)

                    putString(SynveroAppWidget.KEY_HABITS_COUNT, habitsCount)
                    putInt(SynveroAppWidget.KEY_HABITS_TOTAL, habitsTotal)
                    putInt(SynveroAppWidget.KEY_HABITS_DONE, habitsDone)
                    if (habitsJson != null) putString(SynveroAppWidget.KEY_HABITS_JSON, habitsJson)

                    putString(SynveroAppWidget.KEY_TASKS_COUNT, tasksCount)
                    putInt(SynveroAppWidget.KEY_TASKS_TOTAL, tasksTotal)
                    putInt(SynveroAppWidget.KEY_TASKS_DONE, tasksDone)
                    if (tasksJson != null) putString(SynveroAppWidget.KEY_TASKS_JSON, tasksJson)

                    putString(SynveroAppWidget.KEY_BANNER_TITLE, bannerTitle)
                    putString(SynveroAppWidget.KEY_BANNER_SUBTITLE, bannerSubtitle)
                    apply()
                }

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

        // 3. Focus Sounds Channel (Real Natural Recordings: Rain, Ocean Waves, Birds, Cafe, Campfire)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOCUS_SOUND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playFocusSound" -> {
                    val soundType = call.argument<String>("type") ?: "rain"
                    val vol = (call.argument<Double>("volume") ?: 0.8).toFloat()
                    focusVolume = vol.coerceIn(0.0f, 1.0f)
                    startFocusSound(soundType)
                    result.success(true)
                }
                "stopFocusSound" -> {
                    stopFocusSound()
                    result.success(true)
                }
                "setFocusVolume" -> {
                    val vol = (call.argument<Double>("volume") ?: 0.8).toFloat()
                    focusVolume = vol.coerceIn(0.0f, 1.0f)
                    try {
                        focusMediaPlayer?.setVolume(focusVolume, focusVolume)
                    } catch (e: Exception) {}
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 4. Native Share Intent Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareText") {
                val text = call.argument<String>("text") ?: ""
                val title = call.argument<String>("title") ?: "Share My Progress"
                try {
                    val sendIntent: Intent = Intent().apply {
                        action = Intent.ACTION_SEND
                        putExtra(Intent.EXTRA_TEXT, text)
                        type = "text/plain"
                    }
                    val shareIntent = Intent.createChooser(sendIntent, title)
                    startActivity(shareIntent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SHARE_ERROR", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startFocusSound(type: String) {
        stopFocusSound()
        try {
            val resId = when (type.lowercase()) {
                "rain" -> R.raw.focus_rain
                "ocean", "waves" -> R.raw.focus_ocean
                "forest", "birds" -> R.raw.focus_forest
                "cafe" -> R.raw.focus_cafe
                "campfire" -> R.raw.focus_campfire
                else -> R.raw.focus_rain
            }

            focusMediaPlayer = MediaPlayer.create(this, resId)?.apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                isLooping = true
                setVolume(focusVolume, focusVolume)
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopFocusSound() {
        try {
            focusMediaPlayer?.stop()
            focusMediaPlayer?.release()
        } catch (e: Exception) {}
        focusMediaPlayer = null
    }

    private fun startAlarm() {
        try {
            if (mediaPlayer?.isPlaying == true) return

            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@MainActivity, alarmUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }

            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

            val pattern = longArrayOf(0, 800, 400, 800, 400, 1000)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopAlarm() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
        } catch (e: Exception) {}
        mediaPlayer = null

        try {
            vibrator?.cancel()
        } catch (e: Exception) {}
        vibrator = null
    }

    override fun onDestroy() {
        stopFocusSound()
        stopAlarm()
        super.onDestroy()
    }
}
