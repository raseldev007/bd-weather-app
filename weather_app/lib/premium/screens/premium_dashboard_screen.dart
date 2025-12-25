import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/weather_provider.dart';
import '../smart_guidance_provider.dart';
import '../models/guidance_models.dart';

import '../ui/premium_widgets_v4.dart';
import '../ui/risk_simulator.dart';
import '../../services/profile_service.dart';
import '../ui/routine_wizard_sheet.dart';

class PremiumDashboardScreen extends StatelessWidget {
  final String language; 
  const PremiumDashboardScreen({super.key, this.language = 'en'});

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>();
    final smart = context.watch<SmartGuidanceProvider>();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                locationName: weather.selectedName ?? "—",
                onRefresh: () async {
                  final p = context.read<ProfileService>();
                  await context.read<WeatherProvider>().refresh(p, language, smart: smart);
                },
                onRoutine: () => RoutineWizardSheet.show(context),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PremiumToggleRow(
                  enabled: smart.isEnabled,
                  onToggle: (v) => smart.toggleSmartGuidance(v),
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _TabBar(),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: _Body(
                  isLoading: weather.isLoading,
                  error: weather.error,
                  insights: weather.homeInsights,
                  smartEnabled: smart.isEnabled,
                  language: language,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String locationName;
  final VoidCallback onRoutine;
  final VoidCallback onRefresh;

  const _TopBar({
    required this.locationName,
    required this.onRoutine,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: Colors.blueGrey.shade700,
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Premium",
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(locationName,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
          FilledButton.icon(
            onPressed: onRoutine,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text("Routine"),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumToggleRow extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _PremiumToggleRow({
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.teal),
                const SizedBox(width: 8),
                Text("Smart Guidance",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: onToggle),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: Colors.teal.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: Colors.teal.shade900,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 12),
        tabs: const [
          Tab(text: "Overview"),
          Tab(text: "Plan"),
          Tab(text: "Simulator"),
          Tab(text: "Checklist"),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final UIHomeInsights? insights;
  final bool smartEnabled;
  final String language;

  const _Body({
    required this.isLoading,
    required this.error,
    required this.insights,
    required this.smartEnabled,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text("Error: $error"));
    }
    if (insights == null) {
      return const Center(child: Text("No premium insights yet. Load weather first."));
    }

    return TabBarView(
      children: [
        _OverviewTab(insights: insights!, smartEnabled: smartEnabled),
        _PlanTab(insights: insights!, smartEnabled: smartEnabled),
        const RiskSimulator(), // Use widget from risk_simulator.dart
        _ChecklistTab(insights: insights!, smartEnabled: smartEnabled),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final UIHomeInsights insights;
  final bool smartEnabled;

  const _OverviewTab({required this.insights, required this.smartEnabled});

  @override
  Widget build(BuildContext context) {
    final hero = insights.hero;
    final study = insights.study;
    final commute = insights.commute;

    final chips = _buildHeroChips(hero);

    return RefreshIndicator(
      onRefresh: () async {
         // managed by parent usually, but functional here triggers pull-to-refresh
         // However, onRefresh logic is in TopBar. 
         // Here we can re-trigger provider refresh.
         // context.read<WeatherProvider>().refresh(...)
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        children: [
          PremiumHeroCardV4(
            temp: (hero["temp"] as num?)?.toDouble() ?? 0,
            feelsLike: (hero["feelsLike"] as num?)?.toDouble() ?? 0,
            condition: hero["condition"]?.toString() ?? "—",
            actionSentence: hero["action"]?.toString() ?? "—",
            chips: chips,
          ),

          _WhyRow(hero: hero),

          const SizedBox(height: 10),

          PremiumScoreModuleV4(
            score: (study["score"] as num?)?.toInt() ?? 0,
            title: "Study Comfort",
            label: study["label"]?.toString() ?? "—",
            color: Colors.teal,
            icon: Icons.school_outlined,
            signals: (study["signals"] is Map) ? (study["signals"] as Map).cast<String, dynamic>() : null,
            bestWindow: (study["bestWindow"] is Map) ? (study["bestWindow"] as Map).cast<String, dynamic>() : null,
          ),

          const SizedBox(height: 12),

          PremiumScoreModuleV4(
            score: (commute["score"] as num?)?.toInt() ?? 0,
            title: "Commute Risk",
            label: commute["label"]?.toString() ?? "—",
            color: Colors.indigo,
            icon: Icons.directions_bus,
            signals: null,
            // commute bestWindow not yet mapped in UIHomeInsights, pass null or extend provider
            bestWindow: null, 
          ),

          const SizedBox(height: 14),

          if (!smartEnabled)
            _SoftHintCard(
              icon: Icons.lock_outline,
              title: "Smart Guidance is OFF",
              body: "Turn it ON to unlock timeline decisions, simulator personalization, and persistent checklist.",
            ),
        ],
      ),
    );
  }

  static List<Map<String, dynamic>> _buildHeroChips(Map<String, dynamic> hero) {
    final heat = (hero["heatStress"] ?? "—").toString();
    final rain = (hero["rainRisk"] ?? "—").toString();

    final raw = (hero["raw"] is Map) ? (hero["raw"] as Map).cast<String, dynamic>() : <String, dynamic>{};
    final humidity = (raw["humidity"] as num?)?.toDouble() ?? 0;
    final wind = (raw["wind"] as num?)?.toDouble() ?? 0;

    String airLabel = "Air: GOOD";
    Color airColor = Colors.green;
    if (humidity >= 80 || wind >= 8) {
      airLabel = "Air: FAIR";
      airColor = Colors.orange;
    }
    if (humidity >= 90) {
      airLabel = "Air: POOR";
      airColor = Colors.red;
    }

    // Return format compatible with PremiumHeroCardV4
    return [
      {"title": "Rain", "text": rain, "level": rain, "reasons": ["Rain Status: $rain"]}, 
      {"title": "Heat", "text": heat, "level": heat, "reasons": ["Heat Stress: $heat"]},
      {"title": "Air", "text": airLabel.split(': ')[1], "level": airLabel.split(': ')[1], "reasons": ["Based on heavy humidity/wind"]},
    ];
  }
}

class _WhyRow extends StatelessWidget {
  final Map<String, dynamic> hero;
  const _WhyRow({required this.hero});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showWhy(context),
            icon: const Icon(Icons.info_outline),
            label: const Text("Why this advice?"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => RoutineWizardSheet.show(context),
            icon: const Icon(Icons.tune),
            label: const Text("Improve it"),
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
          ),
        ),
      ],
    );
  }

  void _showWhy(BuildContext context) {
    final raw = (hero["raw"] is Map) ? (hero["raw"] as Map).cast<String, dynamic>() : <String, dynamic>{};

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Why we decided this",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _kv("Temp", "${raw["temp"] ?? "—"}°C"),
            _kv("Humidity", "${raw["humidity"] ?? "—"}%"),
            _kv("Wind", "${raw["wind"] ?? "—"} m/s"),
            _kv("Condition", "${raw["condition"] ?? "—"}"),
            const SizedBox(height: 10),
            Text("This is calculated from current conditions + forecast trend.",
                style: GoogleFonts.outfit(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(k, style: GoogleFonts.outfit(fontWeight: FontWeight.w800))),
          Text(v, style: GoogleFonts.outfit(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  final UIHomeInsights insights;
  final bool smartEnabled;

  const _PlanTab({required this.insights, required this.smartEnabled});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // V4 Widget: Plan Timeline
        const BestTimeTimelineV4(),
        
        const SizedBox(height: 14),

        const _SimulatorPreviewCard(),

        const SizedBox(height: 14),

        _TomorrowStrip(items: insights.tomorrowTimeline),
        ],
      ),
    );
  }
}

class _TomorrowStrip extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _TomorrowStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tomorrow Morning", style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final it = items[i];
                return Container(
                  width: 110,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${it["time"] ?? "—"}", style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text("${it["temp"] ?? "—"}°", style: GoogleFonts.outfit(color: Colors.grey.shade700)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulatorPreviewCard extends StatelessWidget {
  const _SimulatorPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Try the Risk Simulator",
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: () => DefaultTabController.of(context).animateTo(2),
            child: const Text("Open"),
          )
        ],
      ),
    );
  }
}

class _ChecklistTab extends StatelessWidget {
  final UIHomeInsights insights;
  final bool smartEnabled;
  const _ChecklistTab({required this.insights, required this.smartEnabled});

  @override
  Widget build(BuildContext context) {
    // Map existing checklist data structure to PremiumChecklistV4 structure
    final items = insights.checklist.map((x) => {
         "id": x["id"],
         "title": x["text"],      
         "subtitle": x["subtitle"],
         "severity": x["severity"], // V4 widget handles color mapping
    }).toList();

    return PremiumChecklistV4(items: items);
  }
}

class _SoftHintCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _SoftHintCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(body, style: GoogleFonts.outfit(color: Colors.grey.shade700)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
