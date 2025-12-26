import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/guidance_models.dart';
import 'models/routine_models.dart';

class SmartGuidanceProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  // Core
  bool _smartGuidanceEnabled = true;
  OutcomeProfileId _selectedProfileId = OutcomeProfileId.general;
  OutcomeProfileId get selectedProfileId => _selectedProfileId;

  // Per-profile routines
  GeneralRoutine _generalRoutine = const GeneralRoutine(commuteMode: CommuteMode.walk);


  // Latest guidance
  GuidanceResult? _latestGuidance;

  // Checklist (per-profile) + daily reset
  String _checklistDayKey = _todayKey();
  final Map<String, Map<String, bool>> _checklistDoneByProfile = {
    OutcomeProfileId.general.name: <String, bool>{},
    OutcomeProfileId.student.name: <String, bool>{},
    OutcomeProfileId.worker.name: <String, bool>{},
  };

  // Alerts (per-profile pack toggles)
  final Map<String, Map<String, bool>> _alertTogglesByProfile = {
    OutcomeProfileId.general.name: <String, bool>{},
    OutcomeProfileId.student.name: <String, bool>{},
    OutcomeProfileId.worker.name: <String, bool>{},
  };

  SmartGuidanceProvider(this._prefs) {
    _loadFromPrefs();
    _resetDailyChecklistIfNeeded(); // important
  }

  // --------- getters ----------
  bool get isEnabled => _smartGuidanceEnabled;
  GuidanceResult? get guidance => _latestGuidance;

  RoutineBundle get routine => RoutineBundle(
        profile: _selectedProfileId,
        general: _generalRoutine,
      );

  // Checklist helpers
  bool isChecklistDone(String itemId) =>
      _checklistDoneByProfile[_selectedProfileId.name]?[itemId] ?? false;

  Map<String, bool> get checklistStateForCurrentProfile =>
      _checklistDoneByProfile[_selectedProfileId.name] ?? {};

  // Alerts helpers
  bool getAlertToggle(String alertKey) =>
      _alertTogglesByProfile[_selectedProfileId.name]?[alertKey] ?? false;

  Map<String, bool> get alertTogglesForCurrentProfile =>
      _alertTogglesByProfile[_selectedProfileId.name] ?? {};

  // --------- core actions ----------
  Future<void> toggleSmartGuidance(bool v) async {
    _smartGuidanceEnabled = v;
    await _prefs.setBool('smart_enabled', v);
    notifyListeners();
  }

  Future<void> setProfileId(OutcomeProfileId id) async {
    _selectedProfileId = id;
    await _prefs.setString('premium_profile', id.name);
    notifyListeners();
  }



  void updateGuidance(GuidanceResult? result) {
    _latestGuidance = result;
    notifyListeners();
  }

  // --------- routine setters (persisted) ----------
  Future<void> setGeneralRoutine(GeneralRoutine r) async {
    _generalRoutine = r;
    await _prefs.setString('routine_general', jsonEncode(_generalToJson(r)));
    notifyListeners();
  }



  // --------- checklist (persisted + daily reset) ----------
  Future<void> markChecklistDone(String itemId, bool done) async {
    _resetDailyChecklistIfNeeded();
    final p = _selectedProfileId.name;
    _checklistDoneByProfile[p]![itemId] = done;
    await _saveChecklistState();
    notifyListeners();
  }

  void _resetDailyChecklistIfNeeded() {
    final today = _todayKey();
    final savedDay = _prefs.getString('checklist_day') ?? today;

    if (savedDay != today) {
      // new day → wipe all profiles' checklist done state
      _checklistDoneByProfile[OutcomeProfileId.general.name] = <String, bool>{};
      _checklistDoneByProfile[OutcomeProfileId.student.name] = <String, bool>{};
      _checklistDoneByProfile[OutcomeProfileId.worker.name] = <String, bool>{};
      _prefs.setString('checklist_day', today);
      _prefs.setString('checklist_state', jsonEncode(_checklistDoneByProfile));
    }

    _checklistDayKey = today;
  }

  Future<void> _saveChecklistState() async {
    await _prefs.setString('checklist_day', _checklistDayKey);
    await _prefs.setString('checklist_state', jsonEncode(_checklistDoneByProfile));
  }

  // --------- alerts toggles (persisted) ----------
  Future<void> setAlertToggle(String alertKey, bool v) async {
    final p = _selectedProfileId.name;
    _alertTogglesByProfile[p]![alertKey] = v;
    await _prefs.setString('alert_toggles', jsonEncode(_alertTogglesByProfile));
    notifyListeners();
  }

  // --------- load from prefs ----------
  void _loadFromPrefs() {
    _smartGuidanceEnabled = _prefs.getBool('smart_enabled') ?? true;

    final profileStr = _prefs.getString('premium_profile');
    if (profileStr != null) {
      _selectedProfileId = OutcomeProfileId.values.firstWhere(
        (e) => e.name == profileStr,
        orElse: () => OutcomeProfileId.general,
      );
    }

    // routines
    _generalRoutine = _generalFromJson(_tryDecode(_prefs.getString('routine_general')));

    // checklist state
    _checklistDayKey = _prefs.getString('checklist_day') ?? _todayKey();
    final checklistJson = _tryDecode(_prefs.getString('checklist_state'));
    if (checklistJson != null && checklistJson is Map) {
      for (var p in OutcomeProfileId.values) {
         if (checklistJson.containsKey(p.name)) {
            _checklistDoneByProfile[p.name] = (checklistJson[p.name] as Map).map((k, v) => MapEntry(k.toString(), v == true));
         }
      }
    }

    // alert toggles
    final alertJson = _tryDecode(_prefs.getString('alert_toggles'));
    if (alertJson != null && alertJson is Map) {
      for (var p in OutcomeProfileId.values) {
        if (alertJson.containsKey(p.name)) {
          _alertTogglesByProfile[p.name] = (alertJson[p.name] as Map).map((k, v) => MapEntry(k.toString(), v == true));
        }
      }
    }
  }

  // --------- helpers ----------


  static String _todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  static dynamic _tryDecode(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  // ---- routine json encode/decode ----
  static Map<String, dynamic> _generalToJson(GeneralRoutine r) => {
        "study": _todToMin(r.studyTime),
        "focus": _todToMin(r.focusTime),
        "return": _todToMin(r.returnTime),
        "commuteMode": r.commuteMode.name,
      };

  static GeneralRoutine _generalFromJson(dynamic j) {
    if (j is! Map) return const GeneralRoutine(commuteMode: CommuteMode.walk);
    return GeneralRoutine(
      studyTime: _minToTod(j["study"]),
      focusTime: _minToTod(j["focus"]),
      returnTime: _minToTod(j["return"]),
      commuteMode: CommuteMode.values.firstWhere(
        (e) => e.name == (j["commuteMode"] ?? "walk"),
        orElse: () => CommuteMode.walk,
      ),
    );
  }







  static int? _todToMin(TimeOfDay? t) => t == null ? null : (t.hour * 60 + t.minute);

  static TimeOfDay? _minToTod(dynamic m) {
    if (m is! int) return null;
    final h = m ~/ 60;
    final min = m % 60;
    return TimeOfDay(hour: h.clamp(0, 23), minute: min.clamp(0, 59));
  }
}
