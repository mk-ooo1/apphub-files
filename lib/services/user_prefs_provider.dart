import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsProvider extends ChangeNotifier {
  static const String _timezoneKey = 'user_timezone';
  
  String _timezone = 'Asia/Kolkata';
  bool _isLoaded = false;

  UserPrefsProvider() {
    _loadPrefs();
  }

  String get timezone => _timezone;
  bool get isLoaded => _isLoaded;

  Future<void> setTimezone(String newTimezone) async {
    _timezone = newTimezone;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timezoneKey, newTimezone);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _timezone = prefs.getString(_timezoneKey) ?? 'Asia/Kolkata';
    _isLoaded = true;
    notifyListeners();
  }
}
