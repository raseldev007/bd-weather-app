import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/bd_division_report_service.dart';
import '../providers/weather_provider.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../premium/smart_guidance_provider.dart';
import '../data/division_images.dart';

class BDReportScreen extends StatefulWidget {
  const BDReportScreen({super.key});

  @override
  State<BDReportScreen> createState() => _BDReportScreenState();
}

class _BDReportScreenState extends State<BDReportScreen> {
  final _reportService = BDDivisionReportService();
  List<Map<String, dynamic>>? _reports;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final lang = Provider.of<SettingsService>(context, listen: false).language;
    try {
      final res = await _reportService.fetchDivisionReports(lang);
      setState(() {
        _reports = res;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsService>(context).language;
    final isBn = lang == 'bn';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isBn ? "বাংলাদেশ রিপোর্ট" : "Bangladesh Report", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reports == null
              ? Center(child: Text(isBn ? "উপাত্ত পাওয়া যায়নি" : "No data available"))
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _reports!.length,
                    itemBuilder: (context, index) {
                      final item = _reports![index];
                      return _buildDivisionCard(item, isBn);
                    },
                  ),
                ),
    );
  }

  Widget _buildDivisionCard(Map<String, dynamic> data, bool isBn) {
    return GestureDetector(
      onTap: () async {
        final provider = context.read<WeatherProvider>();
        final profile = context.read<ProfileService>();
        final settings = context.read<SettingsService>();
        final smart = context.read<SmartGuidanceProvider>();

        // Disable live auto if it was on
        provider.disableLiveAuto();

        await provider.loadByLocation(
          data['lat'],
          data['lon'],
          setMode: WeatherMode.manual,
          name: data['name'],
          profile: profile,
          language: settings.language,
          smart: smart,
        );
        if (mounted) Navigator.pop(context);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                divisionImageMap[data['name']] ?? "assets/divisions/default.png",
                fit: BoxFit.cover,
                cacheWidth: 600,
              ),
            ),
            // Dark Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                  const Spacer(),
                  Row(
                    children: [
                      Text("${data['temp'].round()}°", style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Spacer(),
                      const Icon(Icons.wb_cloudy_outlined, color: Colors.white70),
                    ],
                  ),
                  Text(data['condition'], style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMiniChip(isBn ? "বৃষ্টি: " : "Rain: ", data['rainRisk'], data['rainRisk'] == "High" || data['rainRisk'] == "উচ্চ" ? Colors.redAccent : Colors.greenAccent),
                      const SizedBox(width: 8),
                      _buildMiniChip(isBn ? "তাপ: " : "Heat: ", data['heatStress'], data['heatStress'] == "High" || data['heatStress'] == "তীব্র" ? Colors.orangeAccent : Colors.greenAccent),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          "$label$value",
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
