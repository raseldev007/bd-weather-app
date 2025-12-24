import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/profile_service.dart';
import 'services/settings_service.dart';
import 'services/weather_insight_service.dart';
import 'utils/weather_theme.dart';
import 'copyright_widget.dart';
import 'profile_screen.dart';
import 'services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with SingleTickerProviderStateMixin {
  String selectedCity = "Dhaka";
  UserMode? _lastFetchedMode;
  
  final Map<String, Map<String, double>> divisions = {
    'Dhaka': {'lat': 23.8103, 'lng': 90.4125},
    'Chattogram': {'lat': 22.3569, 'lng': 91.7832},
    'Rajshahi': {'lat': 24.3636, '88.6241': 0}, // Fixed coordinate key error
    'Khulna': {'lat': 22.8456, 'lng': 89.5403},
    'Barishal': {'lat': 22.7010, 'lng': 90.3535},
    'Sylhet': {'lat': 24.8949, 'lng': 91.8687},
    'Rangpur': {'lat': 25.7439, 'lng': 89.2752},
    'Mymensingh': {'lat': 24.7471, 'lng': 90.4203},
  };

  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerFetch();
    });
  }

  void _triggerFetch() {
    final profile = Provider.of<ProfileService>(context, listen: false);
    _lastFetchedMode = profile.mode;
    Provider.of<WeatherService>(context, listen: false).fetchHomeInsights(selectedCity, profile);
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileService>(context);
    final settings = Provider.of<SettingsService>(context);
    final weatherService = Provider.of<WeatherService>(context);

    // Auto-refresh when mode changes
    if (_lastFetchedMode != null && _lastFetchedMode != profile.mode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerFetch());
    }
    
    final isBn = settings.language == 'bn';
    final isEmergency = weatherService.isEmergency;
    
    // Use data from backend if available
    final insights = weatherService.homeInsights;
    final isLoading = weatherService.isLoading;
    
    final condition = insights?.current_weather['condition'] ?? 'Clear';
    final temp = (insights?.current_weather['temperature'] ?? 20).toDouble();
    final humidity = (insights?.current_weather['humidity'] ?? 50).toDouble();

    // --- Transition Notification Logic ---
    if (profile.lastTransitionTitle != null && profile.lastTransitionBody != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.lastTransitionTitle!, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(profile.lastTransitionBody!, style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.teal.shade900,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: isBn ? "বন্ধ করুন" : "DISMISS", textColor: Colors.white, onPressed: () {
              profile.clearTransition();
            }),
          ),
        );
        profile.clearTransition();
      });
    }

    // --- Daily Summary Notification Logic ---
    bool isNewDay = profile.lastDailySummaryTime == null || 
                    profile.lastDailySummaryTime!.day != DateTime.now().day;
    if (profile.isPremium && profile.dailySummaryEnabled && isNewDay) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Row(
               children: [
                 const Icon(Icons.summarize_outlined, color: Colors.white),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Text(
                     isBn ? "প্রাতঃকালীন সারসংক্ষেপ প্রস্তুত।" : "Your morning summary is ready.",
                     style: const TextStyle(fontWeight: FontWeight.bold),
                   ),
                 ),
               ],
             ),
             backgroundColor: Colors.indigo.shade800,
             behavior: SnackBarBehavior.floating,
             duration: const Duration(seconds: 10),
             action: SnackBarAction(label: isBn ? "দেখুন" : "VIEW", textColor: Colors.white, onPressed: () {
               // Focus on summary section logic could go here
             }),
           ),
         );
         profile.markDailySummaryShown();
       });
    }

    return Scaffold(
      backgroundColor: isEmergency ? Colors.white : Colors.grey.shade50,
      appBar: AppBar(
        title: isEmergency 
          ? Text(isBn ? "জরুরি অবস্থা" : "EMERGENCY MODE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red))
          : _buildCitySelector(isBn, condition),
        centerTitle: false,
        backgroundColor: isEmergency ? Colors.black : Colors.white,
        foregroundColor: isEmergency ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isEmergency ? Icons.warning_amber_rounded : Icons.person_outline, color: isEmergency ? Colors.redAccent : Colors.teal), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen()))
          ),
          IconButton(icon: Icon(Icons.refresh, color: isEmergency ? Colors.white : Colors.black), onPressed: _triggerFetch),
        ],
      ),
      body: isLoading && insights == null
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async => _triggerFetch(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildProfileHeader(profile, isBn),
                  const SizedBox(height: 16),
                  _buildMainHeader(profile, condition, temp, humidity, settings.unit, isBn, isEmergency, settings.language),
                  const SizedBox(height: 24),
                  _buildPrimaryInsightCard(insights, isBn, isEmergency),
                  const SizedBox(height: 24),
                  if (!isEmergency) ...[
                    _buildRiskTimeline(isBn),
                    const SizedBox(height: 32),
                    _buildDailyRiskSummary(profile, temp, condition, settings.language),
                    const SizedBox(height: 32),
                    _buildPremiumIntelligence(profile, condition, temp, humidity, settings.language),
                    const SizedBox(height: 32),
                    _buildInsightSection(profile, condition, temp, humidity, settings.language),
                  ] else ...[
                    const SizedBox(height: 32),
                    Text(
                      isBn ? "জরুরি পদক্ষেপসমূহ" : "Critical Next Steps", 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    _buildSimpleGuidance(isBn),
                  ],
                  const SizedBox(height: 40),
                  const CopyrightWidget(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildCitySelector(bool isBn, String condition) {
    return DropdownButton<String>(
      value: selectedCity,
      underline: Container(),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.teal),
      style: GoogleFonts.outfit(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 20),
      items: divisions.keys.map((String city) {
         Map<String, String> localized = {
           'Dhaka': 'ঢাকা', 'Chattogram': 'চট্টগ্রাম', 'Rajshahi': 'রাজশাহী', 
           'Khulna': 'খুলনা', 'Barishal': 'বরিশাল', 'Sylhet': 'সিলেট', 
           'Rangpur': 'রংপুর', 'Mymensingh': 'ময়মনসিংহ'
         };
         return DropdownMenuItem<String>(value: city, child: Text(isBn ? (localized[city] ?? city) : city));
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => selectedCity = val);
          _triggerFetch();
        }
      },
    );
  }

  Widget _buildPrimaryInsightCard(HomeInsights? insights, bool isBn, bool isEmergency) {
    if (insights == null) return const SizedBox.shrink();
    final primary = insights.primary_insight;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: isEmergency ? ImageFilter.blur(sigmaX: 0, sigmaY: 0) : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isEmergency ? 24 : 20),
          decoration: isEmergency 
            ? BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.red, width: 4))
            : WeatherTheme.getGlassyDecoration(opacity: 0.7).copyWith(
                border: Border.all(
                  color: primary['severity'] == 'emergency' ? Colors.red.shade200 : (primary['severity'] == 'high' ? Colors.orange.shade200 : Colors.teal.shade100), 
                  width: 2
                ),
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBn ? primary['bn_summary'] : primary['summary'],
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: isEmergency ? 20 : 16, 
                  color: isEmergency ? Colors.white : (primary['severity'] == 'emergency' ? Colors.red.shade700 : (primary['severity'] == 'high' ? Colors.orange.shade800 : Colors.teal.shade800))
                ),
              ),
              const SizedBox(height: 12),
              ...((isBn ? primary['bn_actions'] : primary['actions'] as List).map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: isEmergency ? 20 : 16, color: isEmergency ? Colors.white : Colors.teal.shade600),
                    const SizedBox(width: 8),
                    Expanded(child: Text(action, style: TextStyle(fontSize: isEmergency ? 16 : 14, fontWeight: FontWeight.w600, height: 1.4, color: isEmergency ? Colors.white : Colors.black))),
                  ],
                ),
              ))),
              if (primary['why_this_alert'] != null) ...[
                 Divider(height: 24, color: isEmergency ? Colors.white24 : Colors.grey.shade200),
                 Row(
                   children: [
                     Icon(Icons.info_outline, size: 14, color: isEmergency ? Colors.white70 : Colors.teal.shade700),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             "${isBn ? "কেন এই সতর্কতা" : "Why this alert"}: ${isBn ? primary['why_this_alert']['bn_trigger'] : primary['why_this_alert']['trigger']}",
                             style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isEmergency ? Colors.white : Colors.black87),
                           ),
                           const SizedBox(height: 2),
                           Text(
                             "${isBn ? "কারা আক্রান্ত" : "Who is affected"}: ${isBn ? primary['bn_who_is_affected'] : primary['who_is_affected']}",
                             style: TextStyle(fontSize: 11, color: isEmergency ? Colors.white70 : Colors.grey.shade700),
                           ),
                         ],
                       ),
                     ),
                     Text(
                       primary['why_this_alert']['time_window'] ?? "",
                       style: TextStyle(fontSize: 11, color: isEmergency ? Colors.white70 : Colors.grey),
                     ),
                   ],
                 )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleGuidance(bool isBn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.security, color: Colors.yellowAccent),
            title: Text(isBn ? "নিরাপদ স্থানে থাকুন" : "Find Higher Ground / Safety", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.phone_in_talk, color: Colors.yellowAccent),
            title: Text(isBn ? "জরুরি হটলাইন: ৯৯৯" : "Emergency Hotline: 999", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskTimeline(bool isBn) {
    final timeline = WeatherInsightService.getRiskTimeline(isBn ? 'bn' : 'en');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isBn ? "আগামী ৬ ঘণ্টার ঝুঁকি বিশ্লেষণ" : "Next 6-Hour Risk Window",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: timeline.length,
            itemBuilder: (context, index) {
              final item = timeline[index];
              final isHighRisk = item['isHighRisk'] as bool;
              return Container(
                width: 75,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isHighRisk ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isHighRisk ? Colors.red.shade100 : Colors.green.shade100),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item['hour'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Icon(
                      isHighRisk ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: isHighRisk ? Colors.red.shade700 : Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['status'],
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHighRisk ? Colors.red.shade900 : Colors.green.shade900),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainHeader(ProfileService profile, String condition, double temp, double humidity, String unit, bool isBn, bool isEmergency, String lang) {
    final heatIndex = WeatherInsightService.calculateHeatIndex(temp, humidity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isEmergency ? Colors.black : null,
        gradient: isEmergency ? null : WeatherTheme.getBackgroundGradient(condition),
        borderRadius: BorderRadius.circular(24),
        border: isEmergency ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(condition, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18, fontWeight: FontWeight.bold)),
              if (!isEmergency) RotationTransition(turns: _logoController, child: const Icon(Icons.wb_sunny_rounded, color: Colors.yellowAccent)),
              if (isEmergency) const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 32),
            ],
          ),
          const SizedBox(height: 8),
          Text("${temp.toStringAsFixed(1)}$unit", style: GoogleFonts.outfit(fontSize: isEmergency ? 72 : 64, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text("${isBn ? "তাপমাত্রা অনুভূত" : "Heat Index"}: ${heatIndex.toStringAsFixed(1)}$unit", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ),
          if (profile.isPremium) ...[
            const SizedBox(height: 12),
            Text(
              WeatherInsightService.getGeneralRefinements(temp, humidity, condition, lang)['comparison'],
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightSection(ProfileService profile, String condition, double temp, double humidity, String lang) {
    final isBn = lang == 'bn';
    final isLocked = !profile.isPremium && profile.mode != UserMode.general;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isBn ? "ব্যবহারিক দিকনির্দেশনা" : "Practical Guidance", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (profile.mode != UserMode.general)
              GestureDetector(
                onTap: () {
                  bool newState = !profile.isPremium;
                  profile.setPremium(newState);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(newState 
                        ? (isBn ? "প্রিমিয়ম সক্রিয় হয়েছে!" : "Premium Activated!") 
                        : (isBn ? "প্রিমিয়ম নিষ্ক্রিয় হয়েছে" : "Premium Deactivated")),
                      backgroundColor: newState ? Colors.teal : Colors.blueGrey,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: profile.isPremium ? Colors.teal.shade700 : Colors.amber.shade700, 
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Row(
                    children: [
                      Icon(profile.isPremium ? Icons.verified : Icons.star, color: Colors.white, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        profile.isPremium 
                          ? (isBn ? "সক্রিয়" : "ACTIVE") 
                          : (isBn ? "প্রিমিয়ম" : "PREMIUM"), 
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGuidanceCard(
          isBn ? "পরামর্শ" : "Advice", 
          WeatherInsightService.getDailyAdvice(condition, temp, humidity, profile.mode, lang), 
          Icons.lightbulb, 
          Colors.amber,
          isLocked: isLocked
        ),
        const SizedBox(height: 12),
        _buildGuidanceCard(
          isBn ? "পোশাক" : "Clothing", 
          WeatherInsightService.getOutfitRecommendation(condition, temp, lang), 
          Icons.checkroom, 
          Colors.blue,
          isLocked: isLocked
        ),
        if (profile.mode == UserMode.student) ...[
          const SizedBox(height: 12),
          _buildGuidanceCard(
            isBn ? "পড়াশোনা" : "Study Comfort", 
            WeatherInsightService.getStudentSpecificInsights(temp, humidity, condition, lang)['studyComfort']['text'], 
            Icons.menu_book, 
            Colors.indigo,
            isLocked: isLocked,
            subtitle: WeatherInsightService.getStudentSpecificInsights(temp, humidity, condition, lang)['studyComfort']['status']
          ),
          const SizedBox(height: 12),
          _buildGuidanceCard(
            isBn ? "পরীক্ষা সহায়িকা" : "Exam-Day Awareness", 
            "${isBn ? "ঝুঁকি:" : "Risk:"} ${WeatherInsightService.getStudentSpecificInsights(temp, humidity, condition, lang)['examAlert']['risk']}. ${isBn ? "পরামর্শ:" : "Advice:"} ${WeatherInsightService.getStudentSpecificInsights(temp, humidity, condition, lang)['examAlert']['suggestion']}", 
            Icons.assignment_turned_in, 
            Colors.red,
            isLocked: isLocked
          ),
          const SizedBox(height: 12),
          _buildGuidanceCard(
            isBn ? "সন্ধ্যায় ফিরতি পথ" : "Evening Return Safety", 
            "${isBn ? "ঝুঁকি:" : "Risk:"} ${WeatherInsightService.getStudentSpecificInsights(temp, humidity, condition, lang)['tuitionReturn']['risk']}. ${isBn ? "দৃশ্যমানতা:" : "Visibility:"} ${WeatherInsightService.getStudentSpecificInsights(temp, humidity, condition, lang)['tuitionReturn']['visibility']}", 
            Icons.nights_stay, 
            Colors.deepPurple,
            isLocked: isLocked
          ),
          const SizedBox(height: 12),
          _buildGuidanceCard(
            isBn ? "যাতায়াত প্রস্তুতি" : "Class Readiness", 
            "${isBn ? "যাতায়াত:" : "Commute:"} ${WeatherInsightService.getStudentSpecificInsights(temp, humidity, condition, lang)['readiness']['commute']}. ${isBn ? "বিকালে পরামর্শ:" : "Afternoon:"} ${WeatherInsightService.getStudentSpecificInsights(temp, humidity, condition, lang)['readiness']['afternoon']}", 
            Icons.school, 
            Colors.teal,
            isLocked: isLocked
          ),
          const SizedBox(height: 12),
          _buildGuidanceCard(
            isBn ? "বাইরের কার্যকলাপ" : "Outdoor Activity", 
            "${isBn ? "সেরা সময়:" : "Best time:"} ${WeatherInsightService.getStudentSpecificInsights(temp, humidity, condition, lang)['outdoor']['best']}. ${isBn ? "এড়িয়ে চলুন:" : "Avoid:"} ${WeatherInsightService.getStudentSpecificInsights(temp, humidity, condition, lang)['outdoor']['avoid']}", 
            Icons.sports_soccer, 
            Colors.orange,
            isLocked: isLocked
          ),
        ],
        if (profile.mode == UserMode.general && profile.isPremium) ...[
          const SizedBox(height: 12),
          _buildGuidanceCard(
            isBn ? "আজকের বিশেষ টিপস" : "Today's Key Tip", 
            WeatherInsightService.getGeneralRefinements(temp, humidity, condition, lang)['keyTip'], 
            Icons.tips_and_updates, 
            Colors.amber,
            isLocked: false
          ),
        ],
      ],
    );
  }

  Widget _buildProfileHeader(ProfileService profile, bool isBn) {
    String title = isBn ? "সাধারণ মোড" : "General Mode";
    IconData icon = Icons.person_outline;
    MaterialColor color = Colors.teal;

    if (profile.mode == UserMode.farmer) {
      title = isBn ? "কৃষক সহায়তা প্রোফাইল" : "Farmer Intelligence";
      icon = Icons.agriculture;
      color = Colors.green;
    } else if (profile.mode == UserMode.worker) {
      title = isBn ? "শ্রমিক সুরক্ষা প্রোফাইল" : "Worker Safety Profile";
      icon = Icons.engineering;
      color = Colors.orange;
    } else if (profile.mode == UserMode.student) {
      title = isBn ? "শিক্ষার্থী প্রোফাইল" : "Student Profile";
      icon = Icons.school;
      color = Colors.indigo;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: WeatherTheme.getGlassyDecoration(opacity: 0.1, color: color),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color.shade900)),
          const Spacer(),
          if (profile.impactScore > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(
                isBn ? "${profile.impactScore}টি সিদ্ধান্ত প্রভাবিত" : "${profile.impactScore} Decisions Influenced",
                style: TextStyle(fontSize: 10, color: color.shade800, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumIntelligence(ProfileService profile, String condition, double temp, double humidity, String lang) {
    bool isLocked = !profile.isPremium && profile.mode != UserMode.general;
    bool isBn = lang == 'bn';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getSmartGuidanceTitle(profile.mode, isBn),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (profile.mode != UserMode.general)
              _buildPremiumBadge(profile, isBn),
          ],
        ),
        const SizedBox(height: 16),
        if (profile.mode == UserMode.general) ...[
          _buildGeneralSmartDecisions(temp, humidity, condition, lang),
          const SizedBox(height: 16),
        ],
        if (profile.mode == UserMode.farmer)
          _buildCropRiskCard(profile, temp, condition, 15, lang, isLocked: isLocked),
        if (profile.mode == UserMode.worker)
          _buildWorkSafetyBanner(profile, temp, humidity, condition, lang, isLocked: isLocked),
        if (profile.mode == UserMode.student)
          _buildStudentRecordCard(temp, humidity, condition, lang, isLocked: isLocked),
        
        if (profile.isPremium) ...[
           _buildTomorrowPreview(profile.mode, temp, condition, lang),
           const SizedBox(height: 16),
        ],
        _buildWhyThisAdvice(profile.isPremium, temp, humidity, condition, lang),
        if (isLocked) ...[
          const SizedBox(height: 12),
          Text(
            isBn ? "• পরিস্থিতি স্বাভাবিক হলে আমরা আপনাকে জানাবো" : "• We will notify you when it becomes safe again.",
            style: TextStyle(color: Colors.teal.shade700, fontSize: 11, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
          ),
        ]
      ],
    );
  }

  Widget _buildPremiumBadge(ProfileService profile, bool isBn) {
    bool isPremium = profile.isPremium;
    return InkWell(
      onTap: () {
        bool newState = !isPremium;
        profile.setPremium(newState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newState 
              ? _getActivationMessage(profile.mode, isBn)
              : (isBn ? "স্মার্ট গাইডেন্স নিষ্ক্রিয় করা হয়েছে" : "Smart Guidance Deactivated")),
            backgroundColor: newState ? Colors.amber.shade900 : Colors.blueGrey,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isPremium ? Colors.green.shade700 : Colors.amber.shade700, 
          borderRadius: BorderRadius.circular(8)
        ),
        child: Text(
          isPremium 
            ? (isBn ? "নিষ্ক্রিয় করুন" : "DEACTIVATE") 
            : (isBn ? "সক্রিয় করুন" : "ACTIVATE"), 
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }

  String _getSmartGuidanceTitle(UserMode mode, bool isBn) {
    if (isBn) {
      switch (mode) {
        case UserMode.worker:
          return "কাজের নিরাপত্তা সহায়তা";
        case UserMode.farmer:
          return "ফসল ও কাজের পরিকল্পনা";
        case UserMode.student:
          return "পড়াশোনা ও যাতায়াত সহায়তা";
        case UserMode.general:
          return "দৈনিক পরিকল্পনা";
      }
    } else {
      switch (mode) {
        case UserMode.worker:
          return "Work Safety Assist";
        case UserMode.farmer:
          return "Crop & Work Planner";
        case UserMode.student:
          return "Study & Commute Assist";
        case UserMode.general:
          return "Daily Planner";
      }
    }
  }

  String _getActivationMessage(UserMode mode, bool isBn) {
    if (isBn) {
      switch (mode) {
        case UserMode.worker:
          return "কাজের নিরাপত্তা সহায়তা সক্রিয় করা হয়েছে";
        case UserMode.farmer:
          return "ফসল ও কাজের পরিকল্পনা সক্রিয় করা হয়েছে";
        case UserMode.student:
          return "পড়াশোনা ও যাতায়াত সহায়তা সক্রিয় করা হয়েছে";
        case UserMode.general:
          return "দৈনিক পরিকল্পনা সক্রিয় করা হয়েছে";
      }
    } else {
      switch (mode) {
        case UserMode.worker:
          return "Work Safety Assist Activated";
        case UserMode.farmer:
          return "Crop & Work Planner Activated";
        case UserMode.student:
          return "Study & Commute Assist Activated";
        case UserMode.general:
          return "Daily Planner Activated";
      }
    }
  }

  Widget _buildGeneralSmartDecisions(double temp, double humidity, String condition, String lang) {
    bool isBn = lang == 'bn';
    final tip = WeatherInsightService.getGeneralRefinements(temp, humidity, condition, lang)['keyTip'];
    
    return Column(
      children: [
        _buildSpecialCard(
          isBn ? "আজকের বিশেষ টিপস" : "Today's Key Tip", 
          tip, 
          Icons.tips_and_updates, 
          Colors.amber
        ),
        const SizedBox(height: 16),
        _buildDailyPlanTimeline(temp, humidity, condition, lang),
      ],
    );
  }

  Widget _buildDailyPlanTimeline(double temp, double humidity, String condition, String lang) {
    final plan = WeatherInsightService.getDailySmartPlan(temp, humidity, condition, lang);
    final riskTimeline = WeatherInsightService.getRiskTimeline(lang);
    bool isBn = lang == 'bn';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: WeatherTheme.getGlassyDecoration(opacity: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isBn ? "স্মার্ট পরিকল্পনা ও ঝুঁকি" : "Smart Plan & Risk Window", style: const TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.timeline, size: 16, color: Colors.teal.shade700),
            ],
          ),
          const SizedBox(height: 16),
          Text(isBn ? "পরবর্তী ৬ ঘণ্টার ঝুঁকি:" : "Next 6-Hour Risk Timeline:", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: riskTimeline.map((item) => Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (item['isHighRisk'] as bool ? Colors.red : Colors.green).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (item['isHighRisk'] as bool ? Colors.red : Colors.green).withValues(alpha: 0.2))
                ),
                child: Column(
                  children: [
                    Text(item['hour'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(item['status'] as String, style: TextStyle(fontSize: 10, color: item['isHighRisk'] as bool ? Colors.red : Colors.green, fontWeight: FontWeight.w900)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const Divider(height: 32),
          ...plan.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['time'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(item['action'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                Text(item['status'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item['color'] as Color)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCropRiskCard(ProfileService profile, double temp, String condition, double windSpeed, String lang, {bool isLocked = false}) {
    final data = WeatherInsightService.getCropRiskData(temp, condition, windSpeed, lang, crop: profile.selectedCrop);
    final isBn = lang == 'bn';
    
    return _buildBlurWrapper(
      isLocked: isLocked,
      title: isBn ? "ফসল ঝুঁকি ও সময় সংক্রান্ত" : "Crop Risk & Work Window",
      previewHeader: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isBn ? "আজকের ঝুঁকি:" : "Risk Today:", style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: (data['color'] as Color).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(data['level'] as String, style: TextStyle(color: data['color'] as Color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (!isLocked) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(isBn ? "আস্থার স্তর: " : "Action Confidence: ", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text("${data['confidence']['level']} ${data['confidence']['icon']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            Text(data['confidence']['text'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.isPremium) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["General Crops", "Rice", "Vegetables", "Jute"].map((c) {
                  bool sel = profile.selectedCrop == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c, style: TextStyle(fontSize: 10, color: sel ? Colors.white : Colors.black)),
                      selected: sel,
                      onSelected: (v) {
                        profile.updateSelectedCrop(c);
                        profile.incrementImpactScore();
                      },
                      selectedColor: Colors.green,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Text(data['cropNote'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 12),
          ],
          if (profile.lastTransitionTime != null && DateTime.now().difference(profile.lastTransitionTime!).inMinutes < 60)
             Container(
               margin: const EdgeInsets.only(bottom: 8),
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
               child: Text(isBn ? "স্ট্যাটাস সম্প্রতি পরিবর্তিত হয়েছে" : "Status changed recently", style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
             ),
          const SizedBox(height: 12),
          ...((data['reasons'] as List).map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [const Icon(Icons.info_outline, size: 12), const SizedBox(width: 8), Text(r as String, style: const TextStyle(fontSize: 12))]),
          ))),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(isBn ? "সেরা কাজের সময়:" : "Safe Window:", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(data['safeWindow'] as String, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          if (!isLocked) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isBn ? "এই সময় হাতছাড়া হলে:" : "If you miss this window:", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(data['ifYouMiss'], style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSpecialCard(
              isBn ? "লোকসান রোধ ইনসাইট" : "Loss Prevention Insight",
              data['lossPrevention'],
              Icons.trending_down,
              Colors.red
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.notifications_active, size: 14, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  isBn ? "পরিস্থিতি পরিবর্তন হলে আমরা আপনাকে জানাব।" : "We'll notify you when conditions change.",
                  style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkSafetyBanner(ProfileService profile, double temp, double humidity, String condition, String lang, {bool isLocked = false}) {
    final data = WeatherInsightService.getWorkSafetyStatus(temp, humidity, condition, lang);
    bool isUnsafe = data['status'] == (lang == 'bn' ? "অনিরাপদ" : "UNSAFE");
    final isBn = lang == 'bn';
    
    return _buildBlurWrapper(
      isLocked: isLocked,
      title: isBn ? "কর্মক্ষেত্র নিরাপত্তা ডিটেক্টর" : "Work Safety Detector",
      previewHeader: Column(
        children: [
          Row(
            children: [
              Icon(isUnsafe ? Icons.warning_rounded : Icons.security, color: data['color'] as Color, size: 24),
              const SizedBox(width: 12),
              Text(
                "${isBn ? "স্ট্যাটাস:" : "STATUS:"} ${data['status']}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: data['color'] as Color, letterSpacing: 1.2),
              ),
            ],
          ),
          if (!isLocked) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(isBn ? "শক্তি ক্ষয় পর্যায়: " : "Energy Drain: ", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(data['energyDrain']['level'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ]
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.lastTransitionTime != null && DateTime.now().difference(profile.lastTransitionTime!).inMinutes < 60)
             Container(
               margin: const EdgeInsets.only(bottom: 8),
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
               child: Text(isBn ? "স্ট্যাটাস সম্প্রতি পরিবর্তিত হয়েছে" : "Status changed recently", style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
             ),
          const SizedBox(height: 8),
          Text(data['reason'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(data['energyDrain']['text'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (data['avoidHours'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(
                "${isBn ? "এড়িয়ে চলুন:" : "Avoid outdoor work"} ${data['avoidHours']}",
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
          if (!isLocked) ...[
            const SizedBox(height: 16),
            Text(isBn ? "প্রস্তাবিত ব্রেক প্যাটার্ন:" : "Recommended Break Pattern:", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(data['breakPattern'], style: const TextStyle(fontSize: 12, height: 1.5)),
            const SizedBox(height: 12),
            _buildSpecialCard(
              isBn ? "উপার্জন সুরক্ষা ইনসাইট" : "Earnings Protection Insight",
              data['earningsProtection'],
              Icons.payments_outlined,
              Colors.orange
            ),
            const SizedBox(height: 12),
            _buildSpecialCard(
              isBn ? "আজকের কাজের সারাংশ" : "Today's Work Summary",
              "• ${isBn ? "⏰ অনিরাপদ সময়:" : "⏰ Unsafe hours:"} ${data['dailySummary']['unsafe']}\n• ${isBn ? "✅ সেরা কাজের সময়:" : "✅ Best work time:"} ${data['dailySummary']['best']}",
              Icons.summarize,
              Colors.blue
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.notifications_active, size: 14, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  isBn ? "পরিস্থিতি পরিবর্তন হলে আমরা আপনাকে জানাব।" : "We will notify you when conditions improve.",
                  style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlurWrapper({required bool isLocked, required String title, required Widget child, Widget? previewHeader}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            if (isLocked) const Icon(Icons.lock_open_outlined, size: 14, color: Colors.amber),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (previewHeader != null) ...[
                previewHeader,
                if (!isLocked) const Divider(height: 24),
              ],
              Stack(
                children: [
                  child,
                  if (isLocked)
                    Positioned.fill(
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.1),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "UNLOCK PREMIUM DETAILS",
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.black87, fontSize: 13, letterSpacing: 1),
                                ),
                                const SizedBox(height: 4),
                                const Text("See safe work windows & risk factors", style: TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyRiskSummary(ProfileService profile, double temp, String condition, String lang) {
    if (profile.mode == UserMode.general || (profile.isPremium && !profile.dailySummaryEnabled)) return const SizedBox.shrink();
    final summary = WeatherInsightService.getDailyRiskSummary(profile.mode, temp, condition, lang);
    if (summary.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(summary['title'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: WeatherTheme.getGlassyDecoration(opacity: 0.1),
          child: Column(
            children: (summary['risks'] as List).map((risk) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(risk['label'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Container(
                    width: 80,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: (risk['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(risk['level'] as String, style: TextStyle(color: risk['color'] as Color, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWhyThisAdvice(bool isPremium, double temp, double humidity, String condition, String lang) {
    final logs = WeatherInsightService.getAdviceExplanation(temp, humidity, condition, lang);
    final isBn = lang == 'bn';
    final confidence = WeatherInsightService.getForecastConfidence(lang);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.1)),
      ),
      child: ExpansionTile(
        title: Text(isBn ? "আমরা এটি কীভাবে সিদ্ধান্ত নিয়েছি" : "How we decided this", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
        subtitle: Row(
          children: [
            Text("${isBn ? "পূর্বাভাস আস্থা:" : "Forecast Confidence:"} ", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text("${confidence['level']} ${confidence['icon']}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        leading: const Icon(Icons.analytics_outlined, size: 18, color: Colors.teal),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPremium) ...[
                   _buildHistoryInsight(lang),
                   const SizedBox(height: 12),
                   _buildWhatIfSection(lang),
                   const SizedBox(height: 12),
                   const Divider(),
                   const SizedBox(height: 12),
                ],
                Text(isBn ? "ব্যব্যহৃত প্যারামিটার:" : "Parameters used:", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(confidence['text'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 12),
                ...logs.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 12, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(log, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                )),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSpecialCard(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1))
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRecordCard(double temp, double humidity, String condition, String lang, {bool isLocked = false}) {
    final data = WeatherInsightService.getStudentSpecificInsights(temp, humidity, condition, lang);
    final isBn = lang == 'bn';

    return Column(
      children: [
        _buildSpecialCard(
          isBn ? "পড়াশোনা ও যাতায়াত প্রস্তুতি" : "Student Readiness", 
          "${isBn ? "ঝুঁকি:" : "Risk:"} ${data['examAlert']['risk']}. ${isBn ? "পরামর্শ:" : "Advice:"} ${data['examAlert']['suggestion']}", 
          Icons.school_outlined, 
          Colors.indigo
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: WeatherTheme.getGlassyDecoration(opacity: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isBn ? "একাডেমিক ইনসাইট" : "Academic Insights", style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (isLocked) const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSmallPreviewItem(
                    isBn ? "স্টাডি কমফোর্ট:" : "Study Comfort:",
                    data['studyComfort']['status'],
                    Icons.menu_book,
                    Colors.indigo
                  ),
                  _buildSmallPreviewItem(
                    isBn ? "ক্লাস যাতায়াত:" : "Commute:",
                    data['readiness']['commute'],
                    Icons.directions_walk,
                    Colors.green
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildSpecialCard(
                isBn ? "টিউশন ফিরতি পথ" : "Tuition Return Safety",
                "${isBn ? "ঝুঁকি:" : "Risk:"} ${data['tuitionReturn']['risk']}. ${isBn ? "দৃশ্যমানতা:" : "Visibility:"} ${data['tuitionReturn']['visibility']}",
                Icons.nightlight_round,
                Colors.purple
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTomorrowPreview(UserMode mode, double temp, String condition, String lang) {
    bool isBn = lang == 'bn';
    
    if (mode == UserMode.farmer) {
      final data = WeatherInsightService.getCropRiskData(temp, condition, 15, lang);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withValues(alpha: 0.1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isBn ? "আগামীকালের কৃষি আউটলুক" : "Tomorrow's Farming Outlook", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSmallPreviewItem(isBn ? "বৃষ্টির ঝুঁকি" : "Rain Risk", data['tomorrowPreview']['risk'], Icons.water_drop, Colors.orange),
                _buildSmallPreviewItem(isBn ? "কাজের উইন্ডো" : "Best Window", data['tomorrowPreview']['window'], Icons.timer, Colors.blue),
              ],
            ),
          ],
        ),
      );
    }

    final morning = WeatherInsightService.getTomorrowMorningPreview(condition, lang);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isBn ? "আগামীকাল সকালে যাতায়াত" : "Tomorrow Morning Outlook", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallPreviewItem(isBn ? "অবস্থা" : "Condition", morning['condition'], Icons.cloud_outlined, Colors.indigo),
              _buildSmallPreviewItem(isBn ? "যাতায়াত" : "Travel", morning['comfort'], Icons.directions_car, Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallPreviewItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryInsight(String lang) {
    bool isBn = lang == 'bn';
    return _buildSpecialCard(
      isBn ? "ইতিহাস-ভিত্তিক ইনসাইট" : "History-Based Insight",
      WeatherInsightService.getHistoryBasedInsight(lang),
      Icons.history,
      Colors.blueGrey
    );
  }

  Widget _buildWhatIfSection(String lang) {
    final data = WeatherInsightService.getWhatIfConditionsChange(lang);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(data['title'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.help_outline, size: 18),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: (data['scenarios'] as List).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right, size: 16),
                    Expanded(child: Text(s as String, style: const TextStyle(fontSize: 11))),
                  ],
                ),
              )).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGuidanceCard(String title, String content, IconData icon, MaterialColor color, {bool isLocked = false, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), radius: 18, child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 16),
          Expanded(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color.shade700, fontSize: 13)),
                        if (subtitle != null)
                          Text(subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.shade900)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isLocked)
                      Text(
                        content, 
                        style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.transparent)
                      )
                    else
                      ...content.split(RegExp(r'\. |\n')).where((s) => s.trim().isNotEmpty).map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("• ", style: TextStyle(color: color.shade700, fontWeight: FontWeight.bold)),
                            Expanded(child: Text(s.trim(), style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black87))),
                          ],
                        ),
                      )).toList(),
                  ],
                ),
                if (isLocked)
                  Positioned.fill(
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Unlock premium for specific advice",
                            style: GoogleFonts.outfit(color: color.shade900, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
