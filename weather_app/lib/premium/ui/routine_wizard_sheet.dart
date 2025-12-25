import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/routine_models.dart';
import '../models/guidance_models.dart';
import '../smart_guidance_provider.dart';

class RoutineWizardSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => const _RoutineWizardBody(),
    );
  }
}

class _RoutineWizardBody extends StatefulWidget {
  const _RoutineWizardBody();

  @override
  State<_RoutineWizardBody> createState() => _RoutineWizardBodyState();
}

class _RoutineWizardBodyState extends State<_RoutineWizardBody> {
  // local editable copies
  TimeOfDay? _studyTime;
  TimeOfDay? _focusTime;
  TimeOfDay? _returnTime;
  CommuteMode _commuteMode = CommuteMode.walk;

  @override
  void initState() {
    super.initState();
    final smart = context.read<SmartGuidanceProvider>();

    final r = smart.routine;

    if (r.general != null) {
      _studyTime = r.general!.studyTime;
      _focusTime = r.general!.focusTime;
      _returnTime = r.general!.returnTime;
      _commuteMode = r.general!.commuteMode;
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay? initial) async {
    final now = TimeOfDay.now();
    final t = await showTimePicker(
      context: context,
      initialTime: initial ?? now,
    );
    return t;
  }

  String _fmt(TimeOfDay? t) {
    if (t == null) return "Not set";
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<SmartGuidanceProvider>(
        builder: (context, smart, _) {


          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Routine Setup",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    )
                  ],
                ),
                const SizedBox(height: 8),

                // Smart guidance toggle (optional but useful here)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: smart.isEnabled,
                  onChanged: (v) => smart.toggleSmartGuidance(v),
                  title: const Text("Smart Guidance"),
                  subtitle: const Text("Personalized decisions + timeline + simulator"),
                ),

                const SizedBox(height: 8),


                const SizedBox(height: 12),

                _sectionTitle("General Routine"),
                _timeTile(
                  title: "Study time",
                  value: _fmt(_studyTime),
                  onTap: () async {
                    final t = await _pickTime(_studyTime);
                    if (t != null) setState(() => _studyTime = t);
                  },
                ),
                _timeTile(
                  title: "Focus time",
                  value: _fmt(_focusTime),
                  onTap: () async {
                    final t = await _pickTime(_focusTime);
                    if (t != null) setState(() => _focusTime = t);
                  },
                ),
                _timeTile(
                  title: "Return time",
                  value: _fmt(_returnTime),
                  onTap: () async {
                    final t = await _pickTime(_returnTime);
                    if (t != null) setState(() => _returnTime = t);
                  },
                ),
                _dropdownTile<CommuteMode>(
                  title: "Commute mode",
                  value: _commuteMode,
                  items: CommuteMode.values,
                  label: (m) => m.name.toUpperCase(),
                  onChanged: (v) => setState(() => _commuteMode = v),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          // Save to provider (persisted there)
                          await smart.setGeneralRoutine(
                            GeneralRoutine(
                              studyTime: _studyTime,
                              focusTime: _focusTime,
                              returnTime: _returnTime,
                              commuteMode: _commuteMode,
                            ),
                          );

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(t, style: Theme.of(context).textTheme.titleMedium),
        ),
      );

  Widget _timeTile({required String title, required String value, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.schedule),
      onTap: onTap,
    );
  }

  Widget _dropdownTile<T>({
    required String title,
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: DropdownButton<T>(
        value: value,
        onChanged: (v) => v == null ? null : onChanged(v),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(label(e)))).toList(),
      ),
    );
  }
}


