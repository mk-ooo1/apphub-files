import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsProvider extends ChangeNotifier {
  static const String _timezoneKey = 'user_timezone';
  static const String _geminiApiKey = 'gemini_api_key';

  String _timezone = 'Asia/Kolkata';
  String _apiKey = '';
  bool _isLoaded = false;

  UserPrefsProvider() {
    _loadPrefs();
  }

  String get timezone => _timezone;
  String get geminiApiKey => _apiKey;
  bool get isLoaded => _isLoaded;

  Future<void> setTimezone(String newTimezone) async {
    _timezone = newTimezone;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timezoneKey, newTimezone);
  }

  Future<void> setGeminiApiKey(String key) async {
    _apiKey = key.trim();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKey, _apiKey);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _timezone = prefs.getString(_timezoneKey) ?? 'Asia/Kolkata';
    _apiKey = prefs.getString(_geminiApiKey) ?? '';
    _isLoaded = true;
    notifyListeners();
  }
}
