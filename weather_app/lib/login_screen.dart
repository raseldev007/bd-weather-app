import 'package:flutter/material.dart';

import 'dart:ui';
import 'signup_screen.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/google_auth_service.dart';
import 'services/profile_service.dart';
import 'main_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  bool isLoading = false;
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack("Please enter email and password");
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    // INSTANT BYPASS: If Firebase is not configured, skip everything
    if (!authService.isConfigured) {
      _showSnack("⚠️ Running in Demo Mode (Offline)");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainWrapper()),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Force timeout after 3 seconds to prevent indefinite hanging
      final success = await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ).timeout(const Duration(seconds: 3), onTimeout: () {
        return false; // Fail fast
      });

      if (mounted) {
        if (success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainWrapper()),
          );
        } else {
          // Immediate failover to demo mode if firebase is acting up
          if (authService.errorMessage?.contains("not initialized") == true || 
              authService.errorMessage == null) {
            
            _showSnack("⚠️ Running in Safe Mode (Offline)");
            
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainWrapper()),
              );
            }
          } else {
            setState(() => isLoading = false);
            _showSnack(authService.errorMessage ?? 'Login failed');
          }
        }
      }
    } catch (e) {
       // Emergency Fallback
       print("Login Error: $e");
       if (mounted) {
         // Immediate entry
         _showSnack("Entering Safe Mode...");
         Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainWrapper()),
         );
       }
    }
  }

  Future<void> _handleGoogleSignIn() async {

    // Removed pre-check to allow attempting connection even if initial check was flaky
    
    setState(() => isLoading = true);

    try {
      final userCredential = await _googleAuthService.signInWithGoogle();
      
      if (userCredential != null) {
        if (mounted) {
          final user = userCredential.user;
          final profileService = Provider.of<ProfileService>(context, listen: false);
          
          // Sync Google Data to Profile Service
          await profileService.updateProfile(
            name: user?.displayName ?? user?.email?.split('@')[0] ?? "User",
            email: user?.email ?? "user@example.com",
            location: "Dhaka, Bangladesh", // Default for now
            profileImageUrl: user?.photoURL ?? "",
          );
          await profileService.setLoggedIn(true);

          _showSnack("✅ Welcome, ${profileService.name}!");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainWrapper()),
          );
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          _showSnack("Sign in cancelled or failed");
        }
      }
    } catch (e) {
       print("Google Sign In Error: $e");
       if (mounted) {
         setState(() => isLoading = false);
         
         // Show detailed error dialog to help user debug
         showDialog(
           context: context,
           builder: (context) => AlertDialog(
             title: const Text("Sign In Failed"),
             content: SelectableText("Error: $e\n\nPossible Cause: SHA-1 Fingerprint mismatch in Firebase Console."),
             actions: [
               TextButton(
                 onPressed: () {
                   Navigator.pop(context);
                   // Fallback to demo mode
                   _showSnack("Entering Safe Mode (Offline)...");
                   Navigator.pushReplacement(
                     context,
                     MaterialPageRoute(builder: (_) => const MainWrapper()),
                   );
                 },
                 child: const Text("Enter Offline Mode"),
               ),
               TextButton(
                 onPressed: () => Navigator.pop(context),
                 child: const Text("Retry"),
               ),
             ],
           ),
         );
       }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.teal));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1504608524841-42fe6f032b4b?q=80&w=2000&auto=format&fit=crop"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark Overlay
          Container(color: Colors.black.withOpacity(0.4)),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Logo
                        RotationTransition(
                          turns: _logoController,
                          child: const Icon(Icons.wb_sunny_rounded, size: 80, color: Colors.yellowAccent),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Weather BD",
                          style: TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Premium Forecast System",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                          _buildGoogleButton(),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white24)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text("OR", style: TextStyle(color: Colors.white54)),
                              ),
                              Expanded(child: Divider(color: Colors.white24)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(_emailController, "Email", Icons.email),
                          const SizedBox(height: 16),
                          _buildTextField(_passwordController, "Password", Icons.lock, obscure: true),
                          const SizedBox(height: 32),
                          
                          if (isLoading)
                            const Column(
                              children: [
                                CircularProgressIndicator(color: Colors.yellowAccent),
                                SizedBox(height: 16),
                                Text("Syncing data...", style: TextStyle(color: Colors.white)),
                              ],
                            )
                          else ...[
                            _buildLoginButton(),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                                );
                              },
                              child: const Text(
                                "Don't have an account? Sign Up",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "© Developed by Rasel",
                              style: TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.yellowAccent),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellowAccent.shade700,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: _handleGoogleSignIn,
      icon: const Icon(Icons.login),
      label: const Text("CONTINUE WITH GOOGLE"),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
