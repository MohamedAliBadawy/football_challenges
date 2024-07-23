import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _myColor = ThemeMode.system == ThemeMode.dark
      ? Color.fromARGB(255, 51, 55, 50)
      : Color(4294245612);
  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  Color get myColor => _myColor;

  void toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDarkMode = prefs.getBool('isDarkMode');
    if (isDarkMode != null) {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      _myColor =
          isDarkMode ? Color.fromARGB(255, 51, 55, 50) : Color(4294245612);
    } else {
      // If no value in SharedPreferences, use system theme
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void setThemeFromSystem(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    _themeMode =
        brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
