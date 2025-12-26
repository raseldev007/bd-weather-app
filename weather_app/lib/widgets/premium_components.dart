import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/units_provider.dart';

class PremiumHeroCard extends StatelessWidget {
  final double temp;
  final double feelsLike;
  final String condition;
  final String actionSentence;
  final List<Map<String, dynamic>> chips; // V3: List of {label, color} maps

  const PremiumHeroCard({
    super.key,
    required this.temp,
    required this.feelsLike,
    required this.condition,
    required this.actionSentence,
    required this.chips, 
  });

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitsProvider>();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.indigo.shade600], // V3 refined gradient
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight
        ),
        boxShadow: [
          BoxShadow(color: Colors.blue.shade200.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(condition, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 18)),
                   Text("${units.formatTemp(temp).replaceAll('°C', '°').replaceAll('°F', '°')}", style: GoogleFonts.outfit(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold, height: 1.0)),
                   Text("Feels like ${units.formatTemp(feelsLike)}", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                ],
              ),
              // Could add a big icon here
            ],
          ),
          const SizedBox(height: 24),
          // V3: Micro Chips (colored dot + text)
          Wrap(
            spacing: 8,
            children: chips.map((c) => Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.15),
                 borderRadius: BorderRadius.circular(20)
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    CircleAvatar(radius: 4, backgroundColor: c['color'] ?? Colors.white),
                    const SizedBox(width: 8),
                    Text(c['label'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 12))
                 ],
               ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16)
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.yellowAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(actionSentence, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)))
              ],
            ),
          )
        ],
      ),
    );
  }
}

class PremiumScoreModule extends StatelessWidget {
  final int score;
  final String title;
  final String label;
  final Color color;
  final IconData icon;
  final Map<String, dynamic>? signals; // V3: {tempSignal: 0/1/2, etc}
  final Map<String, dynamic>? footerInfo; // V4: {text: "Best Window: 9-11 AM", icon: ...}

  const PremiumScoreModule({
    super.key,
    required this.score,
    required this.title,
    required this.label,
    required this.color,
    required this.icon,
    this.signals,
    this.footerInfo
  });

  Color _getSignalColor(int val) {
    if (val == 0) return Colors.green;
    if (val == 1) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               Icon(icon, color: Colors.grey.shade400, size: 20),
               const SizedBox(width: 8),
               Text(title, style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold)),
               const Spacer(),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                 child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
               )
             ],
           ),
           const SizedBox(height: 16),
           LinearProgressIndicator(
             value: score / 100,
             backgroundColor: Colors.grey.shade100,
             color: color,
             minHeight: 8,
             borderRadius: BorderRadius.circular(4),
           ),
           const SizedBox(height: 8),
           Text("$score/100", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
           
           if (footerInfo != null) ...[ // V4 Best Window
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                   children: [
                      const Icon(Icons.timer_outlined, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Text(footerInfo!['text'] ?? "", style: GoogleFonts.outfit(color: Colors.blue.shade900, fontWeight: FontWeight.bold))
                   ],
                ),
              )
           ],
           
           if (signals != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // V4: Show Best Window if available
              // We pass 'signals' as the map, but we might have injected 'bestWindow' into the 'study' map in provider. 
              // Wait, in provider we did: studyScore['bestWindow'] = ...
              // But here we only receive 'signals' map.
              // I need to update the Widget signature to accept 'bestWindow' map or pass it via signals?
              // The user request Step 5 says: Below score: Best focus window: ...
              
              // I will update the Widget logic to look for a special key inside 'signals' OR 
              // better, I should update the calling code in WeatherScreen to pass it.
              // For minimal code change, let's assume 'signals' map might contain window info? 
              // No, 'study' map has it. 
              // Let's modify the Widget to take an optional 'footerInfo' map.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSignalColumn("Temp", signals!['tempSignal']),
                  _buildSignalColumn("Humid", signals!['humiditySignal']),
                  _buildSignalColumn("Noise", signals!['noiseSignal']),
                ],
              )
           ]
        ],
      ),
    );
  }
  
  Widget _buildSignalColumn(String label, int val) {
    return Column(
      children: [
        CircleAvatar(radius: 5, backgroundColor: _getSignalColor(val)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))
      ],
    );
  }
}

class BestTimeTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> items; // [{period, overall}]
  
  const BestTimeTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
         final item = items[index];
         Color color = Colors.green;
         IconData icon = Icons.check_circle;
         if (item['overall'] == 'fair') { color = Colors.orange; icon = Icons.remove_circle_outline; }
         if (item['overall'] == 'poor') { color = Colors.red; icon = Icons.cancel_outlined; }

         return Container(
           margin: const EdgeInsets.only(bottom: 12),
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: Colors.grey.shade100)
           ),
           child: Row(
             children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(item['period'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   Text(item['subtitle'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                 ],
               ),
               const Spacer(),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                 child: Row(
                   children: [
                     Icon(icon, color: color, size: 16),
                     const SizedBox(width: 6),
                     Text(item['overall'].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10))
                   ],
                 ),
               )
             ],
           ),
         );
      },
    );
  }
}

class ChecklistItem extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool? value; // Controlled state
  final ValueChanged<bool>? onChanged;
  
  const ChecklistItem({
    super.key, 
    required this.text, 
    required this.icon, 
    required this.color,
    this.value,
    this.onChanged
  });

  @override
  State<ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<ChecklistItem> {
  bool _internalChecked = false;

  bool get isChecked => widget.value ?? _internalChecked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onChanged != null) {
          widget.onChanged!(!isChecked);
        } else {
          setState(() => _internalChecked = !_internalChecked);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isChecked ? widget.color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isChecked ? widget.color : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: isChecked ? widget.color : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.text, 
                style: TextStyle(
                  color: isChecked ? Colors.black54 : Colors.black87,
                  decoration: isChecked ? TextDecoration.lineThrough : null
                )
              )
            ),
            if (isChecked) Icon(Icons.check_circle, color: widget.color, size: 20)
          ],
        ),
      ),
    );
  }
}

class PremiumSetupSheet extends StatefulWidget {
  final Function(String study, String commute) onSave;
  
  const PremiumSetupSheet({super.key, required this.onSave});

  @override
  State<PremiumSetupSheet> createState() => _PremiumSetupSheetState();
}

class _PremiumSetupSheetState extends State<PremiumSetupSheet> {
  String selectedStudy = "Morning";
  String selectedCommute = "Bus";

  final List<String> studyOptions = ["Morning", "Afternoon", "Night"];
  final List<String> commuteOptions = ["Walk", "Rickshaw", "Bus", "Bike", "Car"];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Setup Your Decision Assistant 🧠", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("We need to know your habits to give you the best advice.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          
          Text("Best time for you to study?", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: studyOptions.map((opt) => ChoiceChip(
              label: Text(opt),
              selected: selectedStudy == opt,
              onSelected: (val) => setState(() => selectedStudy = opt),
              selectedColor: Colors.teal.shade100,
              labelStyle: TextStyle(color: selectedStudy == opt ? Colors.teal.shade900 : Colors.black87),
            )).toList(),
          ),
          
          const SizedBox(height: 20),
          
          Text("How do you usually commute?", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: commuteOptions.map((opt) => ChoiceChip(
              label: Text(opt),
              selected: selectedCommute == opt,
              onSelected: (val) => setState(() => selectedCommute = opt),
               selectedColor: Colors.teal.shade100,
               labelStyle: TextStyle(color: selectedCommute == opt ? Colors.teal.shade900 : Colors.black87),
            )).toList(),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
              onPressed: () => widget.onSave(selectedStudy, selectedCommute),
              child: const Text("Complete Setup", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
            ),
          )
        ],
      ),
    );
  }
}

