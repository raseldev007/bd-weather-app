import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/profile_service.dart';

class SmartGuidanceOnboardingScreen extends StatelessWidget {
  const SmartGuidanceOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // General content
    final modeContent = _getModeContent();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Header
                      Text(
                        "Make Better Decisions\nwith Weather",
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                          height: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Visual Section - Mode-specific benefits
                      _buildBenefitItem(
                        modeContent['icon1']!,
                        modeContent['benefit1']!,
                        Colors.teal,
                      ),
                      const SizedBox(height: 20),
                      _buildBenefitItem(
                        modeContent['icon2']!,
                        modeContent['benefit2']!,
                        Colors.green,
                      ),
                      const SizedBox(height: 20),
                      _buildBenefitItem(
                        modeContent['icon3']!,
                        modeContent['benefit3']!,
                        Colors.indigo,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Value Statement
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 28),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                "We don't show more weather — we tell you what to do.",
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // What You Get
                      Text(
                        "What You Get:",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem("Safe & unsafe time windows"),
                      _buildFeatureItem("Clear action advice"),
                      _buildFeatureItem("Smart notifications when things change"),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              // CTA Section
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                        onPressed: () {
                        context.read<ProfileService>().setPremium(true);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Premium Activated!"),
                            backgroundColor: Colors.teal.shade700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        "Activate ${modeContent['modeName']}",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Cancel anytime • No spam alerts",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, String> _getModeContent() {
    return {
      'modeName': 'Daily Planner',
      'icon1': '🌤️',
      'benefit1': 'Plan your day with confidence',
      'icon2': '⏰',
      'benefit2': 'Know risky hours in advance',
      'icon3': '✅',
      'benefit3': 'Get clear action advice',
    };
  }

  Widget _buildBenefitItem(String emoji, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.teal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
