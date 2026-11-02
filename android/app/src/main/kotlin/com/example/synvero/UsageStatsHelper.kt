package com.example.synvero

import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.TrafficStats
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

object UsageStatsHelper {
    private const val PREFS_LIMITS = "synvero_app_limits_prefs"
    private const val KEY_PREFIX = "limit_"

    fun hasUsagePermission(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun openUsageSettings(context: Context) {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
    }

    fun isAccessibilityEnabled(context: Context): Boolean {
        val expectedService = "${context.packageName}/${AppBlockerAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabledServices)
        while (splitter.hasNext()) {
            val component = splitter.next()
            if (component.equals(expectedService, ignoreCase = true) ||
                component.contains("AppBlockerAccessibilityService") ||
                component.contains(".AppBlockerAccessibilityService")) {
                return true
            }
        }
        return false
    }

    fun openAccessibilitySettings(context: Context) {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
    }

    fun cleanupCorruptedPrefs(context: Context) {
        try {
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val editor = flutterPrefs.edit()
            var hasChanges = false
            for (key in flutterPrefs.all.keys) {
                if (key.startsWith("flutter.synvero_app_usage_limit_mins_")) {
                    editor.remove(key)
                    hasChanges = true
                }
            }
            if (hasChanges) {
                editor.apply()
            }
        } catch (_: Exception) {}
    }

    fun setAppLimit(context: Context, packageName: String, appName: String, minutes: Int) {
        val prefs = context.getSharedPreferences(PREFS_LIMITS, Context.MODE_PRIVATE)
        prefs.edit().apply {
            putInt(KEY_PREFIX + packageName, minutes)
            if (appName.isNotEmpty()) {
                putInt(KEY_PREFIX + appName, minutes)
            }
            apply()
        }
    }

    fun removeAppLimit(context: Context, packageName: String, appName: String) {
        val prefs = context.getSharedPreferences(PREFS_LIMITS, Context.MODE_PRIVATE)
        prefs.edit().apply {
            remove(KEY_PREFIX + packageName)
            if (appName.isNotEmpty()) {
                remove(KEY_PREFIX + appName)
            }
            apply()
        }
    }

    fun getAppLimitMinutes(context: Context, packageName: String): Int? {
        val prefs = context.getSharedPreferences(PREFS_LIMITS, Context.MODE_PRIVATE)
        val limit = prefs.getInt(KEY_PREFIX + packageName, -1)
        if (limit > 0) return limit

        try {
            val pm = context.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            val appName = pm.getApplicationLabel(appInfo).toString()
            val nameLimit = prefs.getInt(KEY_PREFIX + appName, -1)
            if (nameLimit > 0) return nameLimit
        } catch (_: Exception) {}

        return null
    }

    fun getAllLimits(context: Context): Map<String, Int> {
        val result = mutableMapOf<String, Int>()
        val prefs = context.getSharedPreferences(PREFS_LIMITS, Context.MODE_PRIVATE)
        for ((key, value) in prefs.all) {
            if (key.startsWith(KEY_PREFIX) && value is Int && value > 0) {
                val cleanKey = key.removePrefix(KEY_PREFIX)
                result[cleanKey] = value
            }
        }
        return result
    }

    fun getPackageUsageMinutesToday(context: Context, packageName: String): Int {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return 0

        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val todayStart = cal.timeInMillis
        val now = System.currentTimeMillis()

        var totalMs = 0L
        try {
            val events = usageStatsManager.queryEvents(todayStart, now)
            val event = UsageEvents.Event()
            var fgStart = 0L

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.packageName == packageName) {
                    val t = event.timeStamp
                    val type = event.eventType
                    if (type == UsageEvents.Event.ACTIVITY_RESUMED || type == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                        fgStart = t
                    } else if (type == UsageEvents.Event.ACTIVITY_PAUSED ||
                        type == UsageEvents.Event.ACTIVITY_STOPPED ||
                        type == UsageEvents.Event.MOVE_TO_BACKGROUND) {
                        if (fgStart > 0 && t > fgStart) {
                            totalMs += (t - fgStart)
                            fgStart = 0L
                        }
                    }
                }
            }
            if (fgStart > 0 && now > fgStart) {
                totalMs += (now - fgStart)
            }
        } catch (_: Exception) {}

