import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Builds the Synvero theme data.
ThemeData buildSynveroTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: kPrimaryColor,
      primaryContainer: kPrimaryLight,
      secondary: kPrimaryColor,
      secondaryContainer: kSoftBlueBackground,
      surface: kSurfaceColor,
      error: kErrorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: kDarkText,
      onError: Colors.white,
      outline: kBorderColor,
    ),
    scaffoldBackgroundColor: kMainBackground,
    cardTheme: CardThemeData(
      color: kSurfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: kBorderColor),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kInputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kFocusColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kErrorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kErrorColor, width: 2),
      ),
      labelStyle: const TextStyle(
        color: kSecondaryText,
        fontSize: 14,
      ),
      hintStyle: const TextStyle(
        color: kSecondaryText,
        fontSize: 14,
      ),
      errorStyle: const TextStyle(
        color: kErrorColor,
        fontSize: 12,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimaryColor,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    timePickerTheme: const TimePickerThemeData(
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        border: OutlineInputBorder(),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: kDarkText,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: TextStyle(
        color: kDarkText,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        color: kDarkText,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: kDarkText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: kDarkText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: kDarkText,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: kDarkText,
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        color: kSecondaryText,
        fontSize: 14,
      ),
    ),
  );
}

/// Builds the Synvero dark theme data.
ThemeData buildSynveroDarkTheme() {
  const kDarkBg = Color(0xFF0A0F1D);
  const kDarkSurface = Color(0xFF131D31);
  const kDarkBorder = Color(0xFF1E293B);
  const kDarkInput = Color(0xFF162035);
  const kLightText = Color(0xFFF8FAFC);
  const kMutedText = Color(0xFF94A3B8);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B66FF),
      primaryContainer: Color(0xFF1E3A8A),
      secondary: Color(0xFF3B66FF),
      secondaryContainer: Color(0xFF1E293B),
      surface: kDarkSurface,
      error: kErrorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: kLightText,
      onError: Colors.white,
      outline: kDarkBorder,
    ),
    scaffoldBackgroundColor: kDarkBg,
    cardTheme: const CardThemeData(
      color: kDarkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: kDarkBorder),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: kDarkInput,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kDarkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kDarkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF3B66FF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kErrorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kErrorColor, width: 2),
      ),
      labelStyle: TextStyle(
        color: kMutedText,
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: kMutedText,
        fontSize: 14,
      ),
      errorStyle: TextStyle(
        color: kErrorColor,
        fontSize: 12,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B66FF),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF3B66FF),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    timePickerTheme: const TimePickerThemeData(
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        border: OutlineInputBorder(),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: kLightText,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: TextStyle(
        color: kLightText,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        color: kLightText,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: kLightText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: kLightText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: kLightText,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: kLightText,
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        color: kMutedText,
        fontSize: 14,
      ),
    ),
  );
}