package com.example.synvero

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
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
import java.util.Random
import kotlin.math.sin

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.example.synvero/widget"
    private val ALARM_CHANNEL = "com.example.synvero/alarm"
    private val FOCUS_SOUND_CHANNEL = "com.example.synvero/focus_sounds"
    private val SHARE_CHANNEL = "com.example.synvero/share"

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null

    // Ambient Focus Audio generator
    private var focusAudioTrack: AudioTrack? = null
    private var focusSoundThread: Thread? = null
    @Volatile private var isFocusPlaying = false
    @Volatile private var focusVolume = 0.7f

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

        // 3. Focus Sounds Channel (Rain, Ocean, Forest, Cafe, White Noise)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOCUS_SOUND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playFocusSound" -> {
                    val soundType = call.argument<String>("type") ?: "rain"
                    val vol = (call.argument<Double>("volume") ?: 0.7).toFloat()
                    focusVolume = vol.coerceIn(0.0f, 1.0f)
                    startFocusSound(soundType)
                    result.success(true)
                }
                "stopFocusSound" -> {
                    stopFocusSound()
                    result.success(true)
                }
                "setFocusVolume" -> {
                    val vol = (call.argument<Double>("volume") ?: 0.7).toFloat()
                    focusVolume = vol.coerceIn(0.0f, 1.0f)
                    try {
                        focusAudioTrack?.setVolume(focusVolume)
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
        isFocusPlaying = true

        focusSoundThread = Thread {
            val sampleRate = 22050
            val minBufSize = AudioTrack.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )
            val bufferSize = if (minBufSize > 4096) minBufSize else 4096

            focusAudioTrack = AudioTrack(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build(),
                AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build(),
                bufferSize * 2,
                AudioTrack.MODE_STREAM,
                AudioManager.AUDIO_SESSION_ID_GENERATE
            )

            try {
                focusAudioTrack?.setVolume(focusVolume)
                focusAudioTrack?.play()
            } catch (e: Exception) {
                return@Thread
            }

            val random = Random()
            val buffer = ShortArray(bufferSize)
            var lastSample = 0.0
            var phase = 0.0
            val phaseInc = 2.0 * Math.PI * 0.15 / sampleRate // Slow 0.15Hz wave cycle

            while (isFocusPlaying) {
                for (i in 0 until bufferSize) {
                    val rawNoise = (random.nextDouble() * 2.0 - 1.0)
                    val sample: Double

                    when (type) {
                        "rain" -> {
                            // Pink noise with slight high-frequency filtering (soothing raindrops)
                            lastSample = 0.88 * lastSample + 0.12 * rawNoise
                            sample = lastSample * 0.35
                        }
                        "ocean" -> {
                            // Pink noise modulated by gentle 0.15 Hz sinusoidal wave (ocean tide)
                            lastSample = 0.92 * lastSample + 0.08 * rawNoise
                            val wave = (sin(phase) + 1.2) * 0.5
                            sample = lastSample * wave * 0.45
                            phase += phaseInc
                            if (phase > 2.0 * Math.PI) phase -= 2.0 * Math.PI
                        }
                        "forest" -> {
                            // Low wind breeze + subtle chirps
                            lastSample = 0.94 * lastSample + 0.06 * rawNoise
                            val chirp = if (random.nextInt(6000) == 0) sin(phase * 18.0) * 0.1 else 0.0
                            sample = (lastSample * 0.3) + chirp
                            phase += phaseInc
                        }
                        "cafe" -> {
                            // Warm filtered brown noise
                            lastSample = 0.95 * lastSample + 0.05 * rawNoise
                            sample = lastSample * 0.4
                        }
                        else -> {
                            // Smooth white noise
                            lastSample = 0.5 * lastSample + 0.5 * rawNoise
                            sample = lastSample * 0.25
                        }
                    }

                    val intSample = (sample * 32767.0).toInt().coerceIn(-32768, 32767)
                    buffer[i] = intSample.toShort()
                }

                if (!isFocusPlaying) break
                focusAudioTrack?.write(buffer, 0, bufferSize)
            }

            try {
                focusAudioTrack?.stop()
                focusAudioTrack?.release()
            } catch (e: Exception) {}
            focusAudioTrack = null
        }.apply {
            priority = Thread.MIN_PRIORITY
            start()
        }
    }

    private fun stopFocusSound() {
        isFocusPlaying = false
        focusSoundThread?.interrupt()
        focusSoundThread = null

        try {
            focusAudioTrack?.stop()
            focusAudioTrack?.release()
        } catch (e: Exception) {}
        focusAudioTrack = null
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
