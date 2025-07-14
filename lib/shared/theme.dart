import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primary = Color(
    0xFF2196F3,
  ); // Blue color for primary actions
  static const Color secondary = Color(0xFF03DAC6);

  // Text colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLink = Color(0xFF2196F3);

  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  // Border colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color inputBorder = Color(0xFFBDBDBD);
  static const Color focusedInputBorder = Color(0xFF2196F3);

  // Button colors
  static const Color buttonBackground = Color(0xFF2196F3);
  static const Color buttonText = Color(0xFFFFFFFF);

  // Error and validation colors
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);

  // Padding and sizing
  static const double defaultPadding = 16.0;
  static const double inputBorderRadius = 8.0;
  static const double buttonBorderRadius = 8.0;

  // Typography
  static const TextStyle headingLarge = TextStyle(
    fontFamily: "NunitoSans",
    fontSize: 28.0,
    fontVariations: [FontVariation('wght', 700)],
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: "NunitoSans",
    fontSize: 16.0,
    fontVariations: [FontVariation('wght', 500)],
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: "NunitoSans",
    fontSize: 16.0,
    fontVariations: [FontVariation('wght', 400)],
    color: textPrimary,
  );

  static const TextStyle linkText = TextStyle(
    fontFamily: "NunitoSans",
    fontSize: 16.0,
    fontVariations: [FontVariation('wght', 400)],
    color: textSecondary,
  );

  // Theme data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: error,
        background: background,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        headlineLarge: headingLarge,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: focusedInputBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackground,
          foregroundColor: buttonText,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: bodyMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textLink,
          textStyle: bodyMedium,
        ),
      ),
    );
  }
}
