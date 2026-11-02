import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model representing an app's live real-time screen time statistics
class AppScreenTimeItem {
  final String packageName;
  final String appName;
  final String category;
  final int usageMinutes;
  final int usageTimeMs;
  final String durationFormatted;

  AppScreenTimeItem({
    required this.packageName,
    required this.appName,
    required this.category,
    required this.usageMinutes,
    required this.usageTimeMs,
    required this.durationFormatted,
  });

  factory AppScreenTimeItem.fromMap(Map<dynamic, dynamic> map) {
    return AppScreenTimeItem(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? 'App',
      category: map['category'] as String? ?? 'Apps & Tools',
      usageMinutes: (map['usageMinutes'] as num?)?.toInt() ?? 0,
      usageTimeMs: (map['usageTimeMs'] as num?)?.toInt() ?? 0,
      durationFormatted: map['durationFormatted'] as String? ?? '0 min',
    );
  }
}

/// Model representing an app's live real-time network data consumption
class AppDataUsageItem {
  final String packageName;
  final String appName;
  final String category;
  final int bytes;
  final String usageFormatted;

  AppDataUsageItem({
    required this.packageName,
    required this.appName,
    required this.category,
    required this.bytes,
    required this.usageFormatted,
  });

  factory AppDataUsageItem.fromMap(Map<dynamic, dynamic> map) {
    return AppDataUsageItem(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? 'App',
      category: map['category'] as String? ?? 'Apps & Tools',
      bytes: (map['bytes'] as num?)?.toInt() ?? 0,
      usageFormatted: map['usageFormatted'] as String? ?? '0 MB',
    );
  }
}

/// Service managing Digital Wellbeing app usage limits, real-time screen time,
/// and live Android background focus app locking.
class AppLimitService {
  static const String _prefixLimit = 'synvero_app_usage_limit_mins_';
  static const String _prefixStrict = 'synvero_app_strict_lock_';
  static const MethodChannel _channel = MethodChannel('com.example.synvero/usage_stats');

  /// Global notifier when native Android intercepts and blocks an app attempt
  static final ValueNotifier<Map<String, dynamic>?> blockedAppEventNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  static bool _handlerInitialized = false;

  /// Ensures native-to-Flutter event listener is wired up
  static void ensureHandler() {
    if (_handlerInitialized) return;
    _handlerInitialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAppBlockedEvent') {
        final args = call.arguments;
        if (args is Map) {
          blockedAppEventNotifier.value = Map<String, dynamic>.from(args);
        }
      }
    });
  }

  /// Checks if Android Usage Access permission (PACKAGE_USAGE_STATS) is granted
  static Future<bool> hasUsagePermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('hasUsagePermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android Settings -> Special App Access -> Usage Access
  static Future<void> requestUsagePermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestUsagePermission');
    } catch (_) {}
  }

  /// Checks if HabbitNova App Blocker Accessibility Service is turned ON
  static Future<bool> hasAccessibilityPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('hasAccessibilityPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android Settings -> Accessibility
  static Future<void> requestAccessibilityPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } catch (_) {}
  }

  /// Queries real-time screen time statistics from Android UsageStatsManager
  static Future<Map<String, dynamic>> getLiveScreenTimeStats() async {
    ensureHandler();
    if (kIsWeb || !Platform.isAndroid) {
      return _getFallbackScreenTime();
    }
    try {
      final res = await _channel.invokeMethod<Map>('getScreenTimeStats');
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      debugPrint('getLiveScreenTimeStats error: $e');
    }
    return _getFallbackScreenTime();
  }

  /// Queries real-time daily network data usage from Android NetworkStatsManager
  static Future<Map<String, dynamic>> getLiveDataUsageStats() async {
    ensureHandler();
    if (kIsWeb || !Platform.isAndroid) {
      return _getFallbackDataUsage();
    }
    try {
      final res = await _channel.invokeMethod<Map>('getDataUsageStats');
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      debugPrint('getLiveDataUsageStats error: $e');
    }
    return _getFallbackDataUsage();
  }

  /// Fetch limit for a specific app (in minutes). Returns null if no limit is set.
  static Future<int?> getLimit(String appKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_prefixLimit$appKey');
    } catch (e) {
      debugPrint('AppLimitService.getLimit error: $e');
      return null;
    }
  }

  /// Check if strict mode is active for this app
  static Future<bool> isStrict(String appKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_prefixStrict$appKey') ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Set a usage limit in minutes for an app and sync with Android native blocker
  static Future<void> setLimit(
    String appName,
    int minutes, {
    String? packageName,
    bool strictMode = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_prefixLimit$appName', minutes);
      await prefs.setBool('$_prefixStrict$appName', strictMode);
      if (packageName != null && packageName.isNotEmpty) {
        await prefs.setInt('$_prefixLimit$packageName', minutes);
        await prefs.setBool('$_prefixStrict$packageName', strictMode);
      }

      if (!kIsWeb && Platform.isAndroid) {
        await _channel.invokeMethod('setAppLimit', {
          'packageName': packageName ?? '',
          'appName': appName,
          'minutes': minutes,
        });
      }
    } catch (e) {
      debugPrint('AppLimitService.setLimit error: $e');
    }
  }

  /// Remove limit for an app and sync with Android native blocker
  static Future<void> removeLimit(String appName, {String? packageName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefixLimit$appName');
      await prefs.remove('$_prefixStrict$appName');
      if (packageName != null && packageName.isNotEmpty) {
        await prefs.remove('$_prefixLimit$packageName');
        await prefs.remove('$_prefixStrict$packageName');
      }

      if (!kIsWeb && Platform.isAndroid) {
        await _channel.invokeMethod('removeAppLimit', {
          'packageName': packageName ?? '',
          'appName': appName,
        });
      }
    } catch (e) {
      debugPrint('AppLimitService.removeLimit error: $e');
    }
  }

  /// Load all limits for given app keys
  static Future<Map<String, int>> loadAllLimits(List<String> appKeys) async {
    final Map<String, int> limits = {};
    try {
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final nativeLimits = await _channel.invokeMethod<Map>('getAllLimits');
          if (nativeLimits != null) {
            for (final entry in nativeLimits.entries) {
              if (entry.value is int && (entry.value as int) > 0) {
                limits[entry.key.toString()] = entry.value as int;
              }
            }
          }
        } catch (_) {}
      }

      final prefs = await SharedPreferences.getInstance();
      for (final key in appKeys) {
        final limit = prefs.getInt('$_prefixLimit$key');
        if (limit != null && limit > 0) {
          limits[key] = limit;
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

  static Map<String, dynamic> _getFallbackScreenTime() {
    return {
      'hasPermission': false,
      'totalScreenTimeMs': 0,
      'totalFormatted': 'Permission Required',
      'weeklyHours': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      'weekDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      'apps': <Map<String, dynamic>>[],
    };
  }

  static Map<String, dynamic> _getFallbackDataUsage() {
    return {
      'totalBytes': 0,
      'totalFormatted': '0 MB today',
      'apps': <Map<String, dynamic>>[],
    };
  }
}
