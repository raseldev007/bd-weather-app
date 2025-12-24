import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CopyrightWidget extends StatelessWidget {
  const CopyrightWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(color: Colors.grey.withValues(alpha: 0.1), thickness: 1),
          const SizedBox(height: 16),
          Text(
            "Weather Intelligence provided by BMD & Open-Meteo",
            style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 11, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                "© Developed by MD. Rasel",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.teal.shade800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Premium Edition v1.7",
            style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
