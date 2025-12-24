import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/settings_service.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final isBn = settings.language == 'bn';
    
    // In a real app, this would fetch from a dedicated AlertService
    // For now, we show a prioritized list based on common risks
    final List<Map<String, dynamic>> activeAlerts = [
      {
        "title": isBn ? "ঘূর্ণিঝড় সতর্কতা" : "Cyclone Warning",
        "message": isBn ? "চট্টগ্রাম উপকূলবর্তী এলাকার জন্য ৩ নম্বর সতর্কতা সংকেত।" : "Signal No. 3 for Chattogram coastal areas.",
        "severity": "red",
        "icon": "🌪️",
      },
      {
        "title": isBn ? "বজ্রপাত ঝুঁকি" : "Lightning Risk",
        "message": isBn ? "উত্তরাঞ্চলে বজ্রপাতের সম্ভাবনা রয়েছে। খোলা স্থানে যাবেন না।" : "High lightning risk in North Bengal. Avoid open fields.",
        "severity": "orange",
        "icon": "🌩️",
      },
      {
        "title": isBn ? "ভ্যাপসা গরম" : "High Humidity Stress",
        "message": isBn ? "বাতাসে আর্দ্রতা বেশি থাকবে। প্রচুর পানি পান করুন।" : "High humidity levels expected. Stay hydrated.",
        "severity": "yellow",
        "icon": "💦",
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? "সতর্কতা কেন্দ্র" : "Alert Center"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeAlerts.length,
        itemBuilder: (context, index) {
          final alert = activeAlerts[index];
          MaterialColor statusColor = Colors.green;
          if (alert['severity'] == 'red') statusColor = Colors.red;
          if (alert['severity'] == 'orange') statusColor = Colors.orange;
          if (alert['severity'] == 'yellow') statusColor = Colors.amber;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert['icon'], style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert['title'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor.shade900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        alert['message'],
                        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
