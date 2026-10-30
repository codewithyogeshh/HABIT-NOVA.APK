import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing Digital Wellbeing app usage limits and focus blocking.
class AppLimitService {
  static const String _prefixLimit = 'synvero_app_usage_limit_mins_';
  static const String _prefixStrict = 'synvero_app_strict_lock_';

  /// Standard simulated / recorded app usage in minutes for the current day
  static final Map<String, int> defaultUsageMinutes = {
    'Instagram': 90, // 1h 30m
    'YouTube': 61, // 1h 1m
    'HabbitNova Focus': 45, // 45m
    'WA Business': 26, // 26m
    'Chrome Browser': 20, // 20m
  };

  /// Initialize recommended default limits on first run
  static Future<void> initializeDefaultsIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const initKey = 'synvero_app_limits_initialized_v2';
      if (!prefs.containsKey(initKey)) {
        await prefs.setBool(initKey, true);
        await prefs.setInt('$_prefixLimit' 'Instagram', 60); // 1h limit
        await prefs.setInt('$_prefixLimit' 'YouTube', 60); // 1h limit
      }
    } catch (e) {
      debugPrint('AppLimitService.initializeDefaultsIfNeeded: $e');
    }
  }

  /// Fetch limit for a specific app (in minutes). Returns null if no limit is set.
  static Future<int?> getLimit(String appName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_prefixLimit$appName');
    } catch (e) {
      debugPrint('AppLimitService.getLimit error: $e');
      return null;
    }
  }

  /// Check if strict mode is active for this app
  static Future<bool> isStrict(String appName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_prefixStrict$appName') ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Set a usage limit in minutes for an app
  static Future<void> setLimit(
    String appName,
    int minutes, {
    bool strictMode = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_prefixLimit$appName', minutes);
      await prefs.setBool('$_prefixStrict$appName', strictMode);
    } catch (e) {
      debugPrint('AppLimitService.setLimit error: $e');
    }
  }

  /// Remove limit for an app
  static Future<void> removeLimit(String appName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefixLimit$appName');
      await prefs.remove('$_prefixStrict$appName');
    } catch (e) {
      debugPrint('AppLimitService.removeLimit error: $e');
    }
  }

  /// Load all limits for a given list of app names
  static Future<Map<String, int>> loadAllLimits(List<String> appNames) async {
    final Map<String, int> limits = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final name in appNames) {
        final limit = prefs.getInt('$_prefixLimit$name');
        if (limit != null) {
          limits[name] = limit;
        }
      }
    } catch (e) {
      debugPrint('AppLimitService.loadAllLimits error: $e');
    }
    return limits;
  }

  /// Checks if the app has reached or exceeded its limit
  static bool isLimitReached(int currentUsageMinutes, int? limitMinutes) {
    if (limitMinutes == null || limitMinutes <= 0) return false;
    return currentUsageMinutes >= limitMinutes;
  }

  /// Formats minutes into human-readable e.g. "1h 30m" or "45m"
  static String formatMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}
