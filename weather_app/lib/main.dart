import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/profile_service.dart';
import 'services/settings_service.dart';
import 'services/news_service.dart';
import 'services/weather_service.dart'; // Keep if used elsewhere, or remove if not needed directly
import 'providers/weather_provider.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'premium/smart_guidance_provider.dart';

import 'auth_gate.dart';
import 'splash_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Safely)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("🔥 Firebase initialized");
  } catch (e) {
    print("⚠️ Firebase initialization failed: $e");
    print("⚠️ IGNORED FOR DEMO: Missing google-services.json?");
  }
  
  final prefs = await SharedPreferences.getInstance();
  
  // Clean up legacy specialized mode preferences
  final legacyKeys = [
    'userMode', 
    'profile_id', 
    'routine_worker', 
    'routine_farmer', 
    'routine_student',
    'farmState',
    'selectedCrop'
  ];
  for (final key in legacyKeys) {
    if (prefs.containsKey(key)) {
      await prefs.remove(key);
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
        ChangeNotifierProvider(create: (_) => NewsService()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => SmartGuidanceProvider(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BD Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AuthRoot(),
    );
  }
}

class AuthRoot extends StatefulWidget {
  const AuthRoot({super.key});

  @override
  State<AuthRoot> createState() => _AuthRootState();
}

class _AuthRootState extends State<AuthRoot> {
  bool _showSplash = true;
  bool _authChecked = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Show splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    // Try to check authentication status
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.checkAuthStatus();
    } catch (e) {
      print('⚠️ Auth check skipped - Firebase not configured');
    }
    
    if (mounted) {
      setState(() {
        _showSplash = false;
        _authChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash || !_authChecked) {
      return const SplashScreen();
    }

    return const AuthGate();
  }
}
