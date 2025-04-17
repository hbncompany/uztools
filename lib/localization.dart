// localization.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class Localization {
  static Map<String, Map<String, String>> _translations = {};
  static String _currentLanguage = 'uz';

  static Future<void> loadTranslations() async {
    final String jsonString =
        await rootBundle.loadString('assets/translations.json');
    _translations = Map<String, Map<String, String>>.from(jsonDecode(jsonString)
        .map((key, value) => MapEntry(key, Map<String, String>.from(value))));
  }

  static String get currentLanguage => _currentLanguage;

  static void setLanguage(String language) {
    _currentLanguage = language;
  }

  static String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }
}
