import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences sharedPreferences;
  static const String _themeKey = 'theme_mode';

  ThemeCubit({required this.sharedPreferences}) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final cachedTheme = sharedPreferences.getString(_themeKey);
    if (cachedTheme == 'light') {
      emit(ThemeMode.light);
    } else if (cachedTheme == 'dark') {
      emit(ThemeMode.dark);
    } else {
      emit(ThemeMode.system);
    }
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    emit(themeMode);
    String themeString = 'system';
    if (themeMode == ThemeMode.light) themeString = 'light';
    if (themeMode == ThemeMode.dark) themeString = 'dark';
    await sharedPreferences.setString(_themeKey, themeString);
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setTheme(ThemeMode.light);
    } else {
      setTheme(ThemeMode.dark);
    }
  }
}
