import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier._() : super(ThemeMode.light);

  static final ThemeNotifier instance = ThemeNotifier._();

  static const _key = 'theme_mode';

  /// Call once at app start to restore the saved preference.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'dark') {
      value = ThemeMode.dark;
    } else {
      value = ThemeMode.light;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  bool get isDark => value == ThemeMode.dark;
}
