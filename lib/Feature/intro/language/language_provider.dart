import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;

  /// تحميل اللغة المحفوظة
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    String languageCode = prefs.getString('language') ?? 'ar';

    _locale = Locale(languageCode);

    notifyListeners();
  }

  /// تغيير اللغة
  Future<void> changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('language', languageCode);

    _locale = Locale(languageCode);

    notifyListeners();
  }
}