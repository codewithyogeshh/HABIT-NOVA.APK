import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing application theme mode (Light, Dark, System) with persistence.
class ThemeService {
  static const String _prefKey = 'app_theme_mode';

  /// Reactive notifier for theme mode changes.
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Current theme mode.
  static ThemeMode get currentThemeMode => themeModeNotifier.value;

  /// Human-friendly display title for current theme.
  static String get currentThemeName {
    switch (themeModeNotifier.value) {
      case ThemeMode.dark:
        return 'Dark Theme';
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Theme';
    }
  }

  /// Initialize theme mode from SharedPreferences.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode == 'dark') {
        themeModeNotifier.value = ThemeMode.dark;
      } else if (savedMode == 'system') {
        themeModeNotifier.value = ThemeMode.system;
      } else {
        themeModeNotifier.value = ThemeMode.light;
      }
    } catch (_) {
      themeModeNotifier.value = ThemeMode.light;
    }
  }

  /// Set and persist new theme mode.
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr = 'light';
      if (mode == ThemeMode.dark) {
        modeStr = 'dark';
      } else if (mode == ThemeMode.system) {
        modeStr = 'system';
      }
      await prefs.setString(_prefKey, modeStr);
    } catch (_) {}
  }
}
