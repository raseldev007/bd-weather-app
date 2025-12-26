import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/units_provider.dart';
import '../smart_guidance_provider.dart';
import '../models/guidance_models.dart';

/// ---------- Helper: small badge ----------
class _Pill extends StatelessWidget {
  final Widget child;
  final Color bg;
  final Color border;

  const _Pill({required this.child, required this.bg, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

/// ---------- HERO CARD (Interactive Chips + Why modal) ----------
class PremiumHeroCardV4 extends StatelessWidget {
  final double temp;
  final double feelsLike;
  final String condition;
  final String actionSentence;
  final String locationName;

  /// chips from guidance mapping:
  /// [{title, level, text, reasons: [..]}]
  final List<Map<String, dynamic>> chips;

  const PremiumHeroCardV4({
    super.key,
    required this.temp,
    required this.feelsLike,
    required this.condition,
    required this.actionSentence,
    required this.chips,
    required this.locationName,
  });

  IconData _iconForCondition(String c) {
    final x = c.toLowerCase();
    if (x.contains("rain") || x.contains("drizzle")) return Icons.umbrella;
    if (x.contains("cloud")) return Icons.cloud;
    if (x.contains("storm") || x.contains("thunder")) return Icons.thunderstorm;
    if (x.contains("mist") || x.contains("fog") || x.contains("haze")) return Icons.foggy;
    return Icons.wb_sunny;
  }

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case "low": return Colors.green;
      case "medium": return Colors.orange;
      case "high": return Colors.red;
      default: return Colors.white;
    }
  }

  void _showChipWhy(BuildContext context, Map<String, dynamic> c) {
    final level = (c["level"] ?? "").toString();
    final reasons = (c["reasons"] is List) ? (c["reasons"] as List).cast<String>() : const <String>[];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${c["title"] ?? "Insight"}",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Row(
              children: [
                _Pill(
                  bg: _levelColor(level).withOpacity(0.12),
                  border: _levelColor(level).withOpacity(0.35),
                  child: Text(
                    level.toUpperCase(),
                    style: TextStyle(color: _levelColor(level), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (c["text"] ?? "").toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            if (reasons.isNotEmpty) ...[
              Text("Why we decided this",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• "),
                    Expanded(child: Text(r)),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitsProvider>();
    final icon = _iconForCondition(condition);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(condition,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(units.formatTemp(temp).replaceAll('°C', '°').replaceAll('°F', '°'),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 62,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            )),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            locationName,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text("Feels like ${units.formatTemp(feelsLike)}",
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Chips (interactive)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((c) {
              final level = (c["level"] ?? "").toString();
              final dot = _levelColor(level);
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _showChipWhy(context, c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 4, backgroundColor: dot),
                      const SizedBox(width: 8),
                      Text(
                        "${c["title"] ?? ""}: ${(c["text"] ?? "")}",
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Decision line
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.yellowAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    actionSentence,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- SCORE MODULE (Best Window + expandable Why) ----------
class PremiumScoreModuleV4 extends StatelessWidget {
  final int score;
  final String title;
  final String label;
  final Color color;
  final IconData icon;

  /// signals: {tempSignal: 0/1/2, humiditySignal: 0/1/2, noiseSignal: 0/1/2}
  final Map<String, dynamic>? signals;

  /// bestWindow: {startIso, endIso, score, reasons:[...]}
  final Map<String, dynamic>? bestWindow;

  const PremiumScoreModuleV4({
    super.key,
    required this.score,
    required this.title,
    required this.label,
    required this.color,
    required this.icon,
    this.signals,
    this.bestWindow,
  });

  Color _signalColor(int v) {
    if (v == 0) return Colors.green;
    if (v == 1) return Colors.orange;
    return Colors.red;
  }

  String _fmtIso(String? iso) {
    if (iso == null) return "—";
    final dt = DateTime.tryParse(iso);
    if (dt == null) return "—";
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _showWhy(BuildContext context) {
    final reasons = (bestWindow?["reasons"] is List) ? (bestWindow!["reasons"] as List).cast<String>() : const <String>[];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$title • Why", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (bestWindow != null) ...[
              _Pill(
                bg: color.withOpacity(0.10),
                border: color.withOpacity(0.35),
                child: Text(
                  "Best window: ${_fmtIso(bestWindow?["start"])}–${_fmtIso(bestWindow?["end"])}",
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (reasons.isNotEmpty)
              ...reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("• "),
                    // expanded below (can't const due to r)
                  ],
                ),
              )),
            if (reasons.isNotEmpty)
              ...reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• "),
                    Expanded(child: Text(r)),
                  ],
                ),
              )),
            if (reasons.isEmpty)
              Text("No extra explanation available yet.",
                  style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final start = _fmtIso(bestWindow?["start"]);
    final end = _fmtIso(bestWindow?["end"]);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade500, size: 20),
              const SizedBox(width: 8),
              Flexible(child: Text(title, style: GoogleFonts.outfit(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              _Pill(
                bg: color.withOpacity(0.10),
                border: color.withOpacity(0.25),
                child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),

          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: (score.clamp(0, 100)) / 100,
            backgroundColor: Colors.grey.shade100,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Text("$score/100", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87)),

          if (bestWindow != null) ...[
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showWhy(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Best window: $start – $end",
                        style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(Icons.info_outline, size: 18),
                  ],
                ),
              ),
            ),
          ],

          if (signals != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _sig("Temp", signals!['tempSignal'] ?? 1, _signalColor),
                _sig("Humid", signals!['humiditySignal'] ?? 1, _signalColor),
                _sig("Noise", signals!['noiseSignal'] ?? 1, _signalColor),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _sig(String label, int v, Color Function(int) col) {
    return Column(
      children: [
        CircleAvatar(radius: 5, backgroundColor: col(v)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

/// ---------- PLAN TIMELINE (uses SmartGuidanceProvider.guidance.planBlocks) ----------
class BestTimeTimelineV4 extends StatelessWidget {
  const BestTimeTimelineV4({super.key});

  String _label(PlanBlockId id) {
    switch (id) {
      case PlanBlockId.morning: return "Morning";
      case PlanBlockId.noon: return "Noon";
      case PlanBlockId.evening: return "Evening";
      case PlanBlockId.night: return "Night";
    }
  }

  Color _scoreColor(int s) {
    if (s >= 75) return Colors.green;
    if (s >= 55) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartGuidanceProvider>(
      builder: (_, smart, __) {
        final g = smart.guidance;
        if (!smart.isEnabled) {
           return Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text("Smart Guidance is OFF", style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600)),
                 const SizedBox(height: 12),
                 FilledButton.icon(
                   onPressed: () => smart.toggleSmartGuidance(true),
                   icon: const Icon(Icons.auto_awesome, size: 18),
                   label: const Text("Turn On"),
                   style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                 )
               ],
             ),
           );
        }
        if (g == null || g.planBlocks.isEmpty) return const Center(child: Text("No plan yet"));

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: g.planBlocks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final b = g.planBlocks[i];
            final start = "${b.start.hour.toString().padLeft(2, '0')}:${b.start.minute.toString().padLeft(2, '0')}";
            final end = "${b.end.hour.toString().padLeft(2, '0')}:${b.end.minute.toString().padLeft(2, '0')}";

            Widget chip(String t, int s) {
              final c = _scoreColor(s);
              return _Pill(
                bg: c.withOpacity(0.10),
                border: c.withOpacity(0.25),
                child: Text("$t $s", style: TextStyle(color: c, fontWeight: FontWeight.bold)),
              );
            }

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showPlanDetail(context, b, g),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_label(b.id), style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                        const Spacer(),
                        Text("$start–$end", style: GoogleFonts.outfit(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        chip("Study", b.studyScore),
                        chip("Commute", b.commuteScore),
                        chip("Outdoor", b.outdoorScore),
                      ],
                    ),
                    if (b.doThis.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text("Top: ${b.doThis.first}", style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPlanDetail(BuildContext context, PlanBlock b, GuidanceResult g) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Plan details", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text("Confidence: ${b.confidence.name.toUpperCase()}",
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 12),
            Text("Do this", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            ...b.doThis.map((x) => _bullet(x)),
            if (b.avoidThis.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text("Avoid this", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...b.avoidThis.map((x) => _bullet(x)),
            ],
            const SizedBox(height: 12),
            Text("Signals", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: g.riskChips.map((c) => Chip(
                avatar: Icon(c.icon, size: 18),
                label: Text("${c.title}: ${c.level.name.toUpperCase()}"),
              )).toList(),
            ),
            const SizedBox(height: 6),
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

  Widget _bullet(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("• "),
        Expanded(child: Text(t)),
      ],
    ),
  );
}

/// ---------- CHECKLIST (controlled by SmartGuidanceProvider) ----------
class PremiumChecklistV4 extends StatelessWidget {
  /// checklist items from guidance:
  /// [{id, title, subtitle, severity}]
  final List<Map<String, dynamic>> items;

  const PremiumChecklistV4({super.key, required this.items});

  Color _sevColor(String s) {
    switch (s.toLowerCase()) {
      case "warn": return Colors.orange;
      case "danger": return Colors.red;
      default: return Colors.green;
    }
  }

  IconData _sevIcon(String s) {
    switch (s.toLowerCase()) {
      case "warn": return Icons.warning_amber_rounded;
      case "danger": return Icons.error_outline;
      default: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartGuidanceProvider>(
      builder: (_, smart, __) {
        if (!smart.isEnabled) return const Center(child: Text("Enable Smart Guidance to use checklist."));
        if (items.isEmpty) return const Center(child: Text("No checklist items today."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final it = items[i];
            final id = (it["id"] ?? "x_$i").toString();
            final title = (it["title"] ?? "").toString();
            final subtitle = (it["subtitle"] ?? "").toString();
            final sev = (it["severity"] ?? "ok").toString();

            final done = smart.isChecklistDone(id);
            final c = _sevColor(sev);

            return GestureDetector(
              onTap: () => smart.markChecklistDone(id, !done),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: done ? c.withOpacity(0.10) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: done ? c : Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Row(
                  children: [
                    Icon(_sevIcon(sev), color: done ? c : Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              decoration: done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: GoogleFonts.outfit(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                decoration: done ? TextDecoration.lineThrough : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (done) Icon(Icons.check_circle, color: c, size: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
