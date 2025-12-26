import '../models/guidance_models.dart';

class RuleSet {
  // Comfort ranges (°C)
  final double tempIdealMin;
  final double tempIdealMax;

  // Humidity comfort (%)
  final int humidityIdealMax;

  // Risk thresholds
  final double popHigh;   // precipitation probability high
  final double popMed;

  final double windHigh;  // m/s (OpenWeather)
  final double windMed;

  final double sprayWindMax; // farmer spray safe wind max (m/s)
  final int visibilityLow;   // meters

  const RuleSet({
    required this.tempIdealMin,
    required this.tempIdealMax,
    required this.humidityIdealMax,
    required this.popHigh,
    required this.popMed,
    required this.windHigh,
    required this.windMed,
    required this.sprayWindMax,
    required this.visibilityLow,
  });
}

class ScoringRules {
  static const general = RuleSet(
    tempIdealMin: 20, tempIdealMax: 28,
    humidityIdealMax: 75,
    popHigh: 0.60, popMed: 0.30,
    windHigh: 9.0, windMed: 5.0,
    sprayWindMax: 4.0,
    visibilityLow: 2500,
  );

  static const student = RuleSet(
    tempIdealMin: 22, tempIdealMax: 26, // More sensitive for focus
    humidityIdealMax: 65,
    popHigh: 0.50, popMed: 0.20,
    windHigh: 10.0, windMed: 6.0,
    sprayWindMax: 4.0,
    visibilityLow: 2000,
  );

  static const worker = RuleSet(
    tempIdealMin: 18, tempIdealMax: 30, // More tolerant
    humidityIdealMax: 85,
    popHigh: 0.70, popMed: 0.40,
    windHigh: 15.0, windMed: 8.0,
    sprayWindMax: 4.0,
    visibilityLow: 3000, // Safety priority
  );

  static RuleSet byProfile(OutcomeProfileId id) {
    switch (id) {
      case OutcomeProfileId.student: return student;
      case OutcomeProfileId.worker: return worker;
      case OutcomeProfileId.general: return general;
      default: return general;
    }
  }
}
