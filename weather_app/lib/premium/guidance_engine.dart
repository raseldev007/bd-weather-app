
import 'package:flutter/material.dart';
import 'outcome_profiles.dart';

class GuidanceResult {
  final String primaryDecisionLine;
  final List<Map<String, dynamic>> riskChips;
  final String confidenceBadge; // HIGH, MED, LOW
  final Map<String, dynamic> bestWindows;
  final List<Map<String, dynamic>> dailyPlanBlocks;
  final List<Map<String, dynamic>> checklistItems;
  final List<Map<String, dynamic>> alerts;

  GuidanceResult({
    required this.primaryDecisionLine,
    required this.riskChips,
    required this.confidenceBadge,
    required this.bestWindows,
    required this.dailyPlanBlocks,
    required this.checklistItems,
    required this.alerts,
  });
}

class GuidanceEngine {
  
  static GuidanceResult generate(
    OutcomeProfile profile,
    Map<String, dynamic> weatherCurrent,
    List<dynamic> hourlyForecast,
    Map<String, dynamic> routineSettings
  ) {
    // 1. Extract Weather Basics
    double temp = (weatherCurrent['main']['temp'] as num).toDouble();
    double humidity = (weatherCurrent['main']['humidity'] as num).toDouble();
    double wind = (weatherCurrent['wind']['speed'] as num).toDouble();
    String condition = weatherCurrent['weather'][0]['main'].toString();
    
    // 2. Calculate Scores
    var scores = _calculateHourlyScores(hourlyForecast, profile);
    
    // 3. Determine Highlights based on Profile
    String decision = "Enjoy your day!";
    List<Map<String, dynamic>> chips = [];
    String confidence = "HIGH";
    
    if (profile.id == 'student') {
       decision = _getStudentDecision(scores, temp, condition);
       chips = _getStudentRisks(temp, condition);
    } else if (profile.id == 'farmer') {
       decision = _getFarmerDecision(scores, condition);
       chips = _getFarmerRisk(wind, condition);
    } else if (profile.id == 'worker') {
       decision = _getWorkerDecision(scores, temp);
       chips = _getWorkerRisks(temp, condition);
    } else {
       // General
       decision = _getGeneralDecision(scores, condition);
       chips = _getGeneralRisks(condition);
    }

    // 4. Generate Blocks
    var blocks = _generateDailyBlocks(scores, profile);
    
    // 5. Generate Checklist
    var checklist = _generateChecklist(profile, temp, condition);

    return GuidanceResult(
      primaryDecisionLine: decision,
      riskChips: chips,
      confidenceBadge: confidence,
      bestWindows: {
        "bestFocus": scores['bestFocus'],
        "bestOutdoor": scores['bestOutdoor']
      },
      dailyPlanBlocks: blocks,
      checklistItems: checklist,
      alerts: []
    );
  }

  static Map<String, dynamic> _calculateHourlyScores(List<dynamic> hourly, OutcomeProfile profile) {
     // Simplified Scoring for prototype
     // iterate hourly, compute 0-100 for study, outdoor, commute
     
     // Mocking "Best Windows" for now
     return {
       "bestFocus": "6-9 AM",
       "bestOutdoor": "5-7 PM"
     };
  }
  
  static String _getStudentDecision(Map scores, double temp, String condition) {
    if (condition.contains("Rain")) return "Expect rain delays. Pack waterproofs.";
    if (temp > 35) return "Heat stress high. Study indoors.";
    return "Great day for focused study!";
  }
  
  static List<Map<String, dynamic>> _getStudentRisks(double temp, String condition) {
    List<Map<String, dynamic>> list = [];
    if (temp > 32) list.add({"label": "Heat", "color": Colors.red});
    if (condition.contains("Rain")) list.add({"label": "Rain", "color": Colors.orange});
    return list;
  }
  
  // ... similar helper methods for other profiles (omitted for brevity in initial file creation, will expand)
  
  static String _getFarmerDecision(Map scores, String condition) {
     if (condition.contains("Rain")) return "Do NOT spray today. Rain likely.";
     return "Good window for spraying: 8-11 AM.";
  }
  
  static List<Map<String, dynamic>> _getFarmerRisk(double wind, String condition) {
     List<Map<String, dynamic>> list = [];
     if (wind > 10) list.add({"label": "Windy", "color": Colors.orange});
     if (condition.contains("Rain")) list.add({"label": "Rain", "color": Colors.red});
     return list;
  }

  static String _getWorkerDecision(Map scores, double temp) {
     if (temp > 38) return "Danger: Heat Stroke Risk. Limit outdoor work.";
     return "Work conditions are safe until 12 PM.";
  }

  static List<Map<String, dynamic>> _getWorkerRisks(double temp, String condition) {
     List<Map<String, dynamic>> list = [];
    if (temp > 35) list.add({"label": "High Heat", "color": Colors.red});
    if (condition.contains("Storm")) list.add({"label": "Lightning", "color": Colors.red});
    return list;
  }
  
  static String _getGeneralDecision(Map scores, String condition) {
    if (condition.contains("Rain")) return "Carry an umbrella. Commute delays likely.";
    return "Weather is pleasant for outdoor plans.";
  }
  
  static List<Map<String, dynamic>> _getGeneralRisks(String condition) {
     if (condition.contains("Rain")) return [{"label": "Rain", "color": Colors.orange}];
     return [];
  }

  static List<Map<String, dynamic>> _generateDailyBlocks(Map scores, OutcomeProfile profile) {
    // Generate 4 blocks: Morning, Noon, Evening, Night
    // Logic should check hourly forecast for each block
    return [
      {"period": "Morning", "status": "Good", "action": "Do heavy tasks"},
      {"period": "Noon", "status": "Caution", "action": "Avoid sun"},
      {"period": "Evening", "status": "Good", "action": "Enjoy outdoors"},
      {"period": "Night", "status": "Good", "action": "Sleep well"},
    ];
  }
  
  static List<Map<String, dynamic>> _generateChecklist(OutcomeProfile profile, double temp, String condition) {
     List<Map<String, dynamic>> list = [];
     if (profile.id == 'student') {
        list.add({"text": "Pack Laptop Charger", "icon": Icons.power});
        list.add({"text": "Review Notes", "icon": Icons.book});
     } else if (profile.id == 'farmer') {
         list.add({"text": "Check Irrigation", "icon": Icons.water});
         list.add({"text": "Cover Seedlings", "icon": Icons.grass});
     }
     
     if (temp > 30) list.add({"text": "Carry Water Bottle", "icon": Icons.local_drink});
     return list;
  }
}
