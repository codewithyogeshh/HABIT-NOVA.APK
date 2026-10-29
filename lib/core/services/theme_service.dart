import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing application theme mode (Bioluminescent Dark Zen, Light, System) with persistence.
class ThemeService {
  static const String _prefKey = 'app_theme_mode';

  /// Reactive notifier for theme mode changes. Defaults to Bioluminescent Dark Theme.
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  /// Current theme mode.
  static ThemeMode get currentThemeMode => themeModeNotifier.value;

  /// Human-friendly display title for current theme.
  static String get currentThemeName {
    switch (themeModeNotifier.value) {
      case ThemeMode.dark:
        return 'Bioluminescent Zen';
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Theme';
    }
  }

  /// Initialize theme mode from SharedPreferences. Default is Bioluminescent Dark.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode == 'light') {
        themeModeNotifier.value = ThemeMode.light;
      } else if (savedMode == 'system') {
        themeModeNotifier.value = ThemeMode.system;
      } else {
        themeModeNotifier.value = ThemeMode.dark;
      }
    } catch (_) {
      themeModeNotifier.value = ThemeMode.dark;
    }
  }

  /// Set and persist new theme mode.
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr = 'dark';
      if (mode == ThemeMode.light) {
        modeStr = 'light';
      } else if (mode == ThemeMode.system) {
        modeStr = 'system';
      }
      await prefs.setString(_prefKey, modeStr);
    } catch (_) {}
  }
}
