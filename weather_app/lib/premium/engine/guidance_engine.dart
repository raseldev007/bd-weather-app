import 'package:flutter/material.dart';
import '../models/guidance_models.dart';
import '../models/routine_models.dart';
import 'scoring_rules.dart';
import 'window_finder.dart';

class HourPoint {
  final DateTime t;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double wind;
  final double? gust;
  final double pop; // 0..1
  final int? visibility; // meters
  final String conditionMain;

  const HourPoint({
    required this.t,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.gust,
    required this.pop,
    required this.visibility,
    required this.conditionMain,
  });
}

class GuidanceEngine {
  /// IMPORTANT:
  /// For Premium features (timeline + simulator), you need HOURLY forecast.
  /// Ensure OneCall response includes `hourly` (do not exclude hourly in premium mode).
  static GuidanceResult build({
    required Map<String, dynamic> current,
    required Map<String, dynamic> oneCall, // includes hourly + daily ideally
    required RoutineBundle routine,
    required bool smartEnabled,
  }) {
    final profile = routine.profile;
    final rules = ScoringRules.byProfile(profile);

    // If premium is off, return a minimal result (still safe).
    if (!smartEnabled) {
      return GuidanceResult(
        primaryDecisionLine: "Smart Guidance is off.",
        confidence: ConfidenceLevel.low,
        riskChips: const [],
        bestFocusWindow: null,
        bestCommuteWindow: null,
        bestOutdoorWindow: null,
        planBlocks: const [],
        checklist: const [],
        alerts: const [],
      );
    }

    final hours = _parseHours(oneCall);
    if (hours.isEmpty) { 
       // Fallback if no hourly data
       return GuidanceResult(
        primaryDecisionLine: "No hourly forecast available.",
        confidence: ConfidenceLevel.low,
        riskChips: const [],
        bestFocusWindow: null, bestCommuteWindow: null, bestOutdoorWindow: null,
        planBlocks: const [], checklist: const [], alerts: const []
       );
    }
    
    final horizon = hours.take(24).toList(); // keep next 24h for decisions

    // Scores
    final studyScores   = horizon.map((h) => _studyScore(h, rules)).toList();
    final commuteScores = horizon.map((h) => _commuteScore(h, rules, routine)).toList();
    final outdoorScores = horizon.map((h) => _outdoorScore(h, rules)).toList();

    // Best windows
    final focusIdx = WindowFinder.bestWindowStart(studyScores, 4);
    final commuteIdx = WindowFinder.bestWindowStart(commuteScores, 2);
    final outdoorIdx = WindowFinder.bestWindowStart(outdoorScores, 2);

    final bestFocus = _makeWindow(horizon, studyScores, focusIdx, 4, "Best focus window",
      reasons: _windowReasons(horizon.sublist(focusIdx, (focusIdx + 4).clamp(0, horizon.length)), rules)
    );
    final bestCommute = _makeWindow(horizon, commuteScores, commuteIdx, 2, "Best commute window",
      reasons: _windowReasons(horizon.sublist(commuteIdx, (commuteIdx + 2).clamp(0, horizon.length)), rules)
    );
    final bestOutdoor = _makeWindow(horizon, outdoorScores, outdoorIdx, 2, "Best outdoor window",
      reasons: _windowReasons(horizon.sublist(outdoorIdx, (outdoorIdx + 2).clamp(0, horizon.length)), rules)
    );

    // Chips (top summary)
    final chips = _buildRiskChips(horizon.first, rules);

    // Daily plan blocks
    final plan = _buildPlanBlocks(horizon, studyScores, commuteScores, outdoorScores);

    // Checklist
    final checklist = _buildChecklist(profile, current, horizon.first, rules, routine);

    // Alerts (suggestions; you can schedule later)
    final alerts = _buildAlerts(profile, routine, horizon, bestCommute, bestOutdoor, bestFocus);

    final decisionLine = _primaryDecision(bestFocus, bestCommute, bestOutdoor);

    return GuidanceResult(
      primaryDecisionLine: decisionLine,
      confidence: _confidenceFromHorizon(horizon),
      riskChips: chips,
      bestFocusWindow: bestFocus,
      bestCommuteWindow: bestCommute,
      bestOutdoorWindow: bestOutdoor,
      planBlocks: plan,
      checklist: checklist,
      alerts: alerts,
    );
  }

  // ---------------- Parsing ----------------

