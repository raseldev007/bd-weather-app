import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'services/profile_service.dart';
import 'services/weather_insight_service.dart';
import 'services/settings_service.dart';
import 'utils/weather_theme.dart';

class CityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cityData;

  const CityDetailScreen({super.key, required this.cityData});

  @override
  State<CityDetailScreen> createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends State<CityDetailScreen> {
  late LatLng _cityLocation;
  
  final Map<String, LatLng> _cityCoordinates = {
    'Dhaka': const LatLng(23.8103, 90.4125),
    'Chittagong': const LatLng(22.3569, 91.7832),
    'Sylhet': const LatLng(24.8949, 91.8687),
    'Rajshahi': const LatLng(24.3636, 88.6241),
    'Khulna': const LatLng(22.8456, 89.5403),
  };

  @override
  void initState() {
    super.initState();
    final cityName = widget.cityData['city'] as String;
    _cityLocation = _cityCoordinates[cityName] ?? const LatLng(23.8103, 90.4125);
  }

  @override
  Widget build(BuildContext context) {
    final condition = widget.cityData['condition'] as String;
    final temp = (widget.cityData['temperature'] as num).toDouble();
    final humidity = (widget.cityData['humidity'] as num).toDouble();
    final profile = Provider.of<ProfileService>(context);
    final settings = Provider.of<SettingsService>(context);
    final isBn = settings.language == 'bn';
    final lang = settings.language;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.cityData['city'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(gradient: WeatherTheme.getBackgroundGradient(condition)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
          child: Column(
            children: [
              _buildMainStats(condition, temp, humidity, isBn),
              const SizedBox(height: 24),
              _buildTimelineSection(isBn),
              const SizedBox(height: 24),
              _buildInsightsSection(profile, condition, temp, humidity, lang),
              const SizedBox(height: 24),
              _buildMapSection(isBn),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainStats(String condition, double temp, double humidity, bool isBn) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: WeatherTheme.getGlassyDecoration(opacity: 0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${temp.toStringAsFixed(1)}°C", style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(condition, style: GoogleFonts.outfit(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w500)),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.water_drop, color: Colors.lightBlueAccent, size: 32),
              const SizedBox(height: 4),
              Text("$humidity% ${isBn ? "আর্দ্রতা" : "Hum"}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTimelineSection(bool isBn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isBn ? "আজকের সময়রেখা" : "Today's Timeline", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: WeatherTheme.getGlassyDecoration(opacity: 0.15),
          child: Column(
            children: [
               _buildTimelineRow(isBn ? "৩ টা" : "3 PM", Icons.cloud, isBn ? "মেঘলা" : "Cloudy"),
               _buildTimelineRow(isBn ? "৫ টা" : "5 PM", Icons.umbrella, isBn ? "বৃষ্টি শুরু" : "Rain starts"),
               _buildTimelineRow(isBn ? "৭ টা" : "7 PM", Icons.thunderstorm, isBn ? "ভারি বৃষ্টি" : "Heavy rain"),
               _buildTimelineRow(isBn ? "৯ টা" : "9 PM", Icons.cloud_queue, isBn ? "পরিষ্কার আকাশ" : "Clears up", isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow(String time, IconData icon, String label, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(time, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white70))),
          const SizedBox(width: 16),
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.outfit(fontSize: 15, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(ProfileService profile, String condition, double temp, double humidity, String lang) {
    final isBn = lang == 'bn';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: WeatherTheme.getGlassyDecoration(opacity: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isBn ? "কার্যকর পরামর্শ" : "Actionable Advice", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.lightbulb, isBn ? "পরামর্শ" : "Knowledge", WeatherInsightService.getDailyAdvice(condition, temp, humidity, profile.mode, lang)),
          Divider(color: Colors.white.withOpacity(0.1)),
          _buildDetailRow(Icons.checkroom, isBn ? "পোশাক" : "Clothing", WeatherInsightService.getOutfitRecommendation(condition, temp, lang)),
          Divider(color: Colors.white.withOpacity(0.1)),
          _buildDetailRow(Icons.directions_run, isBn ? "কার্যকলাপ" : "Activity", WeatherInsightService.getActivitySuggestion(condition, temp, lang)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.outfit(fontSize: 14, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(bool isBn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isBn ? "অবস্থান" : "Location", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _cityLocation, zoom: 12),
              markers: {Marker(markerId: const MarkerId("pos"), position: _cityLocation)},
            ),
          ),
        ),
      ],
    );
  }
}
