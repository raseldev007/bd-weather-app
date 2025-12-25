import 'package:flutter/material.dart';

class OutcomeProfile {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color themeColor;
  final bool enabledByDefault;
  final List<String> supportedModules;

  const OutcomeProfile({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.themeColor,
    this.enabledByDefault = false,
    required this.supportedModules,
  });
}

class PremiumProfiles {
  static const OutcomeProfile general = OutcomeProfile(
    id: 'general',
    title: 'General',
    subtitle: 'Daily life & Commute',
    icon: Icons.person_outline,
    themeColor: Colors.blue,
    enabledByDefault: true,
    supportedModules: ['commute', 'outdoor', 'checklist'],
  );

  static const OutcomeProfile farmer = OutcomeProfile(
    id: 'farmer',
    title: 'Farmer',
    subtitle: 'Crops & Spray Windows',
    icon: Icons.agriculture,
    themeColor: Colors.green,
    supportedModules: ['spray', 'irrigation', 'work_safety'],
  );

  static const OutcomeProfile worker = OutcomeProfile(
    id: 'worker',
    title: 'Worker',
    subtitle: 'Safety & Shifts',
    icon: Icons.engineering,
    themeColor: Colors.orange,
    supportedModules: ['work_safety', 'commute', 'checklist'],
  );

  static const OutcomeProfile student = OutcomeProfile(
    id: 'student',
    title: 'Student',
    subtitle: 'Study & Exam Focus',
    icon: Icons.school,
    themeColor: Colors.indigo,
    supportedModules: ['study', 'commute', 'checklist'],
  );

  static List<OutcomeProfile> getAll() => [general, farmer, worker, student];
  
  static OutcomeProfile getById(String id) {
    return getAll().firstWhere((p) => p.id == id, orElse: () => general);
  }
}
