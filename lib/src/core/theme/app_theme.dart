import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  // ─── Light Palette ─────────────────────────────────────────
  static const Color sakura = Color(0xFFFFEBF2);
  static const Color blush = Color(0xFFFDE2E4);
  static const Color rose = Color(0xFFFFB7C5);
  static const Color carnation = Color(0xFFFFA6C9);
  static const Color ruby = Color(0xFFE0115F);
  static const Color primary = Color(0xFFFF4081);
  static const Color lilac = Color(0xFFF0E6EF);
  static const Color mocha = Color(0xFFD8B4A6);

  static const Color textMain = Color(0xFF4A4A4A);
  static const Color textLight = Color(0xFF9E9E9E);

  // ─── Dark Palette ──────────────────────────────────────────
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF2A2A2A);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color darkTextMain = Color(0xFFE0E0E0);
  static const Color darkTextLight = Color(0xFFB0B0B0);
  static const Color darkPrimary = Color(0xFFFF4D94);
  static const Color darkRuby = Color(0xFFFF69B4);
  static const Color darkSakura = Color(0xFF2D1F28);
  static const Color darkBlush = Color(0xFF2A2025);
  static const Color darkRose = Color(0xFF8B4A5E);
  static const Color darkLilac = Color(0xFF2E2432);
  static const Color darkDivider = Color(0xFF3A3A3A);
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

  static List<BoxShadow> darkSoftShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
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

TextTheme _buildSafeTextTheme(TextTheme base, Color defaultColor) {
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(color: defaultColor),
    displayMedium: base.displayMedium?.copyWith(color: defaultColor),
    displaySmall: base.displaySmall?.copyWith(color: defaultColor),
    headlineLarge: base.headlineLarge?.copyWith(color: defaultColor),
    headlineMedium: base.headlineMedium?.copyWith(color: defaultColor),
    headlineSmall: base.headlineSmall?.copyWith(color: defaultColor),
    titleLarge: base.titleLarge?.copyWith(color: defaultColor),
    titleMedium: base.titleMedium?.copyWith(color: defaultColor),
    titleSmall: base.titleSmall?.copyWith(color: defaultColor),
    bodyLarge: base.bodyLarge?.copyWith(color: defaultColor),
    bodyMedium: base.bodyMedium?.copyWith(color: defaultColor),
    bodySmall: base.bodySmall?.copyWith(color: defaultColor),
    labelLarge: base.labelLarge?.copyWith(overflow: TextOverflow.ellipsis, color: defaultColor),
    labelMedium: base.labelMedium?.copyWith(overflow: TextOverflow.ellipsis, color: defaultColor),
    labelSmall: base.labelSmall?.copyWith(overflow: TextOverflow.ellipsis, color: defaultColor),
  );
}

class AppTheme {
  // ─── Light Theme ───────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true, fontFamily: 'Inter');
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.rose,
        surface: AppColors.sakura,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      dividerColor: AppColors.sakura,
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
      textTheme: _buildSafeTextTheme(base.textTheme, AppColors.textMain),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.ruby),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.ruby, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textLight),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.borderRadius)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.ruby;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.sakura;
          return null;
        }),
      ),
    );
  }

  // ─── Dark Theme ────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark, fontFamily: 'Inter');
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkPrimary,
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkRose,
        surface: AppColors.darkSurface,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkDivider,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.darkRuby,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.darkRuby),
      ),
      textTheme: _buildSafeTextTheme(base.textTheme, AppColors.darkTextMain),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.darkRose.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.darkPrimary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.darkRuby),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.darkRuby, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.darkTextLight),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.borderRadius)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.darkRuby;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.darkSakura;
          return null;
        }),
      ),
    );
  }
}

// ─── Theme-aware color helpers ─────────────────────────────
// Use these in widgets to pick the right color based on current brightness
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appPrimary => isDark ? AppColors.darkPrimary : AppColors.primary;
  Color get appRuby => isDark ? AppColors.darkRuby : AppColors.ruby;
  Color get appSakura => isDark ? AppColors.darkSakura : AppColors.sakura;
  Color get appBlush => isDark ? AppColors.darkBlush : AppColors.blush;
  Color get appRose => isDark ? AppColors.darkRose : AppColors.rose;
  Color get appLilac => isDark ? AppColors.darkLilac : AppColors.lilac;
  Color get appTextMain => isDark ? AppColors.darkTextMain : AppColors.textMain;
  Color get appTextLight => isDark ? AppColors.darkTextLight : AppColors.textLight;
  Color get appCardColor => isDark ? AppColors.darkCard : Colors.white;
  Color get appScaffoldBg => isDark ? AppColors.darkBackground : Colors.white;
  Color get appDivider => isDark ? AppColors.darkDivider : AppColors.sakura;

  List<BoxShadow> get appSoftShadow => isDark ? AppStyles.darkSoftShadow : AppStyles.softShadow;

  // Gradient for backgrounds
  LinearGradient get appBackgroundGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkBackground, Color(0xFF252525), AppColors.darkBackground],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sakura, Colors.white, AppColors.blush],
        );

  // Glass effect color
  Color get appGlassColor => isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.4);
  Color get appGlassBorder => isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5);
}
