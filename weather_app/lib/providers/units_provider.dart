import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TempUnit { c, f }

class UnitsProvider extends ChangeNotifier {
  TempUnit _unit = TempUnit.c;
  final SharedPreferences _prefs;

  UnitsProvider(this._prefs) {
    _loadUnit();
  }

  TempUnit get unit => _unit;
  bool get isCelsius => _unit == TempUnit.c;

  void _loadUnit() {
    final unitStr = _prefs.getString('temp_unit') ?? '°C';
    _unit = unitStr == '°F' ? TempUnit.f : TempUnit.c;
    notifyListeners();
  }

  Future<void> setUnit(String unitStr) async {
    _unit = unitStr == '°F' ? TempUnit.f : TempUnit.c;
    await _prefs.setString('temp_unit', unitStr);
    notifyListeners();
  }

  String formatTemp(double tempC) {
    if (_unit == TempUnit.f) {
      double tempF = (tempC * 9 / 5) + 32;
      return "${tempF.toStringAsFixed(1)}°F";
    }
    return "${tempC.toStringAsFixed(1)}°C";
  }

  String get unitLabel => _unit == TempUnit.f ? "°F" : "°C";
}
