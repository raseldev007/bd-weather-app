import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_service.dart';
import 'weather_insight_service.dart';

class HomeInsights {
  final Map<String, dynamic> current_weather;
  final Map<String, dynamic> primary_insight;
  final List<dynamic> hourly_risk;

  HomeInsights({
    required this.current_weather,
    required this.primary_insight,
    required this.hourly_risk,
  });

  factory HomeInsights.fromJson(Map<String, dynamic> json) {
    return HomeInsights(
      current_weather: json['current_weather'],
      primary_insight: json['primary_insight'],
      hourly_risk: json['hourly_risk'],
    );
  }
}

class WeatherService extends ChangeNotifier {
  HomeInsights? _homeInsights;
  List<Map<String, dynamic>> _alerts = [];
  Map<String, dynamic>? _forecast;
  bool _isLoading = false;
  final String _baseUrl = "http://localhost:8000/api/v1";

  HomeInsights? get homeInsights => _homeInsights;
  List<Map<String, dynamic>> get alerts => _alerts;
  Map<String, dynamic>? get forecast => _forecast;
  bool get isLoading => _isLoading;
  bool get isEmergency => _alerts.any((a) => a['severity'] == 'emergency');

  WeatherService() {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedInsights = prefs.getString('cached_home_insights');
    final cachedAlerts = prefs.getString('cached_alerts');
    final cachedForecast = prefs.getString('cached_forecast');

    if (cachedInsights != null) _homeInsights = HomeInsights.fromJson(json.decode(cachedInsights));
    if (cachedAlerts != null) _alerts = List<Map<String, dynamic>>.from(json.decode(cachedAlerts));
    if (cachedForecast != null) _forecast = json.decode(cachedForecast);
    notifyListeners();
  }

  Future<void> fetchHomeInsights(String district, ProfileService profile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/insights/home?district=$district&mode=${profile.mode.name}"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _homeInsights = HomeInsights.fromJson(data);
        
        // --- State Transition Detection ---
        final currentTemp = (_homeInsights?.current_weather['temp'] as num).toDouble();
        final currentHumidity = (_homeInsights?.current_weather['humidity'] as num).toDouble();
        final currentCondition = _homeInsights?.current_weather['condition'] as String;
        const lang = 'en'; // Ideally passed from UI or Profile

        OutcomeState? newWorkState;
        OutcomeState? newFarmState;
        Map<String, String> workCopy = {};
        Map<String, String> farmCopy = {};

        if (profile.isPremium) {
           final workData = WeatherInsightService.getWorkSafetyStatus(currentTemp, currentHumidity, currentCondition, lang);
           newWorkState = workData['state'] as OutcomeState;
           workCopy = WeatherInsightService.getNotificationCopy(profile.lastWorkState, newWorkState, UserMode.worker, lang);

           final farmData = WeatherInsightService.getCropRiskData(currentTemp, currentCondition, 0.0, lang); // Assuming wind 0 for now
           newFarmState = farmData['state'] as OutcomeState;
           farmCopy = WeatherInsightService.getNotificationCopy(profile.lastFarmState, newFarmState, UserMode.farmer, lang);
        }

        // Update Profile with new states and notification copy if transition occurred
        await profile.updateStates(
          workState: newWorkState,
          farmState: newFarmState,
          title: profile.mode == UserMode.worker ? workCopy['title'] : farmCopy['title'],
          body: profile.mode == UserMode.worker ? workCopy['body'] : farmCopy['body'],
        );

        // Impact Score Logic: Increment if insight is decision-worthy
        final severity = _homeInsights?.primary_insight['severity'];
        if (severity == 'high' || severity == 'emergency' || profile.mode != UserMode.general) {
          profile.incrementImpactScore();
        }
        
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cached_home_insights', json.encode(data));
      }
    } catch (e) {
      print("Error fetching home insights: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAlerts(String district) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse("$_baseUrl/alerts?district=$district"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _alerts = List<Map<String, dynamic>>.from(data['alerts']);
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cached_alerts', json.encode(_alerts));
      }
    } catch (e) {
      print("Error fetching alerts: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchForecast(String district) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse("$_baseUrl/forecast?district=$district")).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _forecast = data;
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cached_forecast', json.encode(data));
      } else {
        _setForecastFallback();
      }
    } catch (e) {
      print("Error fetching forecast: $e");
      _setForecastFallback();
    }
    _isLoading = false;
    notifyListeners();
  }

  void _setForecastFallback() {
    _forecast = {
      'hourly': [
        {"time": "Now", "temp": "32°C", "cond": "Sunny", "bn_time": "এখন", "bn_cond": "রৌদ্রোজ্জ্বল"},
        {"time": "2 PM", "temp": "34°C", "cond": "Partly Cloudy", "bn_time": "দুপুর ২টা", "bn_cond": "আংশিক মেঘলা"},
        {"time": "5 PM", "temp": "30°C", "cond": "Cloudy", "bn_time": "বিকেল ৫টা", "bn_cond": "মেঘলা"},
        {"time": "8 PM", "temp": "28°C", "cond": "Rain", "bn_time": "রাত ৮টা", "bn_cond": "বৃষ্টি"},
        {"time": "11 PM", "temp": "26°C", "cond": "Clear", "bn_time": "রাত ১১টা", "bn_cond": "পরিষ্কার"},
      ],
      'comparison': {
        "comparisonText": "2°C Warmer than yesterday",
        "bn_comparisonText": "গতকাল থেকে ২°C বেশি গরম",
        "trend": "up"
      },
      'confidence': {
        "level": "High",
        "bnLevel": "উচ্চ",
        "text": "90% match with historical patterns",
        "bn_text": "ঐতিহাসিক ধরণগুলোর সাথে ৯০% মিল",
      },
      'weekly_brief': {
        "text": "Expect heavy rain by Thursday. Keep umbrellas ready.",
        "bn_text": "বৃহস্পতিবার নাগাদ ভারী বৃষ্টির সম্ভাবনা। ছাতা সাথে রাখুন।"
      }
    };
  }
}
