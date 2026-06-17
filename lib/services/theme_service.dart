import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode') ?? 'system';
    
    switch (themeString) {
      case 'dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      default:
        themeModeNotifier.value = ThemeMode.system;
    }
  }

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    themeModeNotifier.value = mode;
    await prefs.setString('themeMode', mode.name);
  }
}
