import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_insight_service.dart';

enum UserMode { general, farmer, worker, student }

class ProfileService extends ChangeNotifier {
  String _name = "User";
  String _email = "user@example.com";
  String _location = "Dhaka, Bangladesh";
  String _profileImageUrl = ""; // Empty means show default icon
  UserMode _mode = UserMode.general;
  bool _isLoggedIn = false;
  bool _isPremium = false;
  OutcomeState? _lastWorkState;
  OutcomeState? _lastFarmState;
  DateTime? _lastTransitionTime;
  String? _lastTransitionTitle;
  String? _lastTransitionBody;
  bool _dailySummaryEnabled = false;
  DateTime? _lastDailySummaryTime;
  String _selectedCrop = "General Crops";
  int _impactScore = 0;

  String get name => _name;
  String get email => _email;
  String get location => _location;
  String get profileImageUrl => _profileImageUrl;
  UserMode get mode => _mode;
  bool get isLoggedIn => _isLoggedIn;
  bool get isPremium => _isPremium;
  OutcomeState? get lastWorkState => _lastWorkState;
  OutcomeState? get lastFarmState => _lastFarmState;
  DateTime? get lastTransitionTime => _lastTransitionTime;
  String? get lastTransitionTitle => _lastTransitionTitle;
  String? get lastTransitionBody => _lastTransitionBody;
  bool get dailySummaryEnabled => _dailySummaryEnabled;
  DateTime? get lastDailySummaryTime => _lastDailySummaryTime;
  String get selectedCrop => _selectedCrop;
  int get impactScore => _impactScore;

  ProfileService() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('name') ?? "User";
    _email = prefs.getString('email') ?? "user@example.com";
    _location = prefs.getString('location') ?? "Dhaka, Bangladesh";
    _profileImageUrl = prefs.getString('profileImageUrl') ?? "";
    final modeIndex = prefs.getInt('userMode') ?? 0;
    _mode = UserMode.values[modeIndex];
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _isPremium = prefs.getBool('isPremium') ?? false;
    _impactScore = prefs.getInt('impactScore') ?? 0;
    _dailySummaryEnabled = prefs.getBool('dailySummaryEnabled') ?? false;
    _selectedCrop = prefs.getString('selectedCrop') ?? "General Crops";
    
    String? lastSummary = prefs.getString('lastDailySummaryTime');
    if (lastSummary != null) _lastDailySummaryTime = DateTime.parse(lastSummary);

    String? workStateStr = prefs.getString('lastWorkState');
    if (workStateStr != null) {
      _lastWorkState = OutcomeState.values.firstWhere(
        (e) => e.toString() == workStateStr,
        orElse: () => OutcomeState.safe,
      );
    }
    
    String? farmStateStr = prefs.getString('lastFarmState');
    if (farmStateStr != null) {
      _lastFarmState = OutcomeState.values.firstWhere(
        (e) => e.toString() == farmStateStr,
        orElse: () => OutcomeState.safe,
      );
    }

    notifyListeners();
  }

  Future<void> setLoggedIn(bool value) async {
    _isLoggedIn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', value);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String location,
    required String profileImageUrl,
  }) async {
    _name = name;
    _email = email;
    _location = location;
    _profileImageUrl = profileImageUrl;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('location', location);
    await prefs.setString('profileImageUrl', profileImageUrl);
    
    notifyListeners();
  }

  Future<void> updateMode(UserMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userMode', mode.index);
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', value);
    notifyListeners();
  }

  Future<void> incrementImpactScore() async {
    _impactScore++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('impactScore', _impactScore);
    notifyListeners();
  }

  // Handle email separately if needed
  Future<void> updateEmail(String email) async {
    _email = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    notifyListeners();
  }

  Future<void> updateStates({OutcomeState? workState, OutcomeState? farmState, String? title, String? body}) async {
    final prefs = await SharedPreferences.getInstance();
    bool changed = false;

    if (workState != null && workState != _lastWorkState) {
      _lastWorkState = workState;
      await prefs.setString('lastWorkState', workState.toString());
      changed = true;
    }

    if (farmState != null && farmState != _lastFarmState) {
      _lastFarmState = farmState;
      await prefs.setString('lastFarmState', farmState.toString());
      changed = true;
    }

    if (changed) {
      _lastTransitionTime = DateTime.now();
      _lastTransitionTitle = title;
      _lastTransitionBody = body;
      notifyListeners();
    }
  }

  void clearTransition() {
    _lastTransitionTitle = null;
    _lastTransitionBody = null;
    // Don't notify here to avoid rebuild loop if called in build, 
    // but usually called after SnackBar shows.
    notifyListeners();
  }

  Future<void> setDailySummaryEnabled(bool value) async {
    _dailySummaryEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailySummaryEnabled', value);
    notifyListeners();
  }

  Future<void> markDailySummaryShown() async {
    _lastDailySummaryTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastDailySummaryTime', _lastDailySummaryTime!.toIso8601String());
    notifyListeners();
  }

  Future<void> updateSelectedCrop(String crop) async {
    _selectedCrop = crop;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCrop', crop);
    notifyListeners();
  }
}

