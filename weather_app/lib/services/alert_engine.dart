import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'dart:convert';

class AlertEngine {
  static const String keyRainAlert = 'last_rain_alert_epoch';
  static const String keyHeatAlert = 'last_heat_alert_epoch';
  static const int antiSpamHours = 6;

  static Future<void> evaluateAndNotify({
    required Map<String, dynamic>? current,
    required Map<String, dynamic>? forecast,
  }) async {
    if (current == null || forecast == null) return;

    final prefs = await SharedPreferences.getInstance();
    final rainEnabled = prefs.getBool('rain_alerts_enabled') ?? true;
    final heatEnabled = prefs.getBool('heat_alerts_enabled') ?? true;

    if (rainEnabled) {
      await _checkRain(current, forecast, prefs);
    }

    if (heatEnabled) {
      await _checkHeat(current, forecast, prefs);
    }
  }

  static Future<void> _checkRain(Map<String, dynamic> current, Map<String, dynamic> forecast, SharedPreferences prefs) async {
    // Check next 6 hours of forecast
    final list = (forecast['list'] as List?) ?? [];
    bool rainExpected = false;
    String rainTime = "";

    for (var i = 0; i < list.length && i < 3; i++) { // 3 * 3h = 9h or whatever frequency
      final item = list[i];
      final pop = (item['pop'] as num?)?.toDouble() ?? 0.0;
      final weather = (item['weather'] as List?)?.first['main']?.toString() ?? "";

      if (pop >= 0.5 || weather.contains('Rain') || weather.contains('Thunderstorm')) {
        rainExpected = true;
        final dt = DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000);
        rainTime = "${dt.hour}:00";
        break;
      }
    }

    if (rainExpected) {
      if (_shouldNotify(prefs, keyRainAlert)) {
        await NotificationService().showNow(
          id: 101,
          title: "Rain Alert 🌧️",
          body: "Rain expected around $rainTime. Plan your commute earlier.",
          channelId: 'rain_alerts',
        );
        await prefs.setInt(keyRainAlert, DateTime.now().millisecondsSinceEpoch);
      }
    }
  }

  static Future<void> _checkHeat(Map<String, dynamic> current, Map<String, dynamic> forecast, SharedPreferences prefs) async {
    final temp = (current['main']?['temp'] as num?)?.toDouble() ?? 0.0;
    
    // Threshold for Bangladesh
    if (temp >= 36.0) {
      if (_shouldNotify(prefs, keyHeatAlert)) {
        await NotificationService().showNow(
          id: 102,
          title: "Heatwave Alert ☀️",
          body: "Extreme heat risk ($temp°C). Stay hydrated and avoid direct sun.",
          channelId: 'heat_alerts',
        );
        await prefs.setInt(keyHeatAlert, DateTime.now().millisecondsSinceEpoch);
      }
    }
  }

  static bool _shouldNotify(SharedPreferences prefs, String key) {
    final lastSent = prefs.getInt(key) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastSent;
    
    return diff > (antiSpamHours * 3600 * 1000);
  }
}
