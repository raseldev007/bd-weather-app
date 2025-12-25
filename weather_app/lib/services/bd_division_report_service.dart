import '../services/weather_service.dart';
import '../services/weather_insight_service.dart';
import '../data/bd_divisions.dart';

class BDDivisionReportService {
  final WeatherService _weatherService = WeatherService();

  Future<List<Map<String, dynamic>>> fetchDivisionReports(String lang) async {
    final List<Future<Map<String, dynamic>>> futures = bdDivisions.map((div) async {
      final current = await _weatherService.getCurrentByLocation(div['lat'], div['lon']);
      
      final temp = (current['main']['temp'] as num).toDouble();
      final humidity = (current['main']['humidity'] as num).toDouble();
      final condition = current['weather'][0]['main'];
      final rainProb = (current['rain'] != null && current['rain']['1h'] != null) ? 100.0 : 0.0; // Simple heuristic

      // Use Insight service to get standard labels
      final isRainy = condition.toLowerCase().contains('rain') || rainProb > 50;
      final heatIndex = WeatherInsightService.calculateHeatIndex(temp, humidity);

      return {
        "name": div['name'],
        "lat": div['lat'],
        "lon": div['lon'],
        "temp": temp,
        "condition": condition,
        "humidity": humidity,
        "wind": (current['wind']['speed'] as num).toDouble(),
        "rainRisk": isRainy ? (lang == 'bn' ? "উচ্চ" : "High") : (lang == 'bn' ? "স্বল্প" : "Low"),
        "heatStress": heatIndex > 35 ? (lang == 'bn' ? "তীব্র" : "High") : (lang == 'bn' ? "নাই" : "None"),
      };
    }).toList();

    return await Future.wait(futures);
  }
}
