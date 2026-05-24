import 'package:flutter/material.dart';

/// Health app theme constants and configuration.
class AppTheme {
  // ── Brand Colors ──
  static const Color healthGreen = Color(0xFF4CAF50);
  static const Color healthGreenLight = Color(0xFF81C784);
  static const Color healthGreenDark = Color(0xFF388E3C);

  static const Color blue = Color(0xFF2196F3);
  static const Color blueLight = Color(0xFF64B5F6);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);

  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);

  // ── Neutral / Surface ──
  static const Color surfaceLight = Color(0xFFF5F7FA);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);

  // ── Health Status Colors ──
  static const Color normal = Color(0xFF4CAF50);
  static const Color elevated = Color(0xFFFF9800);
  static const Color warningLevel = Color(0xFFF44336);

  // ── Light Theme ──
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: healthGreen,
      primary: healthGreen,
      secondary: blue,
      error: error,
      surface: surfaceLight,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceLight,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: healthGreen,
        foregroundColor: Colors.white,
        titleTextStyle: _titleMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Navigation Bar (Bottom Nav) ──
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: healthGreen.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _labelSmall.copyWith(
              color: healthGreen,
              fontWeight: FontWeight.w600,
            );
          }
          return _labelSmall.copyWith(color: Colors.grey);
        }),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: healthGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: healthGreen,
          side: const BorderSide(color: healthGreen),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: healthGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        selectedColor: healthGreen.withValues(alpha: 0.15),
        labelStyle: _labelSmall,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),

      // ── Text Theme ──
      textTheme: TextTheme(
        displayLarge: _displayLarge,
        displayMedium: _displayMedium,
        headlineLarge: _headlineLarge,
        headlineMedium: _headlineMedium,
        titleLarge: _titleLarge,
        titleMedium: _titleMedium,
        titleSmall: _titleSmall,
        bodyLarge: _bodyLarge,
        bodyMedium: _bodyMedium,
        bodySmall: _bodySmall,
        labelLarge: _labelLarge,
        labelMedium: _labelMedium,
        labelSmall: _labelSmall,
      ),
    );
  }

  // ── Dark Theme ──
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: healthGreen,
      primary: healthGreenLight,
      secondary: blueLight,
      error: errorLight,
      surface: surfaceDark,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceDark,

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: cardDark,
        foregroundColor: Colors.white,
        titleTextStyle: _titleMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardDark,
        indicatorColor: healthGreenLight.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _labelSmall.copyWith(
              color: healthGreenLight,
              fontWeight: FontWeight.w600,
            );
          }
          return _labelSmall.copyWith(color: Colors.grey);
        }),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        color: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: healthGreenLight,
          foregroundColor: Colors.black,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: healthGreenLight,
          side: const BorderSide(color: healthGreenLight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: healthGreenLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorLight),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        selectedColor: healthGreenLight.withValues(alpha: 0.2),
        labelStyle: _labelSmall,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: Colors.grey.shade800,
      ),

      textTheme: TextTheme(
        displayLarge: _displayLarge,
        displayMedium: _displayMedium,
        headlineLarge: _headlineLarge,
        headlineMedium: _headlineMedium,
        titleLarge: _titleLarge,
        titleMedium: _titleMedium,
        titleSmall: _titleSmall,
        bodyLarge: _bodyLarge,
        bodyMedium: _bodyMedium,
        bodySmall: _bodySmall,
        labelLarge: _labelLarge,
        labelMedium: _labelMedium,
        labelSmall: _labelSmall,
      ),
    );
  }

  // ── Custom Text Styles for Health Data ──
  static const _displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.5,
  );

  static const _displayMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
  );

  static const _headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const _headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const _titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const _titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static const _titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const _bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const _bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static const _bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static const _labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const _labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const _labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // ── Health-specific text styles (for big number display) ──
  static const TextStyle healthValue = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle healthUnit = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );

  static const TextStyle healthLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.grey,
    letterSpacing: 0.5,
  );

  static const TextStyle healthStatus = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
  );
}
