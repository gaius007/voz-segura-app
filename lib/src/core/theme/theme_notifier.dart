import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modes available for theme selection
enum AppThemeMode {
  system,   // Follow device setting
  light,    // Always light
  dark,     // Always dark
  dynamic,  // Changes based on time of day
}

/// Manages the app's theme mode with persistence and time-based switching.
class ThemeNotifier extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';

  final SharedPreferences _prefs;
  AppThemeMode _mode;
  Timer? _dynamicTimer;

  ThemeNotifier(this._prefs)
      : _mode = _parseMode(_prefs.getString(_prefKey)) {
    if (_mode == AppThemeMode.dynamic) {
      _startDynamicTimer();
    }
  }

  AppThemeMode get mode => _mode;

  /// Returns the Flutter ThemeMode based on current selection
  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.dynamic:
        return _isDayTime() ? ThemeMode.light : ThemeMode.dark;
    }
  }

  /// User-facing label for each mode (in Portuguese)
  String get modeLabel {
    switch (_mode) {
      case AppThemeMode.system:
        return 'Sistema';
      case AppThemeMode.light:
        return 'Claro';
      case AppThemeMode.dark:
        return 'Escuro';
      case AppThemeMode.dynamic:
        return 'Dinâmico';
    }
  }

  /// Updates the theme mode and persists it
  void setMode(AppThemeMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    _prefs.setString(_prefKey, newMode.name);

    _dynamicTimer?.cancel();
    _dynamicTimer = null;

    if (newMode == AppThemeMode.dynamic) {
      _startDynamicTimer();
    }

    notifyListeners();
  }

  /// Checks if current time is daytime (06:00 - 17:59)
  bool _isDayTime() {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 18;
  }

  /// Re-evaluates dynamic theme every 15 minutes
  void _startDynamicTimer() {
    // Store current state to detect transitions
    bool wasDayTime = _isDayTime();

    _dynamicTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      final nowDayTime = _isDayTime();
      if (nowDayTime != wasDayTime) {
        wasDayTime = nowDayTime;
        notifyListeners(); // Triggers theme transition
      }
    });
  }

  static AppThemeMode _parseMode(String? value) {
    if (value == null) return AppThemeMode.system;
    return AppThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  @override
  void dispose() {
    _dynamicTimer?.cancel();
    super.dispose();
  }
}
