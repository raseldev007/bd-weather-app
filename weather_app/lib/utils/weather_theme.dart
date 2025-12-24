import 'package:flutter/material.dart';

class WeatherTheme {
  static Color getPrimaryColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Colors.orange.shade700;
      case 'rainy':
        return Colors.blueGrey.shade800; // Dark, calm UI
      case 'cloudy':
      case 'overcast':
        return Colors.blueGrey.shade400;
      case 'stormy':
        return Colors.red.shade900; // Warning color
      case 'foggy':
        return Colors.grey.shade600;
      default:
        return Colors.teal.shade700;
    }
  }

  static LinearGradient getBackgroundGradient(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade300, Colors.orange.shade700],
        );
      case 'rainy':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900], // Dark rain UI
        );
      case 'cloudy':
      case 'overcast':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade100, Colors.blueGrey.shade400],
        );
      case 'stormy':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade300, Colors.red.shade900], // Warning gradient
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade300, Colors.teal.shade800],
        );
    }
  }

  static Color getCardColor(String condition) {
    return getPrimaryColor(condition).withOpacity(0.1);
  }

  static Color getTextColor(String condition) {
    if (condition.toLowerCase().contains('rain') || condition.toLowerCase().contains('storm')) {
      return Colors.white;
    }
    return Colors.black87;
  }
  static BoxDecoration getGlassyDecoration({Color? color, double opacity = 0.1}) {
    return BoxDecoration(
      color: (color ?? Colors.white).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.1),
          blurRadius: 40,
          spreadRadius: -10,
          offset: const Offset(0, -5),
        ),
      ],
    );
  }
}
