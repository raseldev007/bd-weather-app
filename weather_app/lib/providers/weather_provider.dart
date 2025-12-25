import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/weather_service.dart';
import '../services/weather_insight_service.dart';
import '../services/profile_service.dart'; // To access UserMode
import '../premium/engine/guidance_engine.dart';
import '../premium/smart_guidance_provider.dart';
import '../premium/models/guidance_models.dart';
import '../premium/models/routine_models.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

enum WeatherMode { auto, manual }

/// V2/V3 Premium Data Model
class UIHomeInsights {
  // HERO SECTION
  final Map<String, dynamic> hero; // {temp, condition, feelsLike, chips: [], actionSentence, raw: {temp, humidity, wind}}
  // Added 'raw' to hero to allow Context Switching in UI to re-derive summaries without API call
  
  // MODULES / TABS DATA
  final Map<String, dynamic> study; // {score, label, color, tips: [], signals: {temp, humidity, noise}}
  final Map<String, dynamic> commute; // {score, label, color, tips: []}
  
  // TIMELINE
  final List<Map<String, dynamic>> tomorrowTimeline; // [{time, icon, temp}]
  final List<Map<String, dynamic>> bestTimeTimeline; // [{period, study, commute, outdoor}] V3
  
  // CHECKLIST
  final List<Map<String, dynamic>> checklist; // [{text, icon, color, isDone}]

  // OLD SUPPORT
  final Map<String, dynamic>? cropRisk; 
  final Map<String, dynamic>? workSafety;

  UIHomeInsights({
    required this.hero,
    required this.study,
    required this.commute,
    required this.tomorrowTimeline,
    required this.bestTimeTimeline,
    required this.checklist,
    this.cropRisk,
    this.workSafety,
  });
}

class WeatherProvider extends ChangeNotifier {
  Map<String, dynamic>? currentWeather;
  Map<String, dynamic>? forecast;
  
  // Premium Feature Object
  UIHomeInsights? homeInsights;

  bool isLoading = false;
  String? error;

  WeatherMode mode = WeatherMode.auto;
  String? selectedName;

  double? lastLat;
  double? lastLon;
  
  // V4 Field
  GuidanceResult? guidanceV4;

  // Live Auto-Location Fields
  final LocationService _locationService = LocationService();
  bool liveAutoEnabled = false;
  StreamSubscription<Position>? _posSub;
  DateTime? _lastAutoUpdateTime;

  // V4 Getters
  Map<String, dynamic>? get rawWeather => currentWeather;
  List<dynamic>? get hourlyForecast => (forecast != null && forecast!['list'] != null)
      ? forecast!['list']
      : (forecast != null && forecast!['hourly'] != null) ? forecast!['hourly'] : null;

  // V4 Helpers
  List<dynamic> get premiumHourly {
    final oneCall = _ensureOneCallShape(forecast);
    return (oneCall["hourly"] as List?) ?? [];
  }
  
  List<dynamic> get horizon24 => premiumHourly.take(24).toList();

  // Helper: Normalize Forecast Data
  Map<String, dynamic> _ensureOneCallShape(Map<String, dynamic>? fc) {
    if (fc == null) return {"hourly": []};

    if (fc["hourly"] is List) return fc;

    // OpenWeather 5-day/3-hour forecast shape: { list: [ ... ] }
    if (fc["list"] is List) {
      final list = (fc["list"] as List).cast<Map<String, dynamic>>();

      final hourly = list.map((e) {
        final weather0 = (e["weather"] is List && (e["weather"] as List).isNotEmpty)
            ? (e["weather"][0] as Map<String, dynamic>)
            : <String, dynamic>{};

        return <String, dynamic>{
          "dt": e["dt"], // unix seconds
          "temp": (e["main"]?["temp"] as num?)?.toDouble() ?? 0.0,
          "feels_like": (e["main"]?["feels_like"] as num?)?.toDouble() ??
              (e["main"]?["temp"] as num?)?.toDouble() ?? 0.0,
          "humidity": (e["main"]?["humidity"] as num?)?.toInt() ?? 0,
          "wind_speed": (e["wind"]?["speed"] as num?)?.toDouble() ?? 0.0,
          "wind_gust": (e["wind"]?["gust"] as num?)?.toDouble(),
          "pop": (e["pop"] as num?)?.toDouble() ?? 0.0,
          "visibility": (e["visibility"] as num?)?.toInt(),
          "weather": [
            {"main": (weather0["main"] ?? "Unknown").toString()}
          ],
        };
      }).toList();

      return {"hourly": hourly, "daily": fc["daily"]};
    }

    return {"hourly": []};
  }

