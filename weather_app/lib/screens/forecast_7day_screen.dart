import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../utils/weather_theme.dart';
import '../services/settings_service.dart';

class Forecast7DayScreen extends StatelessWidget {
  const Forecast7DayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final settings = Provider.of<SettingsService>(context);
    final isBn = settings.language == 'bn';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? "৭ দিনের পূর্বাভাস" : "7-Day Forecast"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: provider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : provider.forecast == null
          ? Center(child: Text(isBn ? "কোনো তথ্য নেই" : "No forecast data available"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: (provider.forecast!['daily'] as List?)?.length ?? 0,
              itemBuilder: (context, index) {
                final day = provider.forecast!['daily'][index];
                final date = DateTime.fromMillisecondsSinceEpoch(day['dt'] * 1000);
                final tempMin = (day['temp']['min'] as num).toDouble();
                final tempMax = (day['temp']['max'] as num).toDouble();
                final condition = day['weather'][0]['main'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Text(
                      "${date.day}/${date.month}", 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    title: Text(condition),
                    trailing: Text("${tempMin.round()}° / ${tempMax.round()}°"),
                  ),
                );
              },
            ),
    );
  }
}
