import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/settings_service.dart';
import 'services/weather_service.dart';
import 'services/profile_service.dart';
import 'services/weather_insight_service.dart';
import 'utils/weather_theme.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerFetch();
    });
  }

  void _triggerFetch() {
    final profile = Provider.of<ProfileService>(context, listen: false);
    Provider.of<WeatherService>(context, listen: false).fetchForecast(profile.location.split(',').first.trim());
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final weatherService = Provider.of<WeatherService>(context);
    final isBn = settings.language == 'bn';
    
    final forecastData = weatherService.forecast;
    final isLoading = weatherService.isLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isBn ? "পূর্বাভাস" : "Forecast"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black, // Dark text as background is light
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: _triggerFetch,
            color: Colors.teal.shade700,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade50,
                  Colors.white
                ],
              ),
            ),
          ),
          
          isLoading && forecastData == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => _triggerFetch(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildConfidenceCard(forecastData, isBn),
                      const SizedBox(height: 20),
                      _buildYesterdayComparison(forecastData, isBn),
                      const SizedBox(height: 24),
                      _buildTimelineCard(forecastData, isBn),
                      const SizedBox(height: 24),
                      _buildWeeklyBrief(forecastData, isBn),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard(Map<String, dynamic>? data, bool isBn) {
    final confidence = data?['confidence'] ?? WeatherInsightService.getForecastConfidence(isBn ? 'bn' : 'en');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WeatherTheme.getGlassyDecoration(color: Colors.white, opacity: 0.6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(Icons.verified_user_outlined, color: Colors.green.shade700, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? "পূর্বাভাস নির্ভরযোগ্যতা" : "Forecast Confidence",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  "${isBn ? (confidence['bnLevel'] ?? confidence['level']) : confidence['level']} - ${isBn ? (confidence['bn_text'] ?? confidence['text']) : confidence['text']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYesterdayComparison(Map<String, dynamic>? data, bool isBn) {
    final comparison = data?['comparison'] ?? WeatherInsightService.getForecastComparison(isBn ? 'bn' : 'en');
    final isUp = (comparison['trend'] ?? 'up') == 'up';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUp 
             ? [Colors.orange.shade400, Colors.deepOrange.shade600]
             : [Colors.blue.shade400, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isUp ? Colors.orange : Colors.blue).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8)
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(isUp ? Icons.wb_sunny : Icons.ac_unit, color: Colors.white.withOpacity(0.9), size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? "গতকাল বনাম আজ" : "Yesterday vs Today",
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isBn ? (comparison['bn_comparisonText'] ?? comparison['comparisonText']) : comparison['comparisonText'],
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(Map<String, dynamic>? data, bool isBn) {
    final timeline = data?['hourly'] as List? ?? [];
    if (timeline.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            isBn ? "আজকের সময়রেখা" : "Today's Timeline", 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: timeline.map((item) {
              return _buildTimeCard(
                time: isBn ? (item['bn_time'] ?? item['time']) : item['time'],
                temp: item['temp'],
                cond: isBn ? (item['bn_cond'] ?? item['cond']) : item['cond'],
                rawCond: item['cond']
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard({required String time, required String temp, required String cond, required String rawCond}) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: WeatherTheme.getGlassyDecoration(color: Colors.white, opacity: 0.7),
      child: Column(
        children: [
          Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Icon(_getIconForCond(rawCond), color: WeatherTheme.getPrimaryColor(rawCond), size: 32),
          const SizedBox(height: 12),
          Text(temp, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(cond, style: TextStyle(fontSize: 10, color: Colors.grey.shade700), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildWeeklyBrief(Map<String, dynamic>? data, bool isBn) {
    final brief = data?['weekly_brief'];
    if (brief == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(isBn ? "পরবর্তী ৭ দিন" : "Next 7 Days", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
         const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: WeatherTheme.getGlassyDecoration(color: Colors.indigo.shade50, opacity: 0.6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.indigo.shade100, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.calendar_month_rounded, color: Colors.indigo.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                        isBn ? "সাপ্তাহিক সারসংক্ষেপ" : "Weekly Summary", 
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       isBn ? brief['bn_text'] : brief['text'],
                       style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                     ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconForCond(String cond) {
    cond = cond.toLowerCase();
    if (cond.contains('rain')) return Icons.water_drop;
    if (cond.contains('cloud')) return Icons.cloud;
    if (cond.contains('sun') || cond.contains('clear')) return Icons.wb_sunny;
    if (cond.contains('storm')) return Icons.flash_on;
    return Icons.wb_cloudy;
  }
}