  static List<HourPoint> _parseHours(Map<String, dynamic> oneCall) {
    // Handle both 'hourly' (OpenWeather OneCall) and 'list' (OpenWeather 5 Day)
    // The user mentioned ONE CALL, which uses 'hourly'.
    // If we are using 5 Day Forecast, it uses 'list'. Let's support 'list' as fallback if 'hourly' is missing.
    // However, the structure of 'list' is list of objects with 'dt', 'main':{temp..}, 'weather', 'wind', 'pop', 'visibility'.
    // It's mostly compatible.
    
    final hourly = (oneCall["hourly"] as List?) ?? (oneCall["list"] as List?) ?? const [];
    
    return hourly.take(48).map((e) {
      final m = e as Map<String, dynamic>;
      final dt = DateTime.fromMillisecondsSinceEpoch((m["dt"] as int) * 1000, isUtc: true).toLocal();
      final weather0 = (m["weather"] as List?)?.isNotEmpty == true ? (m["weather"][0] as Map) : {};
      
      // OpenWeather 'list' item structure slightly differs from OneCall 'hourly'
      // OneCall: temp is number. 5Day: main.temp is number.
      // We need to robustly parse.
      
      double? temp; 
      double? feelsLike;
      int? humidity;
      double? pressure; // unused here
      
      if (m.containsKey('main')) {
         // 5 Day
         temp = (m['main']['temp'] as num?)?.toDouble();
         feelsLike = (m['main']['feels_like'] as num?)?.toDouble();
         humidity = (m['main']['humidity'] as num?)?.toInt();
      } else {
         // OneCall
         temp = (m['temp'] as num?)?.toDouble();
         feelsLike = (m['feels_like'] as num?)?.toDouble();
         humidity = (m['humidity'] as num?)?.toInt();
      }

      return HourPoint(
        t: dt,
        temp: temp ?? 0,
        feelsLike: feelsLike ?? temp ?? 0,
        humidity: humidity ?? 0,
        wind: (m.containsKey('wind') ? (m['wind']['speed'] as num?)?.toDouble() : (m['wind_speed'] as num?)?.toDouble()) ?? 0,
        gust: (m.containsKey('wind') ? (m['wind']['gust'] as num?)?.toDouble() : (m['wind_gust'] as num?)?.toDouble()),
        pop: (m["pop"] as num?)?.toDouble() ?? 0,
        visibility: (m["visibility"] as num?)?.toInt(),
        conditionMain: (weather0["main"] as String?) ?? "Unknown",
      );
    }).toList();
  }

  // ---------------- Scores ----------------

  static int _clamp100(double v) => v.clamp(0, 100).round();

  static int _tempComfort(double feelsLike, RuleSet r) {
    // 100 at ideal center, drops linearly outside
    final center = (r.tempIdealMin + r.tempIdealMax) / 2.0;
    final halfRange = (r.tempIdealMax - r.tempIdealMin) / 2.0;
    final dist = (feelsLike - center).abs();
    final score = 100 - (dist / (halfRange + 6.0)) * 100; // +6 softens penalty
    return _clamp100(score);
  }

  static int _humidityComfort(int humidity, RuleSet r) {
    if (humidity <= r.humidityIdealMax) return 100;
    final over = (humidity - r.humidityIdealMax).toDouble();
    return _clamp100(100 - over * 2.2); // tune
  }

  static int _rainPenalty(double pop, RuleSet r) {
    if (pop >= r.popHigh) return 55;
    if (pop >= r.popMed) return 25;
    return 0;
  }

  static int _windPenalty(double wind, RuleSet r) {
    if (wind >= r.windHigh) return 35;
    if (wind >= r.windMed) return 15;
    return 0;
  }

  static int _visibilityPenalty(int? vis, RuleSet r) {
    if (vis == null) return 0;
    if (vis < r.visibilityLow) return 20;
    return 0;
  }

  static int _studyScore(HourPoint h, RuleSet r) {
    final t = _tempComfort(h.feelsLike, r);
    final hum = _humidityComfort(h.humidity, r);
    final rain = _rainPenalty(h.pop, r);
    final wind = _windPenalty(h.wind, r);

    // Distraction proxy: rain + wind
    final score = 0.55 * t + 0.35 * hum - 0.6 * rain - 0.4 * wind;
    return _clamp100(score);
  }

  static int _commuteScore(HourPoint h, RuleSet r, RoutineBundle routine) {
    final rain = _rainPenalty(h.pop, r);
    final wind = _windPenalty(h.wind, r);
    final vis = _visibilityPenalty(h.visibility, r);

    // Base 100 minus penalties
    final score = 100 - (1.1 * rain + 0.9 * wind + 1.0 * vis);

    // Walking is more sensitive to rain/heat
    final commuteMode = routine.general?.commuteMode;
    final modePenalty = (commuteMode == null) ? 0 : (commuteMode == CommuteMode.walk ? 8 : 0);

    return _clamp100(score - modePenalty);
  }

