import 'package:flutter/material.dart';

enum OutcomeProfileId { general, student, worker }
enum ConfidenceLevel { high, medium, low }
enum RiskLevel { low, medium, high }
enum PlanBlockId { morning, noon, evening, night }

class RiskChip {
  final String title; // "Rain", "Heat", "Wind/Visibility"
  final RiskLevel level;
  final String shortText; // "LOW", "MILD", "GOOD"
  final IconData icon;
  final List<String> reasons; // shown in Explain sheet

  const RiskChip({
    required this.title,
    required this.level,
    required this.shortText,
    required this.icon,
    required this.reasons,
  });
}

class TimeWindow {
  final DateTime start;
  final DateTime end;
  final int score; // 0–100
  final String label; // e.g., "Best focus window"
  final List<String> reasons;

  const TimeWindow({
    required this.start,
    required this.end,
    required this.score,
    required this.label,
    required this.reasons,
  });
}

class PlanBlock {
  final PlanBlockId id;
  final DateTime start;
  final DateTime end;

  final int studyScore;
  final int commuteScore;
  final int outdoorScore;


  final List<String> doThis;
  final List<String> avoidThis;
  final ConfidenceLevel confidence;

  const PlanBlock({
    required this.id,
    required this.start,
    required this.end,
    required this.studyScore,
    required this.commuteScore,
    required this.outdoorScore,

    required this.doThis,
    required this.avoidThis,
    required this.confidence,
  });
}

class ChecklistItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final RiskLevel severity; // low/med/high urgency

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.severity,
  });
}

class AlertSuggestion {
  final String id;
  final String title;
  final String body;
  final DateTime fireAt; // when to notify
  final RiskLevel severity;

  const AlertSuggestion({
    required this.id,
    required this.title,
    required this.body,
    required this.fireAt,
    required this.severity,
  });
}

class GuidanceResult {
  final String primaryDecisionLine;
  final ConfidenceLevel confidence;

  final List<RiskChip> riskChips;

  final TimeWindow? bestFocusWindow;     // student/general
  final TimeWindow? bestCommuteWindow;   // all profiles
  final TimeWindow? bestOutdoorWindow;   // all profiles


  final List<PlanBlock> planBlocks;
  final List<ChecklistItem> checklist;
  final List<AlertSuggestion> alerts;

  const GuidanceResult({
    required this.primaryDecisionLine,
    required this.confidence,
    required this.riskChips,
    required this.bestFocusWindow,
    required this.bestCommuteWindow,
    required this.bestOutdoorWindow,

    required this.planBlocks,
    required this.checklist,
    required this.alerts,
  });
}
