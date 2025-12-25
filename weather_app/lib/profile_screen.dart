import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/profile_service.dart';
import 'services/settings_service.dart';
import 'services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageController = TextEditingController();
  final _emailController = TextEditingController();
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileService>(context, listen: false);
    _nameController.text = profile.name;
    _locationController.text = profile.location;
    _imageController.text = profile.profileImageUrl;
    _emailController.text = profile.email;
  }

  void _saveProfile() {
    final profile = Provider.of<ProfileService>(context, listen: false);
    profile.updateProfile(
      name: _nameController.text,
      location: _locationController.text,
      profileImageUrl: _imageController.text,
      email: _emailController.text,
    );
    setState(() => isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileService>(context);
    final settings = Provider.of<SettingsService>(context);
    final isBn = settings.language == 'bn';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? "আপনার প্রোফাইল" : "Your Profile"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _saveProfile();
              } else {
                setState(() => isEditing = true);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 60,
              backgroundImage: profile.profileImageUrl.isNotEmpty ? NetworkImage(profile.profileImageUrl) : null,
              child: profile.profileImageUrl.isEmpty ? const Icon(Icons.person, size: 60) : null,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: isEditing 
                ? Column(
                    children: [
                      _buildEditField(_nameController, isBn ? "পুরো নাম" : "Full Name", Icons.person),
                      const SizedBox(height: 16),
                      _buildEditField(_emailController, isBn ? "ইমেইল" : "Email", Icons.email),
                      const SizedBox(height: 16),
                      _buildEditField(_locationController, isBn ? "ঠিকানা" : "Location", Icons.location_on),
                      const SizedBox(height: 16),
                      _buildEditField(_imageController, isBn ? "ছবির ইউআরএল" : "Profile Image URL", Icons.image),
                    ],
                  )
                : Column(
                    children: [
                      _buildInfoTile(isBn ? "নাম" : "Name", profile.name, Icons.person),
                      _buildInfoTile(isBn ? "ইমেইল" : "Email", profile.email, Icons.email),
                      _buildInfoTile(isBn ? "ঠিকানা" : "Location", profile.location, Icons.location_on),
                      const Divider(height: 40),
                      
                      ListTile(
                        onTap: () async {
                          // 1. Sign Out from Auth Service (Firebase/Google)
                          final authService = Provider.of<AuthService>(context, listen: false);
                          await authService.signOut();
                          
                          // 2. Clear Profile State
                          if (context.mounted) {
                             Provider.of<ProfileService>(context, listen: false).setLoggedIn(false);
                          
                             // 3. Navigate to Login Screen
                             Navigator.pushAndRemoveUntil(
                               context, 
                               MaterialPageRoute(builder: (context) => const LoginScreen()),
                               (route) => false
                             );
                          }
                        },
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: Text(isBn ? "লগ আউট" : "Logout", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        tileColor: Colors.red.withOpacity(0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }


}
