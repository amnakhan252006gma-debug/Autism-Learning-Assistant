import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Local-only persistence and state for the user's preferred theme mode.
///
/// No backend is involved: the choice is stored with [SharedPreferences]
/// and read when the app starts.
class ThemeService {
  ThemeService._();

  static const String _key = 'theme_mode';

  /// Notifier that drives [MaterialApp.themeMode].
  ///
  /// Update this value (after calling [AppTheme.setBrightness]) and the whole
  /// app will rebuild with the new palette.
  static final ValueNotifier<ThemeMode> modeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  /// Load the saved [ThemeMode], defaulting to [ThemeMode.light].
  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    return ThemeMode.values.byName(value ?? ThemeMode.light.name);
  }

  /// Persist the chosen [ThemeMode] locally.
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  /// Toggle between light and dark mode, persist the choice locally, and
  /// rebuild the app.
  static void toggle() {
    final isDark = modeNotifier.value == ThemeMode.dark;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;

    AppTheme.setBrightness(
      newMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
    );
    modeNotifier.value = newMode;
    saveThemeMode(newMode);
  }
}
