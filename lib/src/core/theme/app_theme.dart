import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  // Rich Pink Palette
  static const Color sakura = Color(0xFFFFEBF2);      // Very light pink background
  static const Color blush = Color(0xFFFDE2E4);       // Soft peach-pink
  static const Color rose = Color(0xFFFFB7C5);        // Romantic rose
  static const Color carnation = Color(0xFFFFA6C9);   // Classic soft pink
  static const Color ruby = Color(0xFFE0115F);        // Deep ruby for contrast
  static const Color primary = Color(0xFFFF4081);     // Vibrant pink accent
  static const Color lilac = Color(0xFFF0E6EF);       // Lilac for depth
  static const Color mocha = Color(0xFFD8B4A6);       // Beige-pink for warmth
  
  static const Color textMain = Color(0xFF4A4A4A);
  static const Color textLight = Color(0xFF9E9E9E);
}

class AppStyles {
  static const double borderRadius = 30.0;
  
  static BoxDecoration glass({
    Color color = Colors.white,
    double opacity = 0.2,
    double blur = 12.0,
    BorderRadius? radius,
  }) {
    return BoxDecoration(
      color: color.withOpacity(opacity),
      borderRadius: radius ?? BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    );
  }

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.pink.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.ruby,
    letterSpacing: 1.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: AppColors.textLight,
    fontWeight: FontWeight.w500,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.rose,
        surface: AppColors.sakura,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.ruby,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.ruby),
      ),
      fontFamily: 'Inter', // Defaulting to system or standard if Inter not loaded
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.rose.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        labelStyle: const TextStyle(color: AppColors.textLight),
      ),
    );
  }
}