        if (totalMs == 0L) {
            try {
                val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, todayStart, now)
                for (st in stats) {
                    if (st.packageName == packageName && st.lastTimeUsed >= todayStart) {
                        totalMs = st.totalTimeInForeground
                        break
                    }
                }
            } catch (_: Exception) {}
        }

        return (totalMs / 60000L).toInt()
    }

    fun getScreenTimeStats(context: Context): Map<String, Any> {
        val hasPerm = hasUsagePermission(context)
        if (!hasPerm) {
            return mapOf(
                "hasPermission" to false,
                "totalScreenTimeMs" to 0L,
                "totalFormatted" to "0 minutes",
                "weeklyHours" to listOf(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
                "weekDays" to listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"),
                "apps" to emptyList<Map<String, Any>>()
            )
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return mapOf(
                "hasPermission" to false,
                "totalScreenTimeMs" to 0L,
                "totalFormatted" to "0 minutes",
                "weeklyHours" to listOf(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
                "weekDays" to listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"),
                "apps" to emptyList<Map<String, Any>>()
            )

        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val todayStart = cal.timeInMillis
        val now = System.currentTimeMillis()

        val appForegroundStart = mutableMapOf<String, Long>()
        val appTotalTime = mutableMapOf<String, Long>()

        try {
            val events = usageStatsManager.queryEvents(todayStart, now)
            val event = UsageEvents.Event()

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val pkg = event.packageName ?: continue
                val time = event.timeStamp
                val type = event.eventType

                if (type == UsageEvents.Event.ACTIVITY_RESUMED || type == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    appForegroundStart[pkg] = time
                } else if (type == UsageEvents.Event.ACTIVITY_PAUSED ||
                    type == UsageEvents.Event.ACTIVITY_STOPPED ||
                    type == UsageEvents.Event.MOVE_TO_BACKGROUND) {
                    val start = appForegroundStart.remove(pkg)
                    if (start != null && time > start) {
                        appTotalTime[pkg] = (appTotalTime[pkg] ?: 0L) + (time - start)
                    }
                }
            }

            for ((pkg, start) in appForegroundStart) {
                if (now > start) {
                    appTotalTime[pkg] = (appTotalTime[pkg] ?: 0L) + (now - start)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Fallback to queryUsageStats if queryEvents returned empty
        if (appTotalTime.isEmpty()) {
            try {
                val statsList = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, todayStart, now)
                for (stat in statsList) {
                    if (stat.totalTimeInForeground > 0 && stat.lastTimeUsed >= todayStart) {
                        appTotalTime[stat.packageName] = stat.totalTimeInForeground
                    }
                }
            } catch (_: Exception) {}
        }

        val pm = context.packageManager
        val appList = mutableListOf<Map<String, Any>>()
        var totalScreenTimeMs = 0L

        for ((packageName, foregroundTimeMs) in appTotalTime.entries.sortedByDescending { it.value }) {
            if (foregroundTimeMs < 1000L) continue // skip under 1 second
            if (packageName == "android" ||
                packageName == "com.android.systemui" ||
                packageName == context.packageName) continue

            try {
                val appInfo = pm.getApplicationInfo(packageName, 0)
                val launchIntent = pm.getLaunchIntentForPackage(packageName)
                val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

                // Filter out system backend processes that have no user UI
                if (isSystem && launchIntent == null) continue

                val appName = pm.getApplicationLabel(appInfo).toString()
                totalScreenTimeMs += foregroundTimeMs
                val usageMins = (foregroundTimeMs / 60000L).toInt()

                appList.add(mapOf(
                    "packageName" to packageName,
                    "appName" to appName,
                    "category" to inferCategory(packageName, appName),
                    "usageMinutes" to usageMins,
                    "usageTimeMs" to foregroundTimeMs,
                    "durationFormatted" to formatDuration(foregroundTimeMs)
                ))
            } catch (_: PackageManager.NameNotFoundException) {}
        }

        // Weekly 7-day usage chart (Monday to Sunday)
        val weeklyHours = mutableListOf<Double>()
        val weekDays = mutableListOf<String>()
        val dayFormat = SimpleDateFormat("EEE", Locale.US)

        for (i in 6 downTo 0) {
            val dayCal = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, -i)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val dayStart = dayCal.timeInMillis
            val dayEnd = if (i == 0) now else dayStart + 86400000L

            var dayTotalMs = 0L
            try {
                val dayEvents = usageStatsManager.queryEvents(dayStart, dayEnd)
                val dayStarts = mutableMapOf<String, Long>()
                val dayEv = UsageEvents.Event()

                while (dayEvents.hasNextEvent()) {
                    dayEvents.getNextEvent(dayEv)
                    val pkg = dayEv.packageName ?: continue
                    if (pkg == "android" || pkg == "com.android.systemui" || pkg == context.packageName) continue
                    val t = dayEv.timeStamp
                    val type = dayEv.eventType

                    if (type == UsageEvents.Event.ACTIVITY_RESUMED || type == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                        dayStarts[pkg] = t
                    } else if (type == UsageEvents.Event.ACTIVITY_PAUSED ||
                        type == UsageEvents.Event.ACTIVITY_STOPPED ||
                        type == UsageEvents.Event.MOVE_TO_BACKGROUND) {
                        val s = dayStarts.remove(pkg)
                        if (s != null && t > s) {
                            dayTotalMs += (t - s)
                        }
                    }
                }
            } catch (_: Exception) {}

            val hours = (dayTotalMs / 3600000.0)
            weeklyHours.add(Math.round(hours * 10.0) / 10.0)
            weekDays.add(dayFormat.format(dayCal.time))
        }

        return mapOf(
            "hasPermission" to true,
            "totalScreenTimeMs" to totalScreenTimeMs,
            "totalFormatted" to formatDuration(totalScreenTimeMs),
            "weeklyHours" to weeklyHours,
            "weekDays" to weekDays,
            "apps" to appList
        )
    }

    fun getDataUsageStats(context: Context): Map<String, Any> {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val todayStart = cal.timeInMillis
        val now = System.currentTimeMillis()

        var totalBytes = 0L
        val appDataList = mutableListOf<Map<String, Any>>()
        val pm = context.packageManager

        val networkStatsManager = context.getSystemService(Context.NETWORK_STATS_SERVICE) as? NetworkStatsManager
        if (networkStatsManager != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val mobileSummary = networkStatsManager.querySummaryForDevice(
                    ConnectivityManager.TYPE_MOBILE,
                    null,
                    todayStart,
                    now
                )
                totalBytes += mobileSummary.rxBytes + mobileSummary.txBytes
            } catch (_: Exception) {}

            try {
                val wifiSummary = networkStatsManager.querySummaryForDevice(
                    ConnectivityManager.TYPE_WIFI,
                    null,
                    todayStart,
                    now
                )
                totalBytes += wifiSummary.rxBytes + wifiSummary.txBytes
            } catch (_: Exception) {}

            val uidBytesMap = mutableMapOf<Int, Long>()
            try {
                val wifiStats = networkStatsManager.querySummary(
                    ConnectivityManager.TYPE_WIFI,
                    null,
                    todayStart,
                    now
                )
                val bucket = NetworkStats.Bucket()
                while (wifiStats.hasNextBucket()) {
                    wifiStats.getNextBucket(bucket)
                    val uid = bucket.uid
                    if (uid > 1000) {
                        uidBytesMap[uid] = (uidBytesMap[uid] ?: 0L) + (bucket.rxBytes + bucket.txBytes)
                    }
                }
            } catch (_: Exception) {}

            try {
                val mobileStats = networkStatsManager.querySummary(
                    ConnectivityManager.TYPE_MOBILE,
                    null,
                    todayStart,
                    now
                )
                val bucket = NetworkStats.Bucket()
                while (mobileStats.hasNextBucket()) {
                    mobileStats.getNextBucket(bucket)
                    val uid = bucket.uid
                    if (uid > 1000) {
                        uidBytesMap[uid] = (uidBytesMap[uid] ?: 0L) + (bucket.rxBytes + bucket.txBytes)
                    }
                }
            } catch (_: Exception) {}

            for ((uid, bytes) in uidBytesMap.entries.sortedByDescending { it.value }) {
                if (bytes < 1024 * 50) continue // Skip under 50 KB
                val packages = pm.getPackagesForUid(uid) ?: continue
                for (pkg in packages) {
                    try {
                        val appInfo = pm.getApplicationInfo(pkg, 0)
                        val appName = pm.getApplicationLabel(appInfo).toString()
                        appDataList.add(mapOf(
                            "packageName" to pkg,
                            "appName" to appName,
                            "category" to inferCategory(pkg, appName),
                            "bytes" to bytes,
                            "usageFormatted" to formatBytes(bytes)
                        ))
                        break
                    } catch (_: Exception) {}
                }
            }
        }

        // Fallback using TrafficStats if device query was empty or restricted
        if (totalBytes <= 0L) {
            val rx = TrafficStats.getTotalRxBytes()
            val tx = TrafficStats.getTotalTxBytes()
            if (rx != TrafficStats.UNSUPPORTED.toLong() && tx != TrafficStats.UNSUPPORTED.toLong() && (rx + tx) > 0L) {
                totalBytes = rx + tx
            }
        }

        val totalStr = if (totalBytes > 0) "${formatBytes(totalBytes)} today" else "0 MB today"

        return mapOf(
            "totalBytes" to totalBytes,
            "totalFormatted" to totalStr,
            "apps" to appDataList
        )
    }

    fun formatDuration(ms: Long): String {
        val totalMins = ms / 60000L
        val hours = totalMins / 60
        val mins = totalMins % 60
        if (hours > 0 && mins > 0) return "$hours hour${if (hours > 1) "s" else ""}, $mins minute${if (mins > 1) "s" else ""}"
        if (hours > 0) return "$hours hour${if (hours > 1) "s" else ""}"
        if (mins > 0) return "$mins minute${if (mins > 1) "s" else ""}"
        return "< 1 minute"
    }

    fun formatBytes(bytes: Long): String {
        if (bytes < 1024) return "$bytes B"
        val kb = bytes / 1024.0
        if (kb < 1024) return "${Math.round(kb * 10.0) / 10.0} KB"
        val mb = kb / 1024.0
        if (mb < 1024) return "${Math.round(mb * 10.0) / 10.0} MB"
        val gb = mb / 1024.0
        return "${Math.round(gb * 100.0) / 100.0} GB"
    }

    private fun inferCategory(packageName: String, appName: String): String {
        val low = (packageName + appName).lowercase()
        return when {
            low.contains("instagram") || low.contains("facebook") || low.contains("snapchat") || low.contains("twitter") || low.contains("tiktok") -> "Social Media"
            low.contains("youtube") || low.contains("netflix") || low.contains("prime") || low.contains("spotify") || low.contains("hotstar") -> "Entertainment & Video"
            low.contains("whatsapp") || low.contains("telegram") || low.contains("message") || low.contains("signal") -> "Communication"
            low.contains("chrome") || low.contains("browser") || low.contains("firefox") || low.contains("opera") -> "Web Browsing"
            low.contains("study") || low.contains("habit") || low.contains("synvero") || low.contains("focus") || low.contains("todo") || low.contains("notion") -> "Productivity & Focus"
            low.contains("game") || low.contains("pubg") || low.contains("freefire") -> "Gaming"
            else -> "Apps & Tools"
        }
    }
}

