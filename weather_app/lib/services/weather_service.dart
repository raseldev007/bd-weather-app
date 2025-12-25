import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'profile_service.dart';
import 'weather_insight_service.dart';

class HomeInsights {
  final Map<String, dynamic> currentWeather;
  final Map<String, dynamic> primaryInsight;
  final List<dynamic> hourlyRisk;

  HomeInsights({
    required this.currentWeather,
    required this.primaryInsight,
    required this.hourlyRisk,
  });

  factory HomeInsights.fromJson(Map<String, dynamic> json) {
    return HomeInsights(
      currentWeather: json['current_weather'],
      primaryInsight: json['primary_insight'],
      hourlyRisk: json['hourly_risk'],
    );
  }
}

class WeatherService extends ChangeNotifier {
  HomeInsights? _homeInsights;
  List<Map<String, dynamic>> _alerts = [];
  Map<String, dynamic>? _forecast;
  bool _isLoading = false;
  
  // API Configuration
  final String _apiKey = '8fec44d87737fac7b4fed3d7be924b7b';
  final String _baseUrl = 'https://api.openweathermap.org/data/2.5';

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

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  Future<void> fetchHomeInsights(String district, ProfileService profile) async {
    _isLoading = true;
    notifyListeners();
    try {
      Position position = await _determinePosition();
      
      // Fetch Current Weather from OWM
      final weatherResponse = await http.get(
        Uri.parse("$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric"),
      );

      if (weatherResponse.statusCode == 200) {
        final data = json.decode(weatherResponse.body);
        
        // Transform OWM data to app internal model
        final currentTemp = (data['main']['temp'] as num?)?.toDouble() ?? 0.0;
        final currentHumidity = (data['main']['humidity'] as num?)?.toDouble() ?? 0.0;
        
        String condition = "Unknown";
        String description = "";
        
        if (data['weather'] != null && (data['weather'] as List).isNotEmpty) {
           condition = data['weather'][0]['main']?.toString() ?? "Unknown";
           description = data['weather'][0]['description']?.toString() ?? "";
        }

        final city = data['name']?.toString() ?? "Location";
        final windSpeed = (data['wind'] != null) ? (data['wind']['speed'] as num?)?.toDouble() ?? 0.0 : 0.0;

        // --- Calculate Insights Locally ---
        const lang = 'en'; 
        
        OutcomeState? newWorkState;
        OutcomeState? newFarmState;
        Map<String, String> workCopy = {};
        Map<String, String> farmCopy = {};

        // Generate Primary Insight based on temp for now (can be expanded)
        String insightTitle = "Safe Conditions";
        String insightBody = "Weather is suitable for outdoor activities.";
        String severity = "safe";

        if (currentTemp > 35) {
          insightTitle = "Heat Warning";
          insightBody = "Extreme heat. Stay hydrated and avoid direct sun.";
          severity = "high";
        } else if (condition.toLowerCase().contains("rain")) {
          insightTitle = "Rain Alert";
          insightBody = "Rain detected. Carry an umbrella.";
          severity = "medium";
        }

        if (profile.isPremium) {
           // Reuse existing logic from WeatherInsightService if applicable
           final workData = WeatherInsightService.getWorkSafetyStatus(currentTemp, currentHumidity, condition, lang);
           newWorkState = workData['state'] as OutcomeState;
           workCopy = WeatherInsightService.getNotificationCopy(profile.lastWorkState, newWorkState, UserMode.worker, lang);

           final farmData = WeatherInsightService.getCropRiskData(currentTemp, condition, 0.0, lang); // Wind 0 for now
           newFarmState = farmData['state'] as OutcomeState;
           farmCopy = WeatherInsightService.getNotificationCopy(profile.lastFarmState, newFarmState, UserMode.farmer, lang);
        }

        // Construct HomeInsights object
        final internalData = {
          "current_weather": {
            "temp": currentTemp,
            "condition": condition,
            "humidity": currentHumidity,
            "wind": windSpeed,
            "district": city,
            "description": description
          },
          "primary_insight": {
            "title": insightTitle,
            "body": insightBody,
            "severity": severity
          },
          "hourly_risk": [] // Placeholder as OWM Free API doesn't give hourly risk easily without 2.5/forecast call
        };

        _homeInsights = HomeInsights.fromJson(internalData);

        // Update Profile logic
        await profile.updateStates(
          workState: newWorkState,
          farmState: newFarmState,
          title: profile.mode == UserMode.worker ? workCopy['title'] : farmCopy['title'],
          body: profile.mode == UserMode.worker ? workCopy['body'] : farmCopy['body'],
        );

        // Save to cache
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cached_home_insights', json.encode(internalData));
      }
    } catch (e) {
      debugPrint("Error fetching live weather: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAlerts(String district) async {
    // OWM Free tier doesn't support alerts API, keeping empty or mock implementation for now
    _alerts = [];
    notifyListeners();
  }

  Future<void> fetchForecast(String district) async {
    // For 7 day forecast, OWM OneCall is needed (paid/separate). 
    // Standard callback for 5 day / 3 hour exists but requires more parsing.
    // Keeping fallback for now to avoid breaking UI.
    _setForecastFallback();
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
        "comparisonText": "No historical data",
        "bn_comparisonText": "কোনো ঐতিহাসিক তথ্য নেই",
        "trend": "neutral"
      },
      'confidence': {
        "level": "N/A",
        "bnLevel": "প্রযোজ্য নয়",
        "text": "Requires Premium API",
        "bn_text": "প্রিমিয়াম API প্রয়োজন",
      },
      'weekly_brief': {
        "text": "Live forecast coming soon.",
        "bn_text": "লাইভ পূর্বাভাস শীঘ্রই আসছে।"
      }
    };
  }
}
