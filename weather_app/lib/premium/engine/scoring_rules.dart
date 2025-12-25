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

  static RuleSet byProfile(OutcomeProfileId id) {
    return general;
  }
}
