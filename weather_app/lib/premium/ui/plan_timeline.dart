
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlanTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> blocks;
  
  const PlanTimeline({super.key, required this.blocks});

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const Center(child: Text("No plan available"));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        final isSafe = block['status'] == 'Good' || block['status'] == 'Safe';
        final color = isSafe ? Colors.green : Colors.orange;
        
        return GestureDetector(
          onTap: () => _showPlanDetails(context, block),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Column(
                    children: [
                      Text(block['period'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color)),
                      // const SizedBox(height: 4),
                      // Icon(isSafe ? Icons.check_circle : Icons.warning_amber, color: color, size: 16)
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(block['action'] ?? "Check details", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                           _buildMiniTag(block['study'] == 'Good' ? "Study ✅" : "Study ⚠️"),
                           const SizedBox(width: 8),
                           _buildMiniTag(block['outdoor'] == 'Good' ? "Outdoor ✅" : "Outdoor ❌"),
                        ],
                      )
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey)
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMiniTag(String text) {
    bool isPos = text.contains("✅");
    return Text(text, style: TextStyle(fontSize: 10, color: isPos ? Colors.green : Colors.orange, fontWeight: FontWeight.bold));
  }

  void _showPlanDetails(BuildContext context, Map<String, dynamic> block) {
    showModalBottomSheet(
      context: context,
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text("${block['period']} Insight", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                   child: const Text("Confidence: HIGH", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
                 )
               ],
             ),
             const SizedBox(height: 20),
             _buildDetailRow(Icons.check_circle, "Do this:", block['action'], Colors.green),
             const SizedBox(height: 16),
             _buildDetailRow(Icons.remove_circle, "Avoid:", "Heavy outdoor activity if heat > 35°C", Colors.red),
             const SizedBox(height: 24),
             const Text("Why this advice?", style: TextStyle(fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             const Text("Based on 3-hour forecast trends for temperature and humidity.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
               Text(text, style: GoogleFonts.outfit(fontSize: 16))
            ],
          ),
        )
      ],
    );
  }
}
