import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared premium design tokens used by both the light and dark themes.
///
/// Keeping spacing, radii and the font family in one place means every screen
/// picks up the same visual language without touching its own code.
class AppTokens {
  AppTokens._();

  /// Bundled premium typeface (see pubspec.yaml `fonts:` section).
  static const String fontFamily = 'PlusJakartaSans';

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  static const double buttonHeight = 54;
  static const double controlHeight = 52;
}

/// Typography scale tuned for a premium, editorial feel: tight tracking on
/// headings, generous line height on body copy.
TextTheme _premiumTextTheme({required Color text, required Color muted}) {
  return TextTheme(
    displayLarge: TextStyle(
      color: text,
      fontSize: 34,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      color: text,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.9,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      color: text,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      height: 1.18,
    ),
    headlineLarge: TextStyle(
      color: text,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.22,
    ),
    headlineMedium: TextStyle(
      color: text,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.26,
    ),
    headlineSmall: TextStyle(
      color: text,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      color: text,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      color: text,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.35,
    ),
    titleSmall: TextStyle(
      color: text,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    bodyLarge: TextStyle(
      color: text,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      color: text,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    bodySmall: TextStyle(
      color: muted,
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      color: text,
      fontSize: 14.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      color: muted,
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
    labelSmall: TextStyle(
      color: muted,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    ),
  );
}

ThemeData _buildPremiumTheme({required Brightness brightness}) {
  final bool dark = brightness == Brightness.dark;

  final Color background = dark ? kDarkBackground : kMainBackground;
  final Color surface = dark ? kDarkSurface : kSurfaceColor;
  final Color surfaceAlt = dark ? const Color(0xFF0A1F33) : kSoftBlueBackground;
  final Color border = dark ? kDarkCardBorder : kBorderColor;
  final Color text = dark ? kDarkLightText : kDarkText;
  final Color muted = dark ? kDarkMutedText : kSecondaryText;
  final Color primary = dark ? const Color(0xFF3B66FF) : kPrimaryColor;
  final Color primaryContainer = dark ? const Color(0xFF1E3A8A) : kPrimaryLight;

  final ColorScheme scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: primaryContainer,
    onPrimaryContainer: dark ? kDarkLightText : kPrimaryDark,
    secondary: primary,
    onSecondary: Colors.white,
    secondaryContainer: surfaceAlt,
    onSecondaryContainer: text,
    error: kErrorColor,
    onError: Colors.white,
    surface: surface,
    onSurface: text,
    surfaceContainerHighest: surfaceAlt,
    onSurfaceVariant: muted,
    outline: border,
    outlineVariant: border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: dark ? kDarkLightText : kDarkText,
    onInverseSurface: dark ? kDarkText : kDarkLightText,
    inversePrimary: primaryContainer,
  );

  final TextTheme textTheme = _premiumTextTheme(text: text, muted: muted);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: AppTokens.fontFamily,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    dividerColor: border,
    splashColor: primary.withValues(alpha: 0.08),
    highlightColor: primary.withValues(alpha: 0.04),
    disabledColor: kDisabledColor,
    textTheme: textTheme,
    iconTheme: IconThemeData(color: text, size: 22),
    primaryIconTheme: const IconThemeData(color: Colors.white),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: dark ? Colors.black54 : primary.withValues(alpha: 0.10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppTokens.radiusLg)),
        side: BorderSide(color: border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: text),
      titleTextStyle: TextStyle(
        color: text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppTokens.radiusXl)),
        side: BorderSide(color: border),
      ),
      titleTextStyle: textTheme.headlineMedium,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: surface,
      modalBarrierColor: Colors.black.withValues(alpha: 0.55),
      elevation: 0,
      showDragHandle: false,
      dragHandleColor: border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusXl)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? kDarkSurface : kInputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
        borderSide: const BorderSide(color: kErrorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
        borderSide: const BorderSide(color: kErrorColor, width: 1.6),
      ),
      labelStyle: TextStyle(color: muted, fontSize: 14, fontWeight: FontWeight.w500),
      floatingLabelStyle: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: muted, fontSize: 14, fontWeight: FontWeight.w400),
      errorStyle: const TextStyle(color: kErrorColor, fontSize: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primary.withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white70,
        minimumSize: const Size(0, AppTokens.buttonHeight),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
        ),
        textStyle: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shadowColor: primary.withValues(alpha: 0.45),
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        minimumSize: const Size(0, AppTokens.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
        ),
        textStyle: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        minimumSize: const Size(0, AppTokens.controlHeight),
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
        ),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusSm)),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceAlt,
      selectedColor: primary.withValues(alpha: 0.16),
      disabledColor: surfaceAlt,
      side: BorderSide(color: border),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(color: text, fontSize: 12.5, fontWeight: FontWeight.w600),
      secondaryLabelStyle: TextStyle(color: primary, fontSize: 12.5, fontWeight: FontWeight.w600),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 70,
      indicatorColor: primary.withValues(alpha: 0.14),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11.5,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? primary : muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected) ? primary : muted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF0E2437) : kDarkText,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
      actionTextColor: kPrimaryLight,
      elevation: 8,
      insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
      ),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: muted,
      textColor: text,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      minVerticalPadding: 12,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? primary : border,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? primary : border,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(color: border, width: 1.6),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? primary : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? primary : border,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: border,
      circularTrackColor: border,
      linearMinHeight: 6,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      textStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
        side: BorderSide(color: border),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0E2437) : kDarkText,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: primary,
      selectionColor: primary.withValues(alpha: 0.28),
      selectionHandleColor: primary,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: muted,
      indicatorColor: primary,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusXl)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        border: OutlineInputBorder(),
      ),
    ),
  );
}

/// Builds the Synvero premium light theme.
ThemeData buildSynveroTheme() => _buildPremiumTheme(brightness: Brightness.light);

/// Builds the Synvero premium dark theme (Bioluminescent Zen).
ThemeData buildSynveroDarkTheme() => _buildPremiumTheme(brightness: Brightness.dark);