  static int _outdoorScore(HourPoint h, RuleSet r) {
    final t = _tempComfort(h.feelsLike, r);
    final rain = _rainPenalty(h.pop, r);
    final wind = _windPenalty(h.wind, r);
    final score = 0.7 * t - 0.8 * rain - 0.5 * wind + 20; // bias to allow “okay” time
    return _clamp100(score);
  }



  // ---------------- Outputs ----------------

  static TimeWindow _makeWindow(
    List<HourPoint> horizon,
    List<int> scores,
    int startIdx,
    int size,
    String label, {
    required List<String> reasons,
  }) {
    final s = startIdx.clamp(0, horizon.length - 1);
    final e = (s + size).clamp(1, horizon.length);
    final windowScore = (scores.sublist(s, e).reduce((a, b) => a + b) / (e - s)).round();
    return TimeWindow(
      start: horizon[s].t,
      end: horizon[e - 1].t.add(const Duration(hours: 1)),
      score: windowScore,
      label: label,
      reasons: reasons,
    );
  }

  static List<String> _windowReasons(List<HourPoint> hrs, RuleSet r) {
    if (hrs.isEmpty) return const [];
    final avgPop = hrs.map((h) => h.pop).reduce((a, b) => a + b) / hrs.length;
    final avgWind = hrs.map((h) => h.wind).reduce((a, b) => a + b) / hrs.length;
    final avgFeels = hrs.map((h) => h.feelsLike).reduce((a, b) => a + b) / hrs.length;
    return [
      "Low rain risk (~${(avgPop * 100).round()}%)",
      "Wind ~${avgWind.toStringAsFixed(1)} m/s",
      "Feels like ~${avgFeels.toStringAsFixed(1)}°C",
    ];
  }



  static List<RiskChip> _buildRiskChips(HourPoint now, RuleSet r) {
    // Rain chip
    final rainLevel = now.pop >= r.popHigh ? RiskLevel.high : (now.pop >= r.popMed ? RiskLevel.medium : RiskLevel.low);
    final rainText = rainLevel == RiskLevel.high ? "HIGH" : (rainLevel == RiskLevel.medium ? "MED" : "LOW");

    // Heat/Cold chip (based on feels_like vs ideal)
    final tempComfort = _tempComfort(now.feelsLike, r);
    final stressLevel = tempComfort < 55 ? RiskLevel.high : (tempComfort < 75 ? RiskLevel.medium : RiskLevel.low);
    final stressText = stressLevel == RiskLevel.high ? "STRONG" : (stressLevel == RiskLevel.medium ? "MILD" : "LOW");

    // Wind/Visibility chip
    final wLevel = now.wind >= r.windHigh ? RiskLevel.high : (now.wind >= r.windMed ? RiskLevel.medium : RiskLevel.low);
    final vPenalty = _visibilityPenalty(now.visibility, r);
    final mix = (wLevel == RiskLevel.high || vPenalty > 0) ? RiskLevel.medium : RiskLevel.low;
    final mixText = mix == RiskLevel.medium ? "CAUTION" : "GOOD";

    return [
      RiskChip(
        title: "Rain",
        level: rainLevel,
        shortText: rainText,
        icon: Icons.umbrella,
        reasons: ["Rain probability ${(now.pop * 100).round()}%"],
      ),
      RiskChip(
        title: "Temp Stress",
        level: stressLevel,
        shortText: stressText,
        icon: Icons.thermostat,
        reasons: ["Feels like ${now.feelsLike.toStringAsFixed(1)}°C", "Comfort score $tempComfort/100"],
      ),
      RiskChip(
        title: "Wind/Vis",
        level: mix,
        shortText: mixText,
        icon: Icons.air,
        reasons: [
          "Wind ${now.wind.toStringAsFixed(1)} m/s",
          if (now.visibility != null) "Visibility ${now.visibility} m",
        ],
      ),
    ];
  }

