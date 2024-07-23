import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Locale? get locale => _locale;

  void toggleLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('locale', _locale!.languageCode);
  }

  void _loadLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? locale = prefs.getString('locale');
    if (locale != null) {
      _locale = locale == 'ar' ? const Locale('ar') : const Locale('en');
    }
    notifyListeners();
  }
}