  final WeatherService _service = WeatherService();

  Future<void> loadByLocation(double lat, double lon, {WeatherMode? setMode, String? name, required ProfileService profile, required String language, SmartGuidanceProvider? smart}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      if (setMode != null) mode = setMode;

      // Ensure stable coordinates
      lastLat = lat;
      lastLon = lon;
      
      // Update selected name logic
      selectedName = name ?? "My Location";

      // 1. Fetch Raw Data (Parallel-ish)
      final weatherFuture = _service.getCurrentByLocation(lat, lon);
      final forecastFuture = _service.get7DayForecast(lat, lon);
      
      final results = await Future.wait([weatherFuture, forecastFuture]);
      
      currentWeather = results[0];
      forecast = results[1];
      
      // 2. Generate Premium Insights
      if (currentWeather != null) {
          // V4 Integration Pipeline
          final oneCall = _ensureOneCallShape(forecast);
          
          if (smart != null) {
              final routine = smart.routine;
              final smartEnabled = smart.isEnabled;

              guidanceV4 = GuidanceEngine.build(
                 current: currentWeather!,
                 oneCall: oneCall,
                 routine: routine,
                 smartEnabled: smartEnabled,
              );
              
              smart.updateGuidance(guidanceV4);

              homeInsights = _mapGuidanceToUIHomeInsights(
                 currentWeather!,
                 oneCall,
                 guidanceV4!,
                 profile,
                 language
              );
          } else {
             // Fallback if smart provider not passed (should not happen in updated UI)
             // Maybe recreate legacy insights or empty
          }
          
          if (name == null) {
             selectedName = currentWeather!['name'];
          }
      }

    } catch (e) {
      error = e.toString();
      debugPrint("Weather Provider Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }



  void _generatePremiumInsightsV2(Map<String, dynamic> current, Map<String, dynamic>? forecast, ProfileService profile, String language) {
      final temp = (current['main']['temp'] as num?)?.toDouble() ?? 0.0;
      final humidity = (current['main']['humidity'] as num?)?.toDouble() ?? 0.0;
      final feelsLike = (current['main']['feels_like'] as num?)?.toDouble() ?? temp;
      final wind = (current['wind']['speed'] as num?)?.toDouble() ?? 0.0;
      final condition = (current['weather'] != null && (current['weather'] as List).isNotEmpty) 
          ? current['weather'][0]['main'].toString() : "Clear";
      
      // Hourly Data
      List<dynamic> hourly = (forecast != null && forecast['hourly'] != null) ? forecast['hourly'] : [];
      
      // 1. HERO DATA (Initial Default)
      final tenSec = WeatherInsightService.getTenSecondSummary(temp, feelsLike, hourly, language);
      final heroData = {
        "temp": temp,
        "feelsLike": feelsLike,
        "condition": condition,
        "heatStress": tenSec['heatStress'],
        "rainRisk": tenSec['rainRisk'],
        "action": tenSec['action'],
        "raw": {
           "temp": temp, "humidity": humidity, "wind": wind, "condition": condition
        }
      };
      
      
      // 2. SCORES
      var studyScore = WeatherInsightService.getStudyComfortScore(temp, humidity);
      studyScore['signals'] = WeatherInsightService.getDetailedStudySignals(temp, humidity, wind);
      
      // V4: Best Focus Window based on Prefs
      final focusWindow = WeatherInsightService.getBestFocusWindow(hourly, profile.studyTimePref);
      studyScore['bestWindow'] = focusWindow; // Attach to study module

      final commuteScore = WeatherInsightService.getCommuteRiskScore(0, wind, condition);

      // 3. CHECKLIST
      final checklist = WeatherInsightService.getChecklist(temp, humidity, condition, language);
      
      // 4. TIMELINES
      final timeline = WeatherInsightService.getTomorrowMorningTimeline(hourly, language);
      final bestTimeTimeline = WeatherInsightService.getBestTimeTimeline(hourly, language); 
      
      // V4 Plan
      // We can use bestTimeTimeline as the source for the Plan Tab for now, 
      // or key the 'dailyPlan' if we want a different structure. 
      // Reuse bestTimeTimeline since it already has Morning/Noon/Eve structure which matches Step 11 "Daily Plan".

      // 5. OLD SPECIALIZED
      Map<String, dynamic>? cropRisk;
      Map<String, dynamic>? workSafety;
      cropRisk = null;
      workSafety = null;

      homeInsights = UIHomeInsights(
        hero: heroData,
        study: studyScore,
        commute: commuteScore,
        tomorrowTimeline: timeline,
        bestTimeTimeline: bestTimeTimeline, // Usage for Planner Tab
        checklist: checklist,
        cropRisk: cropRisk,
        workSafety: workSafety
      );
  }

  Future<void> refresh(ProfileService profile, String language, {SmartGuidanceProvider? smart}) async {
    if (lastLat == null || lastLon == null) return;
    await loadByLocation(lastLat!, lastLon!, name: selectedName, profile: profile, language: language, smart: smart);
  }

  // V4 Helpers
  RoutineBundle _routineFromProfile(ProfileService profile) {
    return const RoutineBundle(
      profile: OutcomeProfileId.general,
      general: GeneralRoutine(commuteMode: CommuteMode.walk),
    );
  }

  UIHomeInsights _mapGuidanceToUIHomeInsights(
    Map<String, dynamic> current,
    Map<String, dynamic> oneCall,
    GuidanceResult g,
    ProfileService profile,
    String language,
  ) {
    final temp = (current['main']['temp'] as num?)?.toDouble() ?? 0.0;
    final humidity = (current['main']['humidity'] as num?)?.toDouble() ?? 0.0;
    final feelsLike = (current['main']['feels_like'] as num?)?.toDouble() ?? temp;
    final wind = (current['wind']['speed'] as num?)?.toDouble() ?? 0.0;
    final condition = (current['weather'] is List && (current['weather'] as List).isNotEmpty)
        ? current['weather'][0]['main'].toString()
        : "Clear";

    // Risk chips
    String rainRisk = g.riskChips.isNotEmpty ? g.riskChips[0].shortText : "LOW";
    String heatStress = g.riskChips.length > 1 ? g.riskChips[1].shortText : "LOW";

    final heroData = {
      "temp": temp,
      "feelsLike": feelsLike,
      "condition": condition,
      "rainRisk": rainRisk,
      "heatStress": heatStress,
      "action": g.primaryDecisionLine,
      "chips": g.riskChips.map((c) => {
        "title": c.title,
        "level": c.level.name,
        "text": c.shortText,
        "reasons": c.reasons,
      }).toList(),
      "raw": {"temp": temp, "humidity": humidity, "wind": wind, "condition": condition},
    };

    // Study module
    final study = {
      "score": g.bestFocusWindow?.score ?? 0,
      "label": (g.bestFocusWindow != null) ? "BEST WINDOW" : "—",
      "signals": {
        "temp": "based",
        "humidity": "based",
        "noise": "based",
      },
      "bestWindow": (g.bestFocusWindow == null) ? null : {
        "start": g.bestFocusWindow!.start.toIso8601String(),
        "end": g.bestFocusWindow!.end.toIso8601String(),
        "score": g.bestFocusWindow!.score,
        "reasons": g.bestFocusWindow!.reasons,
      },
    };

    // Commute module
    final commute = {
      "score": g.bestCommuteWindow?.score ?? 0,
      "label": (g.bestCommuteWindow != null) ? "BEST WINDOW" : "—",
      "bestWindow": (g.bestCommuteWindow == null) ? null : {
        "start": g.bestCommuteWindow!.start.toIso8601String(),
        "end": g.bestCommuteWindow!.end.toIso8601String(),
        "score": g.bestCommuteWindow!.score,
        "reasons": g.bestCommuteWindow!.reasons,
      },
    };

    // Plan tab timeline
    final bestTimeTimeline = g.planBlocks.map((b) {
      String period = b.id.name; 
      return {
        "period": period,
        "study": b.studyScore,
        "commute": b.commuteScore,
        "outdoor": b.outdoorScore,

        "do": b.doThis,
        "avoid": b.avoidThis,
        "confidence": b.confidence.name,
      };
    }).toList();

    // Checklist
    final checklist = g.checklist.map((c) => {
      "id": c.id,
      "text": c.title,
      "subtitle": c.subtitle,
      "severity": c.severity.name,
      "isDone": false,
      "icon": c.icon,
      "color": (c.severity == RiskLevel.high) ? Colors.red : ((c.severity == RiskLevel.medium) ? Colors.orange : Colors.blueGrey),
    }).toList();

    // Tomorrow (Keep existing logic or derive from g)
    final tomorrowTimeline = WeatherInsightService.getTomorrowMorningTimeline(
      (oneCall["hourly"] as List?) ?? [],
      language,
    );

    Map<String, dynamic>? cropRisk;
    Map<String, dynamic>? workSafety;

    return UIHomeInsights(
      hero: heroData,
      study: study,
      commute: commute,
      tomorrowTimeline: tomorrowTimeline,
      bestTimeTimeline: bestTimeTimeline,
      checklist: checklist,
      cropRisk: cropRisk,
      workSafety: workSafety,
    );
  }

  // --- LIVE AUTO-LOCATION METHODS ---

  Future<void> enableLiveAuto(ProfileService profile, String language, SmartGuidanceProvider? smart) async {
    if (liveAutoEnabled) return;

    try {
      // Get initial position
      Position pos = await _locationService.getCurrentLocation();
      liveAutoEnabled = true;
      notifyListeners();

      // Initial load
      await loadByLocation(
        pos.latitude,
        pos.longitude,
        setMode: WeatherMode.auto,
        name: "My Location",
        profile: profile,
        language: language,
        smart: smart,
      );
      _lastAutoUpdateTime = DateTime.now();

      // Start watching
      _posSub = _locationService.watchLiveLocation(distanceFilter: 100).listen((newPos) async {
        if (!liveAutoEnabled) return;

        double distance = 0;
        if (lastLat != null && lastLon != null) {
          distance = Geolocator.distanceBetween(lastLat!, lastLon!, newPos.latitude, newPos.longitude);
        }

        bool timePassed = false;
        if (_lastAutoUpdateTime != null) {
          timePassed = DateTime.now().difference(_lastAutoUpdateTime!).inMinutes > 30;
        }

        if (distance > 200 || timePassed || _lastAutoUpdateTime == null) {
           await loadByLocation(
             newPos.latitude,
             newPos.longitude,
             setMode: WeatherMode.auto,
             name: "My Location",
             profile: profile,
             language: language,
             smart: smart,
           );
           _lastAutoUpdateTime = DateTime.now();
        }
      });
    } catch (e) {
      liveAutoEnabled = false;
      error = e.toString();
      notifyListeners();
    }
  }

  void disableLiveAuto() {
    liveAutoEnabled = false;
    _posSub?.cancel();
    _posSub = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }
}
