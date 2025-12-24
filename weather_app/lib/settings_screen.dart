import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/settings_service.dart';
import 'services/profile_service.dart';
import 'services/auth_service.dart';
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
          _SectionHeader(title: isBn ? "অ্যাকাউন্ট ও সাবস্ক্রিপশন" : "Account & Subscription"),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text(isBn ? "স্মার্ট গাইডেন্স" : "Smart Guidance"),
            subtitle: Text(profile.isPremium 
              ? (isBn ? "সাবস্ক্রিপশন সক্রিয়" : "Subscription Active") 
              : (isBn ? "সঠিক সিদ্ধান্ত নিতে প্রো ফিচার আনলক করুন" : "Unlock decision support features")),
            trailing: Switch(
              value: profile.isPremium,
              onChanged: (val) => profile.setPremium(val),
              activeThumbColor: Colors.amber,
            ),
          ),
          const Divider(),
          _SectionHeader(title: isBn ? "সতর্কতা" : "Alerts"),
          SwitchListTile(
            title: Text(isBn ? "বৃষ্টির সতর্কতা" : "Rain Alerts"),
            subtitle: Text(isBn ? "বৃষ্টির সম্ভাবনা থাকলে জানান" : "Notify when rain is expected"),
            value: settings.rainAlerts,
            onChanged: settings.toggleRain,
            activeThumbColor: Colors.teal,
          ),
          SwitchListTile(
            title: Text(isBn ? "দাবদাহ সতর্কতা" : "Heatwave Alerts"),
            subtitle: Text(isBn ? "প্রচণ্ড গরম থাকলে জানান" : "Notify about extreme temperatures"),
            value: settings.heatAlerts,
            onChanged: settings.toggleHeat,
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
            subtitle: Text("${isBn ? "বর্তমান" : "Current"}: ${settings.unit}"),
            trailing: DropdownButton<String>(
              value: settings.unit,
              underline: Container(),
              onChanged: (val) => settings.setUnit(val!),
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
          _SectionHeader(title: isBn ? "বিশেষায়িত প্রোফাইল (Outcome Profiles)" : "Specialized Outcome Profiles"),
          _buildProfileSelection(context, profile, isBn),
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

  Widget _buildProfileSelection(BuildContext context, ProfileService profile, bool isBn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildProfileCard(
            context,
            profile,
            UserMode.general,
            isBn ? "সাধারণ" : "General",
            isBn ? "দৈনন্দিন যাতায়াত ও কাজের আপডেট" : "Daily commute & life updates",
            Icons.person_outline,
            Colors.teal,
            isBn
          ),
          const SizedBox(height: 12),
          _buildProfileCard(
            context,
            profile,
            UserMode.farmer,
            isBn ? "কৃষক সহায়তা" : "Farmer Intelligence",
            isBn ? "ফসল সুরক্ষা ও কৃষি সিদ্ধান্ত" : "Crop protection & timing",
            Icons.agriculture,
            Colors.green,
            isBn
          ),
          const SizedBox(height: 12),
          _buildProfileCard(
            context,
            profile,
            UserMode.worker,
            isBn ? "শ্রমিক সুরক্ষা" : "Worker Safety",
            isBn ? "তাপমাত্রা ও বজ্রপাত ঝুঁকি সতর্কতা" : "Heat & lightning safety",
            Icons.engineering,
            Colors.orange,
            isBn
          ),
          const SizedBox(height: 12),
          _buildProfileCard(
            context,
            profile,
            UserMode.student,
            isBn ? "শিক্ষার্থী প্রোফাইল" : "Student Profile",
            isBn ? "পড়াশোনা ও যাতায়াত নিরাপত্তা" : "Study & commute safety",
            Icons.school,
            Colors.indigo,
            isBn
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, 
    ProfileService profile, 
    UserMode mode, 
    String title, 
    String subtitle, 
    IconData icon, 
    MaterialColor color,
    bool isBn
  ) {
    final isSelected = profile.mode == mode;
    return InkWell(
      onTap: () {
        profile.updateMode(mode);
        _showModeActivationSheet(context, title, subtitle, icon, color, isBn);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.withValues(alpha: 0.2), width: 2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color)
          ],
        ),
      ),
    );
  }

  void _showModeActivationSheet(BuildContext context, String title, String benefit, IconData icon, MaterialColor color, bool isBn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              isBn ? "$title মোড সক্রিয় হয়েছে" : "$title Activated",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              benefit,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("GOT IT"),
              ),
            ),
          ],
        ),
      ),
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