  static List<PlanBlock> _buildPlanBlocks(
    List<HourPoint> horizon,
    List<int> study,
    List<int> commute,
    List<int> outdoor,
  ) {
    // 4 blocks based on local day segments
    DateTime dayStart = DateTime(horizon.first.t.year, horizon.first.t.month, horizon.first.t.day);

    final blocks = <(PlanBlockId, int, int)>[
      (PlanBlockId.morning, 6, 11),
      (PlanBlockId.noon, 11, 15),
      (PlanBlockId.evening, 15, 19),
      (PlanBlockId.night, 19, 23),
    ];

    PlanBlock buildBlock(PlanBlockId id, int startHour, int endHour) {
      final start = dayStart.add(Duration(hours: startHour));
      final end = dayStart.add(Duration(hours: endHour));
      final idxs = <int>[];

      for (int i = 0; i < horizon.length; i++) {
        if (!horizon[i].t.isBefore(start) && horizon[i].t.isBefore(end)) idxs.add(i);
      }
      if (idxs.isEmpty) idxs.add(0);

      int avg(List<int> s) => (idxs.map((i) => s[i]).reduce((a, b) => a + b) / idxs.length).round();

      final st = avg(study);
      final cm = avg(commute);
      final od = avg(outdoor);

      final doThis = <String>[
        if (st >= 75) "Good for focused study",
        if (cm >= 75) "Safe commute window",
        if (od >= 70) "Comfortable outdoor time",
      ].take(2).toList();

      final avoidThis = <String>[
        if (cm < 55) "Avoid travel if possible",
        if (od < 50) "Avoid outdoor activity",
        if (st < 55) "Study comfort may drop",
      ].take(2).toList();

      return PlanBlock(
        id: id,
        start: start,
        end: end,
        studyScore: st,
        commuteScore: cm,
        outdoorScore: od,

        doThis: doThis.isEmpty ? ["Normal conditions"] : doThis,
        avoidThis: avoidThis,
        confidence: ConfidenceLevel.medium,
      );
    }

    return blocks.map((b) => buildBlock(b.$1, b.$2, b.$3)).toList();
  }

  static List<ChecklistItem> _buildChecklist(
    OutcomeProfileId profile,
    Map<String, dynamic> current,
    HourPoint now,
    RuleSet r,
    RoutineBundle routine,
  ) {
    final items = <ChecklistItem>[];

    final feels = now.feelsLike;
    final pop = now.pop;
    final wind = now.wind;

    // Universal
    if (pop >= r.popMed) {
      items.add(const ChecklistItem(
        id: "umbrella",
        title: "Carry umbrella",
        subtitle: "Rain risk is elevated today",
        icon: Icons.umbrella,
        severity: RiskLevel.medium,
      ));
    }
    if (feels <= 18) {
      items.add(const ChecklistItem(
        id: "jacket",
        title: "Light jacket",
        subtitle: "Cool conditions expected",
        icon: Icons.checkroom,
        severity: RiskLevel.low,
      ));
    }
    if (feels >= 32) {
      items.add(const ChecklistItem(
        id: "water",
        title: "Carry water",
        subtitle: "Heat stress may increase",
        icon: Icons.water_drop,
        severity: RiskLevel.medium,
      ));
    }

    // Study
    items.add(const ChecklistItem(
      id: "leave_early",
      title: "Leave 10–15 min early",
      subtitle: "Buffer for traffic/weather changes",
      icon: Icons.access_time,
      severity: RiskLevel.low,
    ));

    return items.take(6).toList();
  }

  static List<AlertSuggestion> _buildAlerts(
    OutcomeProfileId profile,
    RoutineBundle routine,
    List<HourPoint> horizon,
    TimeWindow bestCommute,
    TimeWindow bestOutdoor,
    TimeWindow? bestFocus,
  ) {
    final alerts = <AlertSuggestion>[];

    // “Best outdoor starts soon”
    final now = DateTime.now();
    if (bestOutdoor.start.isAfter(now) && bestOutdoor.start.difference(now).inMinutes <= 90) {
      alerts.add(AlertSuggestion(
        id: "outdoor_window",
        title: "Best outdoor window soon",
        body: "Best outdoor time starts at ${_hm(bestOutdoor.start)}.",
        fireAt: bestOutdoor.start.subtract(const Duration(minutes: 20)),
        severity: RiskLevel.low,
      ));
    }

    // reminder before study (if set)
    final studyTime = routine.general?.studyTime;
    if (studyTime != null) {
      final t = DateTime(now.year, now.month, now.day, studyTime.hour, studyTime.minute);
      alerts.add(AlertSuggestion(
        id: "study_leave",
        title: "Study time reminder",
        body: "Check commute risk before leaving. Best commute: ${_hm(bestCommute.start)}–${_hm(bestCommute.end)}.",
        fireAt: t.subtract(const Duration(minutes: 30)),
        severity: RiskLevel.low,
      ));
    }

    return alerts;
  }

  static String _primaryDecision(
    TimeWindow? focus,
    TimeWindow commute,
    TimeWindow outdoor,
  ) {
    return "Best focus: ${_hm(focus?.start)}–${_hm(focus?.end)} • Best commute: ${_hm(commute.start)}–${_hm(commute.end)}.";
  }

  static ConfidenceLevel _confidenceFromHorizon(List<HourPoint> horizon) {
    // Simple confidence: closer horizon = higher confidence
    if (horizon.isEmpty) return ConfidenceLevel.low;
    final now = DateTime.now();
    final first = horizon.first.t;
    final deltaH = first.difference(now).inHours.abs();
    if (deltaH <= 1) return ConfidenceLevel.high;
    if (deltaH <= 6) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  static String _hm(DateTime? t) {
    if (t == null) return "--:--";
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }
}
