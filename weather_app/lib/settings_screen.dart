import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/settings_service.dart';
import 'services/profile_service.dart';
import 'services/auth_service.dart';
import 'services/alert_engine.dart';
import 'providers/weather_provider.dart';
import 'providers/units_provider.dart';
import 'contact_developer_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final profile = Provider.of<ProfileService>(context);

    final isBn = settings.language == 'bn';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? "সেটিংস" : "Settings"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _SectionHeader(title: isBn ? "সতর্কতা" : "Alerts"),
          SwitchListTile(
            title: Text(isBn ? "বৃষ্টির সতর্কতা" : "Rain Alerts"),
            subtitle: Text(isBn ? "বৃষ্টির সম্ভাবনা থাকলে জানান" : "Notify when rain is expected"),
            value: settings.rainAlerts,
            onChanged: (val) async {
              final weather = Provider.of<WeatherProvider>(context, listen: false);
              final success = await settings.toggleRain(val);
              if (success) {
                 if (val) {
                   AlertEngine.evaluateAndNotify(
                     current: weather.currentWeather,
                     forecast: weather.forecast,
                   );
                 }
              } else if (val && context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(isBn ? "সতর্কতা পেতে নোটিফিকেশন পারমিশন এনাবল করুন" : "Enable notification permission to receive alerts."))
                 );
              }
            },
            activeThumbColor: Colors.teal,
          ),
          SwitchListTile(
            title: Text(isBn ? "দাবদাহ সতর্কতা" : "Heatwave Alerts"),
            subtitle: Text(isBn ? "প্রচণ্ড গরম থাকলে জানান" : "Notify about extreme temperatures"),
            value: settings.heatAlerts,
            onChanged: (val) async {
              final weather = Provider.of<WeatherProvider>(context, listen: false);
              final success = await settings.toggleHeat(val);
              if (success) {
                 if (val) {
                    AlertEngine.evaluateAndNotify(
                      current: weather.currentWeather,
                      forecast: weather.forecast,
                    );
                 }
              } else if (val && context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(isBn ? "সতর্কতা পেতে নোটিফিকেশন পারমিশন এনাবল করুন" : "Enable notification permission to receive alerts."))
                 );
              }
            },
            activeThumbColor: Colors.teal,
          ),
          const Divider(),
          _SectionHeader(title: isBn ? "ভাষা ও একক" : "Units & Preferences"),
          ListTile(
            title: Text(isBn ? "ভাষা নির্বাচন" : "Language Settings"),
            subtitle: Text(isBn ? "বর্তমান: বাংলা" : "Current: English"),
            trailing: DropdownButton<String>(
              value: settings.language,
              underline: Container(),
              onChanged: (val) => settings.setLanguage(val!),
              items: const [
                DropdownMenuItem(value: "bn", child: Text("বাংলা")),
                DropdownMenuItem(value: "en", child: Text("English")),
              ],
            ),
          ),
          ListTile(
            title: Text(isBn ? "তাপমাত্রার একক" : "Temperature Unit"),
            subtitle: Text("${isBn ? "বর্তমান" : "Current"}: ${Provider.of<UnitsProvider>(context).unitLabel}"),
            trailing: DropdownButton<String>(
              value: Provider.of<UnitsProvider>(context).unitLabel,
              underline: Container(),
              onChanged: (val) {
                if (val != null) {
                  Provider.of<UnitsProvider>(context, listen: false).setUnit(val);
                }
              },
              items: ["°C", "°F"].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            ),
          ),
          SwitchListTile(
            title: Text(isBn ? "ডেটা সেভার মোড" : "Low Data Mode"),
            subtitle: Text(isBn ? "কম ডেটা ব্যবহার করুন" : "Reduce data usage"),
            value: settings.lowDataMode,
            onChanged: settings.toggleLowData,
            activeThumbColor: Colors.teal,
          ),
          const Divider(),
          _SectionHeader(title: isBn ? "অ্যাকাউন্ট" : "Account"),
          Consumer<AuthService>(
            builder: (context, authService, _) {
              final user = authService.currentUser;
              return Column(
                children: [
                  if (user != null)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: Icon(Icons.person, color: Colors.teal.shade700),
                      ),
                      title: Text(user.displayName ?? 'User'),
                      subtitle: Text(user.email ?? ''),
                    ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(isBn ? "লগ আউট" : "Logout"),
                    subtitle: Text(isBn ? "অ্যাকাউন্ট থেকে সাইন আউট করুন" : "Sign out from your account"),
                    onTap: () => _showLogoutDialog(context, isBn),
                  ),
                ],
              );
            },
          ),
          const Divider(),

          _SectionHeader(title: isBn ? "সাপোর্ট ও যোগাযোগ" : "Support & Development"),
          ListTile(
            leading: const Icon(Icons.code, color: Colors.teal),
            title: Text(isBn ? "ডেভেলপারের সাথে যোগাযোগ" : "Contact Developer"),
            subtitle: Text(isBn ? "MD. Rasel (ব্যবসায়িক যোগাযোগ)" : "MD. Rasel (Business Deals)"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactDeveloperScreen()),
            ),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text("Premium Edition v1.7", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isBn) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isBn ? "লগ আউট নিশ্চিত করুন" : "Confirm Logout"),
          content: Text(
            isBn 
              ? "আপনি কি নিশ্চিত যে আপনি লগ আউট করতে চান?"
              : "Are you sure you want to logout?"
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isBn ? "বাতিল" : "Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(isBn ? "লগ আউট" : "Logout"),
            ),
          ],
        );
      },
    );
  }


}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}
