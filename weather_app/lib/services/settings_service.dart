import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  bool _rainAlerts = true;
  bool _heatAlerts = true;
  bool _windAlerts = true;
  String _unit = "°C";
  String _language = "bn"; 
  bool _lowDataMode = false;

  bool get rainAlerts => _rainAlerts;
  bool get heatAlerts => _heatAlerts;
  bool get windAlerts => _windAlerts;
  bool get lowDataMode => _lowDataMode;
  String get unit => _unit;
  String get language => _language;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _rainAlerts = prefs.getBool('rainAlerts') ?? true;
    _heatAlerts = prefs.getBool('heatAlerts') ?? true;
    _windAlerts = prefs.getBool('windAlerts') ?? true;
    _lowDataMode = prefs.getBool('lowDataMode') ?? false;
    _unit = prefs.getString('unit') ?? "°C";
    _language = prefs.getString('language') ?? "bn";
    notifyListeners();
  }

  Future<void> toggleLowData(bool value) async {
    _lowDataMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lowDataMode', value);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  Future<void> toggleRain(bool value) async {
    _rainAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rainAlerts', value);
    notifyListeners();
  }

  Future<void> toggleHeat(bool value) async {
    _heatAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('heatAlerts', value);
    notifyListeners();
  }

  Future<void> toggleWind(bool value) async {
    _windAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('windAlerts', value);
    notifyListeners();
  }

  Future<void> setUnit(String unit) async {
    _unit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unit', unit);
    notifyListeners();
  }
}
