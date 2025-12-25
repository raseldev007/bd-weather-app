import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/guidance_models.dart';
import '../models/routine_models.dart';
import '../smart_guidance_provider.dart';

class PlanTimelineTab extends StatelessWidget {
  const PlanTimelineTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartGuidanceProvider>(
      builder: (context, smart, _) {
        final g = smart.guidance;
        if (!smart.isEnabled) {
          return const _EmptyState(text: "Smart Guidance is OFF. Enable it to see your daily plan.");
        }
        if (g == null || g.planBlocks.isEmpty) {
          return const _EmptyState(text: "No plan yet. Load weather data first.");
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: g.planBlocks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final b = g.planBlocks[i];
            return _PlanBlockCard(
              block: b,
              profile: OutcomeProfileId.general,
              onTap: () => _showDetail(context, b, g),
            );
          },
        );
      },
    );
  }

  void _showDetail(BuildContext context, PlanBlock b, GuidanceResult g) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PlanDetailSheet(block: b, guidance: g),
    );
  }
}

class _PlanBlockCard extends StatelessWidget {
  final PlanBlock block;
  final OutcomeProfileId profile;
  final VoidCallback onTap;

  const _PlanBlockCard({required this.block, required this.profile, required this.onTap});

  String _label(PlanBlockId id) {
    switch (id) {
      case PlanBlockId.morning: return "Morning";
      case PlanBlockId.noon: return "Noon";
      case PlanBlockId.evening: return "Evening";
      case PlanBlockId.night: return "Night";
    }
  }

  Color _scoreColor(BuildContext context, int s) {
    if (s >= 75) return Colors.green;
    if (s >= 55) return Colors.orange;
    return Colors.red;
  }

  Widget _metricChip(BuildContext context, String title, int score) {
    final c = _scoreColor(context, score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.30)),
      ),
      child: Text("$title: $score",
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final start = "${block.start.hour.toString().padLeft(2, '0')}:${block.start.minute.toString().padLeft(2, '0')}";
    final end = "${block.end.hour.toString().padLeft(2, '0')}:${block.end.minute.toString().padLeft(2, '0')}";

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_label(block.id), style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text("$start–$end", style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip(context, "Study", block.studyScore),
                _metricChip(context, "Commute", block.commuteScore),
                _metricChip(context, "Outdoor", block.outdoorScore),
              ],
            ),
            if (block.doThis.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text("Top suggestion: ${block.doThis.first}",
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanDetailSheet extends StatelessWidget {
  final PlanBlock block;
  final GuidanceResult guidance;

  const _PlanDetailSheet({required this.block, required this.guidance});

  @override
  Widget build(BuildContext context) {
    final start = "${block.start.hour.toString().padLeft(2, '0')}:${block.start.minute.toString().padLeft(2, '0')}";
    final end = "${block.end.hour.toString().padLeft(2, '0')}:${block.end.minute.toString().padLeft(2, '0')}";

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Plan details", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text("$start–$end • Confidence: ${block.confidence.name.toUpperCase()}",
                style: Theme.of(context).textTheme.labelMedium),

            const SizedBox(height: 12),
            Text("Do this", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            ...block.doThis.map((x) => _bullet(context, x)),

            if (block.avoidThis.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text("Avoid this", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...block.avoidThis.map((x) => _bullet(context, x)),
            ],

            const SizedBox(height: 12),
            Text("Why (signals)", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: guidance.riskChips.map((c) {
                final level = c.level.name.toUpperCase();
                return Chip(
                  label: Text("${c.title}: $level"),
                  avatar: Icon(c.icon, size: 18),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),
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

  Widget _bullet(BuildContext context, String t) {
    return Padding(
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
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
