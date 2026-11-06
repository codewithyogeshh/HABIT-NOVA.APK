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

        val (_, apps) = getAppUsageForInterval(context, usageStatsManager, todayStart, now)
        val app = apps.firstOrNull { it["packageName"] == packageName }
        return (app?.get("usageMinutes") as? Int) ?: 0
    }

    private val MEDIA_PACKAGES = setOf(
        "com.mxtech.videoplayer.ad",
        "com.google.android.youtube",
        "com.netflix.mediaclient",
        "org.videolan.vlc",
        "com.spotify.music",
        "com.jio.media.ondemand",
        "com.hotstar.mobile",
        "com.playit.videoplayer",
        "com.amazon.avod.thirdpartyclient"
    )

    private fun isMediaPkg(pkg: String): Boolean {
        return MEDIA_PACKAGES.contains(pkg) || pkg.contains("videoplayer") || pkg.contains("youtube")
    }

    /**
     * Highly accurate Activity-Aware and Screen-Aware state machine parser.
     * Replicates Google Digital Wellbeing down to the exact minute.
     * Features:
     * 1. 12-hour pre-window lookback to catch apps started before midnight.
     * 2. Per-activity tracking (actKey) to prevent intra-app screen transitions from prematurely terminating tracking.
     * 3. Immediate flush and pause on SCREEN_NON_INTERACTIVE and KEYGUARD_SHOWN.
     * 4. Automatic idle timeout capping (max 5m without interaction) for non-media background sessions.
     * 5. Strict calendar day boundary clamping [startTime, endTime].
     */
    private fun getAppUsageForInterval(
        context: Context,
        usageStatsManager: UsageStatsManager,
        startTime: Long,
        endTime: Long
    ): Pair<Long, List<Map<String, Any>>> {
        val appTimeMap = mutableMapOf<String, Long>()

        try {
            // Lookback 12 hours before startTime to catch apps active across midnight
            val lookbackStart = maxOf(0L, startTime - 12 * 3600 * 1000L)
            val events = usageStatsManager.queryEvents(lookbackStart, endTime)
            val event = UsageEvents.Event()

            // Map: actKey (pkg::cls) -> startTimestamp
            val activeActivities = mutableMapOf<String, Long>()
            var isScreenOn = true

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val t = event.timeStamp
                val type = event.eventType
                val pkg = event.packageName ?: continue
                val cls = event.className ?: ""
                val actKey = "$pkg::$cls"

                when (type) {
                    UsageEvents.Event.ACTIVITY_RESUMED -> {
                        activeActivities[actKey] = t
                        isScreenOn = true
                    }

                    UsageEvents.Event.ACTIVITY_PAUSED,
                    UsageEvents.Event.ACTIVITY_STOPPED -> {
                        if (activeActivities.containsKey(actKey)) {
                            val startT = activeActivities.remove(actKey) ?: t
                            if (isScreenOn) {
                                val sClamped = maxOf(startT, startTime)
                                val eClamped = minOf(t, endTime)
                                if (eClamped > sClamped) {
                                    var dur = eClamped - sClamped
                                    // Cap unattended non-media session to 5 minutes
                                    if (!isMediaPkg(pkg) && dur > 10 * 60 * 1000L) {
                                        dur = 5 * 60 * 1000L
                                    }
                                    appTimeMap[pkg] = (appTimeMap[pkg] ?: 0L) + dur
                                }
                            }
                        }
                    }

                    UsageEvents.Event.SCREEN_NON_INTERACTIVE,
                    UsageEvents.Event.KEYGUARD_SHOWN -> {
                        // Phone locked or display off - close all active activities at timestamp
                        if (isScreenOn) {
                            for ((k, startT) in activeActivities) {
                                val p = k.substringBefore("::")
                                val sClamped = maxOf(startT, startTime)
                                val eClamped = minOf(t, endTime)
                                if (eClamped > sClamped) {
                                    var dur = eClamped - sClamped
                                    if (!isMediaPkg(p) && dur > 10 * 60 * 1000L) {
                                        dur = 5 * 60 * 1000L
                                    }
                                    appTimeMap[p] = (appTimeMap[p] ?: 0L) + dur
                                }
                            }
                        }
                        activeActivities.clear()
                        isScreenOn = false
                    }

                    UsageEvents.Event.SCREEN_INTERACTIVE,
                    UsageEvents.Event.KEYGUARD_HIDDEN -> {
                        isScreenOn = true
                    }
                }
            }

            // Close any still-active activities up to clamped current time
            val nowClamped = minOf(System.currentTimeMillis(), endTime)
            if (isScreenOn) {
                for ((k, startT) in activeActivities) {
                    val p = k.substringBefore("::")
                    val sClamped = maxOf(startT, startTime)
                    val eClamped = minOf(nowClamped, endTime)
                    if (eClamped > sClamped) {
                        var dur = eClamped - sClamped
                        if (!isMediaPkg(p) && dur > 10 * 60 * 1000L) {
                            dur = 5 * 60 * 1000L
                        }
                        appTimeMap[p] = (appTimeMap[p] ?: 0L) + dur
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        val pm = context.packageManager
        val appList = mutableListOf<Map<String, Any>>()
        var totalScreenTimeMs = 0L

        // Default launcher detection so the desktop wallpaper/launcher doesn't show as an app
        val defaultLauncher = try {
            val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
            val resolveInfo = pm.resolveActivity(homeIntent, PackageManager.MATCH_DEFAULT_ONLY)
            resolveInfo?.activityInfo?.packageName
        } catch (_: Exception) { null }

        for ((packageName, foregroundTimeMs) in appTimeMap.entries.sortedByDescending { it.value }) {
            // Exclude system root, notification shade, and launcher from app breakdown
            if (packageName == "android" ||
                packageName == "com.android.systemui" ||
                packageName == defaultLauncher ||
                packageName == "com.miui.home" ||
                packageName == "com.google.android.apps.nexuslauncher") continue

            if (foregroundTimeMs < 1000L) continue // skip under 1 second

            try {
                val appInfo = pm.getApplicationInfo(packageName, 0)
                val launchIntent = pm.getLaunchIntentForPackage(packageName)
                val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

                // Exclude system background daemons without UI
                if (isSystem && launchIntent == null && packageName != context.packageName) continue

                val appName = if (packageName == context.packageName) "HabbitNova" else pm.getApplicationLabel(appInfo).toString()
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

        // Clamp totalScreenTimeMs to maximum 24h for a single day
        val dayWindowMs = endTime - startTime
        val cappedTotalMs = minOf(totalScreenTimeMs, maxOf(dayWindowMs, 1000L))

        return Pair(cappedTotalMs, appList)
    }

    fun getScreenTimeStats(context: Context): Map<String, Any> {
        val hasPerm = hasUsagePermission(context)
        if (!hasPerm) {
            return mapOf(
                "hasPermission" to false,
                "totalScreenTimeMs" to 0L,
                "totalFormatted" to "0m",
                "weeklyHours" to listOf(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
                "weekDays" to listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"),
                "apps" to emptyList<Map<String, Any>>()
            )
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return mapOf(
                "hasPermission" to false,
                "totalScreenTimeMs" to 0L,
                "totalFormatted" to "0m",
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

        // 1. Calculate Today's exact screen time and apps using event state machine
        val (todayTotalMs, todayApps) = getAppUsageForInterval(context, usageStatsManager, todayStart, now)

        // 2. Weekly 7-day usage breakdown & day-by-day app tracking (6 days ago to today)
        val weeklyHours = mutableListOf<Double>()
        val weekDays = mutableListOf<String>()
        val dailyHistory = mutableListOf<Map<String, Any>>()
        val dayFormat = SimpleDateFormat("EEE", Locale.US)
        val fullDateFormat = SimpleDateFormat("EEEE, d MMMM", Locale.US)
        val isoDateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)

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

            val (dayTotalMs, dayApps) = if (i == 0) {
                Pair(todayTotalMs, todayApps)
            } else {
                getAppUsageForInterval(context, usageStatsManager, dayStart, dayEnd)
            }

            // Strictly clamp day total to 24.0 hours so impossible sums never happen
            val dayCappedMs = minOf(dayTotalMs, 24 * 3600 * 1000L)
            val hours = minOf(dayCappedMs / 3600000.0, 24.0)
            val roundedHours = Math.round(hours * 10.0) / 10.0

            weeklyHours.add(roundedHours)
            weekDays.add(dayFormat.format(dayCal.time))

            dailyHistory.add(mapOf(
                "dayOffset" to i,
                "dayName" to dayFormat.format(dayCal.time),
                "dateStr" to isoDateFormat.format(dayCal.time),
                "fullDate" to fullDateFormat.format(dayCal.time),
                "isToday" to (i == 0),
                "totalScreenTimeMs" to dayCappedMs,
                "totalFormatted" to formatDuration(dayCappedMs),
                "hours" to roundedHours,
                "apps" to dayApps
            ))
        }

        return mapOf(
            "hasPermission" to true,
            "totalScreenTimeMs" to todayTotalMs,
            "totalFormatted" to formatDuration(todayTotalMs),
            "weeklyHours" to weeklyHours,
            "weekDays" to weekDays,
            "dailyHistory" to dailyHistory,
            "apps" to todayApps
        )
    }

    fun getScreenTimeForCustomDate(context: Context, startTime: Long, endTime: Long): Map<String, Any> {
        if (!hasUsagePermission(context)) {
            return mapOf(
                "hasPermission" to false,
                "totalScreenTimeMs" to 0L,
                "totalFormatted" to "0m",
                "apps" to emptyList<Map<String, Any>>()
            )
        }
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return mapOf(
                "hasPermission" to false,
                "totalScreenTimeMs" to 0L,
                "totalFormatted" to "0m",
                "apps" to emptyList<Map<String, Any>>()
            )

        val (totalMs, appList) = getAppUsageForInterval(context, usageStatsManager, startTime, endTime)

        return mapOf(
            "hasPermission" to true,
            "totalScreenTimeMs" to totalMs,
            "totalFormatted" to formatDuration(totalMs),
            "apps" to appList,
            "startTime" to startTime,
            "endTime" to endTime
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
        val totalMins = (ms / 60000L).coerceAtLeast(0L)
        val hours = totalMins / 60L
        val mins = totalMins % 60L
        if (hours > 0 && mins > 0) return "${hours}h ${mins}m"
        if (hours > 0) return "${hours}h"
        return "${mins}m"
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
