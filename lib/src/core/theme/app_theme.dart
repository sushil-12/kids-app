import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds the app's Material 3 theme: rounded, high-contrast, and friendly.
/// Large tap targets and bold type suit ages 2–8.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    // Seeded from the "Little Genius" logo: purple-led rainbow wordmark on a
    // soft, light ground.
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      primary: AppColors.purple,
      secondary: AppColors.coral,
      tertiary: AppColors.teal,
      surface: AppColors.cream,
      brightness: Brightness.light,
    );

    final TextTheme textTheme =
        GoogleFonts.fredokaTextTheme().apply(bodyColor: AppColors.dark, displayColor: AppColors.dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: textTheme,
      // Big, rounded, easy-to-tap controls.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          textStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
