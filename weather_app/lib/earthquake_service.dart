import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


class EarthquakeService {
  Future<List<dynamic>> fetchEarthquakes() async {
    // Detect platform for correct localhost URL
    // Web: 127.0.0.1
    // Android Emulator: 10.0.2.2
    String apiUrl = "http://127.0.0.1:8000/earthquakes";
    if (!kIsWeb) {
      apiUrl = "http://10.0.2.2:8000/earthquakes";
    }

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return _getMockData();
      }
    } catch (e) {
       debugPrint("Backend unreachable, using mock data: $e");
       return _getMockData();
    }
  }

  List<dynamic> _getMockData() {
    return [
      {"location": "Sylhet Region (Demo)", "magnitude": 4.5, "date": "Dec 23, 10:00 AM", "alert_level": "Moderate"},
      {"location": "Chittagong Hill Tracts (Demo)", "magnitude": 3.2, "date": "Dec 22, 02:30 PM", "alert_level": "Low"},
      {"location": "Near Dhaka (Demo)", "magnitude": 2.1, "date": "Dec 21, 11:15 PM", "alert_level": "Low"},
      {"location": "Myanmar Border (Demo)", "magnitude": 5.8, "date": "Dec 20, 08:45 AM", "alert_level": "High"},
    ];
  }
  }
