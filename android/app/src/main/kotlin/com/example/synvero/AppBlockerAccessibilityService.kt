package com.example.synvero

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast

class AppBlockerAccessibilityService : AccessibilityService() {
    private var lastBlockedPackage = ""
    private var lastBlockedTime = 0L
    private val handler = Handler(Looper.getMainLooper())

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString() ?: return
        if (packageName == applicationContext.packageName ||
            packageName == "com.android.launcher" ||
            packageName == "com.google.android.apps.nexuslauncher" ||
            packageName.contains("launcher") ||
            packageName.contains("systemui") ||
            packageName == "android") {
            return
        }

        val limitMinutes = UsageStatsHelper.getAppLimitMinutes(applicationContext, packageName)
        if (limitMinutes == null || limitMinutes <= 0) {
            return
        }

        val usedMinutes = UsageStatsHelper.getPackageUsageMinutesToday(applicationContext, packageName)
        if (usedMinutes >= limitMinutes) {
            val now = System.currentTimeMillis()
            if (packageName == lastBlockedPackage && (now - lastBlockedTime) < 1500L) {
                return
            }
            lastBlockedPackage = packageName
            lastBlockedTime = now

            // 1. Immediately minimize the blocked app back to home screen
            performGlobalAction(GLOBAL_ACTION_HOME)

            // 2. Fetch friendly app name
            val appName = try {
                val pm = applicationContext.packageManager
                val appInfo = pm.getApplicationInfo(packageName, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (_: Exception) {
                packageName
            }

            // 3. Show a clear toast warning to user
            handler.post {
                Toast.makeText(
                    applicationContext,
                    "🚫 $appName ब्लॉक केले आहे! Daily limit reached (${limitMinutes}m)",
                    Toast.LENGTH_LONG
                ).show()
            }

            // 4. Launch HabbitNova with the Blocked Shield dialog
            handler.postDelayed({
                try {
                    val intent = Intent(applicationContext, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        putExtra("blocked_package", packageName)
                        putExtra("blocked_app_name", appName)
                        putExtra("blocked_limit_mins", limitMinutes)
                        putExtra("blocked_used_mins", usedMinutes)
                    }
                    startActivity(intent)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }, 120)
        }
    }

    override fun onInterrupt() {}
}

