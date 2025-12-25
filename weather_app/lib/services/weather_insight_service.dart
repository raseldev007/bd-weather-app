import 'package:flutter/material.dart';
import '../services/profile_service.dart';

enum OutcomeState { safe, caution, unsafe }

class WeatherInsightService {
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'advice': 'Advice',
      'outfit': 'Clothing',
      'activity': 'Activity',
      'carry_umbrella': 'Carry an umbrella',
      'avoid_outdoor': 'Avoid outdoor activity at noon',
      'stay_hydrated': 'Stay hydrated, it\'s a hot day!',
      'keep_warm': 'Keep yourself warm.',
      'strong_wind': 'Strong wind expected',
      'waterlogging': 'Urban waterlogging risk high in Dhaka/Chittagong.',
      'lightning': 'High lightning risk. Stay away from open fields.',
      'cyclone': 'Cyclone Warning: Seek safe shelter immediately.',
      'flood': 'Flood Alert: River levels rising near you.',
      'monsoon_early': 'Monsoon started. Moderate rainfall expected.',
      'monsoon_peak': 'Monsoon peak. Heavy continuous rain likely.',
      'commute_delay': 'Heavy rain may cause significant traffic delays.',
    },
    'bn': {
      'advice': 'পরামর্শ',
      'outfit': 'পোশাক',
      'activity': 'কার্যকলাপ',
      'carry_umbrella': 'সাথে ছাতা রাখুন',
      'avoid_outdoor': 'দুপুরে ঘরের বাইরে যাওয়া এড়িয়ে চলুন',
      'stay_hydrated': 'প্রচুর পানি পান করুন, আজ খুব গরম!',
      'keep_warm': 'নিজেকে উষ্ণ রাখুন।',
      'strong_wind': 'প্রবল বাতাসের সম্ভাবনা',
      'waterlogging': 'ঢাকা/চট্টগ্রামে জলাবদ্ধতার ঝুঁকি রয়েছে।',
      'lightning': 'বজ্রপাতের উচ্চ ঝুঁকি। খোলা মাঠ থেকে দূরে থাকুন।',
      'cyclone': 'ঘূর্ণিঝড় সতর্কতা: দ্রুত নিরাপদ আশ্রয়ে যান।',
      'flood': 'বন্যা সতর্কতা: আপনার কাছাকাছি নদীর পানি বাড়ছে।',
      'monsoon_early': 'বর্ষাকাল শুরু হয়েছে। মাঝারি বৃষ্টির সম্ভাবনা।',
      'monsoon_peak': 'বর্ষার মাঝামাঝি সময়। ভারি বৃষ্টির সম্ভাবনা।',
      'commute_delay': 'ভারি বৃষ্টির কারণে যানজটের সম্ভাবনা রয়েছে।',
    }
  };

  static String t(String key, String lang) => _translations[lang]?[key] ?? key;

  static double calculateHeatIndex(double temp, double humidity) {
    // Simple Heat Index approximation
    // HI = T + 0.5 * (temp - 10) * (humidity / 100)
    return temp + (0.5 * (temp - 10.0) * (humidity / 100.0));
  }

  static String getMonsoonPhase(String lang) {
    int month = DateTime.now().month;
    if (month == 6) return t('monsoon_early', lang);
    if (month == 7 || month == 8) return t('monsoon_peak', lang);
    if (month == 9) return lang == 'bn' ? "বর্ষার শেষ সময়। হালকা বৃষ্টির সম্ভাবনা।" : "Late monsoon. Light scattered rain.";
    return "";
  }

  static String getDailyAdvice(String condition, double temp, double humidity, String lang, {double rainProb = 0, double windSpeed = 0, String city = ""}) {
    List<String> advices = [];
    double heatIndex = calculateHeatIndex(temp, humidity);
    int hour = DateTime.now().hour;
    
    // Core Advice based on PRD rules
    if (rainProb > 60 || condition.toLowerCase().contains('rain')) {
      advices.add(t('carry_umbrella', lang));
    }
    
    if (heatIndex > 38) {
      advices.add(t('avoid_outdoor', lang));
    } else if (temp > 30) {
      advices.add(t('stay_hydrated', lang));
    }

    if (windSpeed > 30) {
       advices.add(t('strong_wind', lang));
    }

    // Monsoon Intelligence
    String monsoon = getMonsoonPhase(lang);
    if (monsoon.isNotEmpty) {
       // Only show monsoon status if relevant
       if (condition.toLowerCase().contains('rain')) advices.add(monsoon);
    }

    if (advices.isEmpty) return lang == 'bn' ? "আপনার দিনটি ভালো কাটুক!" : "Have a wonderful day!";
    return advices.join(". ");
  }

  static String getOutfitRecommendation(String condition, double temp, String lang) {
    String base = "";
    if (temp > 30) {
      base = lang == 'bn' ? "হালকা সুতির পোশাক" : "Light, breathable clothes";
    } else if (temp >= 20) {
      base = lang == 'bn' ? "স্বাভাবিক পোশাক" : "Normal wear";
    } else {
      base = lang == 'bn' ? "হালকা জ্যাকেট" : "Light jacket recommended";
    }

    if (condition.toLowerCase().contains('rain')) {
      return "$base + ${lang == 'bn' ? "রেইনকোট/ছাতা" : "raincoat/umbrella"}";
    }

    // Student specific clothing
    if (temp > 32) {
      return lang == 'bn' ? "হালকা সুতির ইউনিফর্ম পরুন" : "Wear light cotton uniform";
    }
    
    return base;
  }

  static String getStudyComfort(double temp, double humidity, String lang) {
    double heatIndex = calculateHeatIndex(temp, humidity);
    if (heatIndex > 35) {
      return lang == 'bn' ? "গরম এবং আর্দ্র - পড়ার জন্য অস্বস্তিকর। ফ্যান বা ভেন্টিলেশন ব্যবহার করুন।" : "Hot and humid - Uncomfortable for study. Use ventilation.";
    }
    if (temp < 18) {
       return lang == 'bn' ? "ঠান্ডা আবহাওয়া - নিবিড় মনে পড়ার জন্য বেশ ভালো সময়।" : "Cool weather - Great for focused study.";
    }
    return lang == 'bn' ? "পড়াশোনার জন্য মনোরম পরিবেশ।" : "Pleasant environment for studying.";
  }

  static String getActivitySuggestion(String condition, double temp, String lang) {
    if (temp > 32) {
      return lang == 'bn' 
        ? "বাইরে যাওয়ার উপযুক্ত সময়: সকাল ৬-৮ টা" 
        : "Best outdoor time: 6–8 AM (Avoid the heat)";
    } else if (condition.toLowerCase().contains('rain')) {
      return lang == 'bn' 
        ? "বৃষ্টির কারণে ইনডোর কার্যক্রমের পরামর্শ" 
        : "Indoor activities recommended due to rain";
    } else {
      return lang == 'bn' 
        ? "বিকেলে হাঁটার জন্য খুব ভালো সময় (৪-৬ টা)" 
        : "Great time for a walk: 4–6 PM";
    }
  }

  static Map<String, dynamic>? getPrimaryAlert(String condition, double temp, double humidity, String city, String lang) {
    double heatIndex = calculateHeatIndex(temp, humidity);

    // Prioritize Cyclone first
    if (condition.toLowerCase().contains('storm') && (city == 'Chittagong' || city == 'Khulna')) {
      return {
        "title": lang == 'bn' ? "ঘূর্ণিঝড় সতর্কতা" : "Cyclone Warning",
        "message": t('cyclone', lang),
        "icon": "🌪️",
        "severity": "red"
      };
    }

    // Flood / Waterlogging
    if (condition.toLowerCase().contains('rain')) {
       if (city == 'Dhaka' || city == 'Chittagong') {
         return {
          "title": lang == 'bn' ? "জলাবদ্ধতা ঝুঁকি" : "Waterlogging Alert",
          "message": t('waterlogging', lang),
          "icon": "🌊",
          "severity": "orange"
        };
       }
    }

    // Lightning
    if (condition.toLowerCase().contains('storm')) {
      return {
          "title": lang == 'bn' ? "বজ্রপাত সতর্কতা" : "Lightning Risk",
          "message": t('lightning', lang),
          "icon": "🌩️",
          "severity": "red"
        };
    }

    // Heatwave
    if (heatIndex > 40) {
      return {
        "title": lang == 'bn' ? "তীব্র দাবদাহ" : "Extreme Heatwave",
        "message": t('stay_hydrated', lang),
        "icon": "🔥",
        "severity": "red"
      };
    }

    // Commute for rain
    if (condition.toLowerCase().contains('rain')) {
      return {
        "title": lang == 'bn' ? "যাতায়াত সতর্কতা" : "Commute Alert",
        "message": t('commute_delay', lang),
        "icon": "🚗",
        "severity": "yellow"
      };
    }

    return null;
  }

  static Map<String, dynamic> getDecisionInsights(String condition, double temp, double humidity, String lang) {
    bool isBn = lang == 'bn';
    List<String> bullets = [];
    double heatIndex = calculateHeatIndex(temp, humidity);
    
    if (condition.toLowerCase().contains('rain')) {
      bullets.add(isBn ? "সন্ধ্যায় বৃষ্টির প্রবল সম্ভাবনা" : "Heavy rain expected in the evening");
      bullets.add(isBn ? "জলাবদ্ধতার ঝুঁকি রয়েছে" : "Moderate waterlogging risk");
      bullets.add(isBn ? "যাতায়াত ধীরগতির হতে পারে" : "Evening travel may be slow");
    } else if (heatIndex > 38) {
      bullets.add(isBn ? "তীব্র তাপপ্রবাহের সতর্কতা" : "Extreme heatwave caution");
      bullets.add(isBn ? "দুপুরে বাইরে যাওয়া বিপজ্জনক" : "Dangerous to be outside at noon");
      bullets.add(isBn ? "জলশূন্যতা রোধে পানি পান করুন" : "Stay hydrated to avoid dehydration");
    } else {
      bullets.add(isBn ? "আবহাওয়া অনুকূলে রয়েছে" : "Weather is currently favorable");
      bullets.add(isBn ? "বাইরের কাজের জন্য ভালো সময়" : "Good time for outdoor activities");
      bullets.add(isBn ? "বিকেলে হাঁটার পরিকল্পনা করতে পারেন" : "You can plan an evening walk");
    }

    return {
      "title": isBn ? "আজ আপনার জন্য এর অর্থ কী" : "What this means for you today",
      "bullets": bullets,
    };
  }

  static List<Map<String, dynamic>> getRiskTimeline(String lang) {
    bool isBn = lang == 'bn';
    int currentHour = DateTime.now().hour;
    
    return List.generate(6, (index) {
      int hour = (currentHour + index) % 24;
      bool isHighRisk = hour >= 14 && hour <= 16; // Simulated risk for mid-afternoon heat

      return {
        "hour": "${hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)} ${hour >= 12 ? 'PM' : 'AM'}",
        "status": isHighRisk ? (isBn ? "ঝুঁকিপূর্ণ" : "Risky") : (isBn ? "নিরাপদ" : "Safe"),
        "isHighRisk": isHighRisk,
      };
    });
  }

  static List<Map<String, dynamic>> getDailySmartPlan(double temp, double humidity, String condition, String lang) {
    bool isBn = lang == 'bn';
    double heatIndex = calculateHeatIndex(temp, humidity);
    
    return [
      {
        "time": isBn ? "সকাল (৬-৯ টা)" : "Morning (6–9 AM)",
        "status": isBn ? "নিরাপদ" : "Safe",
        "action": isBn ? "বাইরের কাজের সেরা সময়" : "Best time for outdoors",
        "icon": Icons.check_circle,
        "color": Colors.green,
      },
      {
        "time": isBn ? "দুপুর (১২-৩ টা)" : "Noon (12–3 PM)",
        "status": heatIndex > 35 ? (isBn ? "সতর্কতা" : "Caution") : (isBn ? "নিরাপদ" : "Safe"),
        "action": heatIndex > 35 ? (isBn ? "ছায়া অবলম্বন করুন" : "Limit heavy activity") : (isBn ? "কাজ চালিয়ে যান" : "Continue work"),
        "icon": heatIndex > 35 ? Icons.warning_amber_rounded : Icons.check_circle,
        "color": heatIndex > 35 ? Colors.orange : Colors.green,
      },
      {
        "time": isBn ? "সন্ধ্যা (৬-৯ টা)" : "Evening (6–9 PM)",
        "status": condition.toLowerCase().contains('rain') ? (isBn ? "এড়িয়ে চলুন" : "Avoid") : (isBn ? "নিরাপদ" : "Safe"),
        "action": condition.toLowerCase().contains('rain') ? (isBn ? "বৃষ্টির সম্ভাবনা প্রবল" : "Heavy rain expected") : (isBn ? "আরামদায়ক আবহাওয়া" : "Pleasant weather"),
        "icon": condition.toLowerCase().contains('rain') ? Icons.cancel : Icons.check_circle,
        "color": condition.toLowerCase().contains('rain') ? Colors.red : Colors.green,
      },
    ];
  }

  static Map<String, dynamic> getCropRiskData(double temp, String condition, double windSpeed, String lang, {String crop = "General Crops"}) {
    bool isBn = lang == 'bn';
    String risk = "Low";
    String bnRisk = "নিম্ন";
    Color color = Colors.green;
    OutcomeState state = OutcomeState.safe;
    List<String> reasons = [];

    if (condition.toLowerCase().contains('rain')) {
      risk = "High";
      bnRisk = "উচ্চ";
      color = Colors.red;
      state = OutcomeState.unsafe;
      reasons.add(isBn ? "বৃষ্টির পানি চারা নষ্ট করতে পারে" : "Rain may damage seedlings");
    } else if (temp > 35) {
      risk = "Medium";
      bnRisk = "মাঝারি";
      color = Colors.orange;
      state = OutcomeState.caution;
      reasons.add(isBn ? "অতিরিক্ত গরমে পানিশূন্যতা" : "Heat stress in crops");
    }

    if (windSpeed > 25) {
      reasons.add(isBn ? "ঝড়ো বাতাসের ঝুঁকি" : "High wind risk");
    }

    // New Premium Insights
    Map<String, dynamic> confidence = {
      "level": "HIGH",
      "text": isBn ? "সার প্রয়োগের জন্য উপযুক্ত পরিবেশ" : "Suitable conditions for fertilizer application",
      "icon": "✅"
    };

    String missConsequence = isBn 
      ? "• পরবর্তী সুযোগ: আগামীকাল সকাল ৬–৮ টা\n• সকাল ১০টার পর ঝুঁকি: বৃষ্টি + সার ধুয়ে যাওয়া" 
      : "• Next suitable time: Tomorrow 6–8 AM\n• Risk after 10 AM: Rain + runoff";

    String lossPrevention = isBn 
      ? "• বৃষ্টির ঠিক আগে সার প্রয়োগ করলে তা ধুয়ে যেতে পারে।\n• এতে ফসলের পুষ্টিগুণ ও আর্থিক বিনিয়োগ উভয়ই ক্ষতিগ্রস্ত হয়।" 
      : "• Fertilizer applied just before rain may wash away.\n• This causes loss of nutrients and financial investment.";

    String cropNote = crop == "Rice" ? (isBn ? "ধান ক্ষেতের জন্য এই সময়টি আদর্শ।" : "For rice fields, this window is ideal.")
                    : crop == "Vegetables" ? (isBn ? "শাকসবজির জন্য সাধারণ যত্ন নিন।" : "General care for vegetable plots.")
                    : (isBn ? "ফসলের সাধারণ যত্নের জন্য উপযুক্ত সময়।" : "Ideal window for general crop maintenance.");

    return {
      "level": isBn ? bnRisk : risk,
      "color": color,
      "state": state,
      "reasons": reasons,
      "safeWindow": isBn ? "সকাল ৭-১০ টা (নিরাপদ)" : "7–10 AM (Best window)",
      "confidence": confidence,
      "ifYouMiss": missConsequence,
      "lossPrevention": lossPrevention,
      "cropNote": cropNote,
      "tomorrowPreview": {
        "risk": isBn ? "মাঝারি" : "Medium",
        "window": isBn ? "ভোরবেলা" : "Early morning",
        "rain": isBn ? "বৃষ্টির সম্ভাবনা" : "Rain risk"
      }
    };
  }

  static Map<String, dynamic> getWorkSafetyStatus(double temp, double humidity, String condition, String lang) {
    bool isBn = lang == 'bn';
    double heatIndex = calculateHeatIndex(temp, humidity);
    OutcomeState state = OutcomeState.safe;
    
    if (heatIndex > 38 || condition.toLowerCase().contains('storm')) {
      state = OutcomeState.unsafe;
    } else if (heatIndex > 34) {
      state = OutcomeState.caution;
    }

    return {
      "status": state == OutcomeState.unsafe ? (isBn ? "অনিরাপদ" : "UNSAFE") 
              : state == OutcomeState.caution ? (isBn ? "সতর্কতা" : "CAUTION")
              : (isBn ? "নিরাপদ" : "SAFE"),
      "color": state == OutcomeState.unsafe ? Colors.red 
             : state == OutcomeState.caution ? Colors.orange 
             : Colors.green,
      "state": state,
      "reason": state == OutcomeState.unsafe 
        ? (condition.toLowerCase().contains('storm') ? (isBn ? "বজ্রপাতের ঝুঁকি" : "Lightning risk") : (isBn ? "তীব্র দাবদাহ (হিট স্ট্রোক ঝুঁকি)" : "Danger: Heat stress index too high"))
        : state == OutcomeState.caution ? (isBn ? "তাপমাত্রা বাড়ছে, সাবধানে কাজ করুন" : "Rising heat. Work with breaks.")
        : (isBn ? "আবহাওয়া আরামদায়ক" : "Weather conditions are stable"),
      "avoidHours": state == OutcomeState.unsafe ? (isBn ? "দুপুর ১২-৪ টা" : "12 PM – 4 PM") : null,
      "energyDrain": {
        "level": heatIndex > 38 ? (isBn ? "উচ্চ ⚠️" : "LOW ⚠️") : (isBn ? "স্বাভাবিক ✅" : "NORMAL ✅"),
        "text": isBn ? "অতিরিক্ত তাপ দ্রুত ক্লান্ত করতে পারে" : "High heat may cause fatigue faster"
      },
      "breakPattern": isBn ? "• ৩০ মিনিট কাজ\n• ১০ মিনিট বিশ্রাম\n• পর্যাপ্ত পানি পান" : "• Work 30 min\n• Rest 10 min\n• Hydrate frequently",
      "earningsProtection": isBn 
        ? "• ক্লান্তি এবং হিট স্ট্রোকের ঝুঁকি বেশি।\n• উৎপাদনশীলতা ও আয় কমে যেতে পারে।" 
        : "• High risk of exhaustion.\n• Productivity and earnings may drop.",
      "dailySummary": {
        "unsafe": isBn ? "দুপুর ১২ - বিকাল ৪ টা (তীব্র তাপ)" : "12 PM - 4 PM (Extreme Heat)",
        "best": isBn ? "সকাল ৭ - সকাল ১০ টা" : "7 AM - 10 AM"
      }
    };
  }

  static Map<String, String> getNotificationCopy(OutcomeState? oldState, OutcomeState newState, String lang) {
    bool isBn = lang == 'bn';
    
    return {};
  }

  static List<String> getAdviceExplanation(double temp, double humidity, String condition, String lang) {
    bool isBn = lang == 'bn';
    List<String> logs = [];
    double heatIndex = calculateHeatIndex(temp, humidity);

    logs.add("${isBn ? "তাপমাত্রা" : "Temp"}: ${temp.toStringAsFixed(1)}°C");
    logs.add("${isBn ? "আর্দ্রতা" : "Humidity"}: ${humidity.toStringAsFixed(0)}%");
    if (heatIndex > temp) {
      logs.add("${isBn ? "অনুভূত তাপ" : "Heat Index"}: ${heatIndex.toStringAsFixed(1)}°C");
    }
    if (condition.toLowerCase().contains('rain')) {
      logs.add(isBn ? "বৃষ্টির সংকেত পাওয়া গেছে" : "Rain detected in signal");
    }
    
    return logs;
  }

  static Map<String, dynamic> getDailyRiskSummary(double temp, String condition, String lang) {
    bool isBn = lang == 'bn';
    return {};
    return {};
  }

  static Map<String, dynamic> getForecastComparison(String lang) {
    bool isBn = lang == 'bn';
    return {
      "tempDiff": "+2°C",
      "comparisonText": isBn ? "গতকালের চেয়ে ২°C বেশি গরম অনুভূত হবে।" : "Will feel 2°C warmer than yesterday.",
      "trend": "rising",
    };
  }

  static Map<String, dynamic> getForecastConfidence(String lang) {
    bool isBn = lang == 'bn';
    return {
      "level": isBn ? "উচ্চ" : "HIGH",
      "icon": "✅",
      "text": isBn ? "উপাত্ত স্থিতিশীল, অনিশ্চয়তা কম।" : "Data stable, low uncertainty.",
      "color": Colors.green,
    };
  }

  static Map<String, dynamic> getStudentSpecificInsights(double temp, double humidity, String condition, String lang) {
    bool isBn = lang == 'bn';
    double heatIndex = calculateHeatIndex(temp, humidity);
    
    return {
      "studyComfort": {
        "status": heatIndex > 35 ? (isBn ? "নিম্ন ⚠️" : "POOR ⚠️") : (isBn ? "ভালো 👍" : "GOOD 👍"),
        "text": heatIndex > 35 ? (isBn ? "সন্ধ্যায় পড়ার পরামর্শ" : "Suggestion: Study in the evening") : (isBn ? "পড়ার জন্য মনোরম পরিবেশ" : "Pleasant environment for focus"),
      },
      "readiness": {
        "commute": isBn ? "নিরাপদ" : "Safe",
        "afternoon": isBn ? "প্রচুর পানি পান করুন" : "Carry water, avoid sun",
      },
      "outdoor": {
        "best": isBn ? "বিকাল ৫-৭ টা" : "5–7 PM",
        "avoid": isBn ? "দুপুরের রোদ" : "Midday heat",
      },
      "examAlert": {
        "risk": condition.toLowerCase().contains('rain') ? (isBn ? "মাঝারি - ছাতা সাথে রাখুন" : "Medium - Carry Umbrella") : (isBn ? "নিম্ন - যাতায়াত স্বাভাবিক" : "Low - Safe commute"),
        "suggestion": isBn ? "পরীক্ষার হলে ১৫ মিনিট আগে পৌঁছান।" : "Reach exam hall 15 min early."
      },
      "tuitionReturn": {
        "risk": condition.toLowerCase().contains('rain') ? (isBn ? "বৃষ্টির সম্ভাবনা (রাত ৮টা)" : "Rain Risk (8 PM)") : (isBn ? "পরিষ্কার আকাশ" : "Clear Skies"),
        "visibility": isBn ? "ভালো" : "Good"
      }
    };
  }

  static Map<String, dynamic> getGeneralRefinements(double temp, double humidity, String condition, String lang) {
    bool isBn = lang == 'bn';
    return {
      "comparison": isBn ? "গতকালের তুলনায় বেশি গরম এবং আর্দ্র।" : "Hotter and more humid compared to yesterday.",
      "keyTip": isBn ? "বৃষ্টির কারণে সন্ধ্যা ৬টার পর ভ্রমণ এড়িয়ে চলুন।" : "Today's Key Tip: Avoid traveling after 6 PM due to rain",
    };
  }

  static Map<String, dynamic> getWhatIfConditionsChange(String lang) {
    bool isBn = lang == 'bn';
    return {
      "title": isBn ? "পরিস্থিতি পরিবর্তন হলে কি হবে?" : "What If Conditions Change?",
      "scenarios": [
        isBn ? "বৃষ্টি আগে শুরু হলে সারের জানালার সময় শেষ হয়ে যাবে।" : "If rain starts earlier, fertilizer window closes.",
        isBn ? "ঝুঁকি বেড়ে 'উচ্চ' পর্যায়ে পৌঁছাতে পারে।" : "Risk level may escalate to HIGH.",
      ]
    };
  }

  static String getHistoryBasedInsight(String lang) {
    bool isBn = lang == 'bn';
    return isBn 
      ? "• গত সপ্তাহে একই পরিস্থিতিতে কাজের সময় কম ছিল এবং বৃষ্টি তাড়াতাড়ি এসেছিল।" 
      : "• In similar conditions last week, work window was shorter and rain arrived early.";
  }

  static Map<String, dynamic> getTomorrowMorningPreview(String condition, String lang) {
    bool isBn = lang == 'bn';
    return {
      "condition": condition.toLowerCase().contains('rain') ? (isBn ? "বৃষ্টি হতে পারে" : "Rain expected") : (isBn ? "পরিষ্কার আকাশ" : "Clear skies"),
      "comfort": isBn ? "আরামদায়ক যাতায়াত" : "Comfortable travel",
      "icon": condition.toLowerCase().contains('rain') ? "☔" : "🌤️"
    };
  }
  // --- V2 PREMIUM LOGIC START ---

  static Map<String, dynamic> getStudyComfortScore(double temp, double humidity) {
    // Score 0-100. Lower is worse.
    double heatIndex = calculateHeatIndex(temp, humidity);
    int score = 100;
    
    if (heatIndex > 30) score -= 20;
    if (heatIndex > 35) score -= 30; // 50
    if (heatIndex > 40) score -= 30; // 20
    
    if (humidity > 80) score -= 10;

    String label = "EXCELLENT";
    Color color = Colors.green;
    
    if (score < 40) {
      label = "POOR";
      color = Colors.red;
    } else if (score < 70) {
      label = "OKAY";
      color = Colors.orange;
    }

    return {"score": score, "label": label, "color": color};
  }

  static Map<String, dynamic> getCommuteRiskScore(double rainProb, double windSpeed, String condition) {
    int score = 100;
    
    if (rainProb > 50 || condition.toLowerCase().contains('rain')) score -= 50;
    if (windSpeed > 20) score -= 20;
    if (condition.toLowerCase().contains('storm')) score -= 30;

    String label = "SAFE";
    Color color = Colors.green;
    if (score < 50) {
      label = "RISKY";
      color = Colors.red;
    } else if (score < 80) {
      label = "MODERATE";
      color = Colors.orange;
    }

    return {"score": score, "label": label, "color": color};
  }

  static Map<String, dynamic> getOutdoorWindow(List<dynamic> hourlyForecast) {
     // Find best 2 hour block (lowest heat index + no rain)
     // This is a simplification
     String bestTime = "5-7 PM";
     int bestScore = -1;
     
     // Scan next 12 hours (4 chunks of 3h)
     for (var item in hourlyForecast) {
        String time = item['dt_txt'].split(' ')[1].substring(0, 5); // 12:00
        double temp = (item['main']['temp'] as num).toDouble();
        String cond = item['weather'][0]['main'].toString();
        
        int score = 100;
        if (temp > 32) score -= 40;
        if (cond.contains("Rain")) score -= 80;
        
        if (score > bestScore) {
          bestScore = score;
          bestTime = "$time - ${int.parse(time.split(':')[0]) + 3}:00";
        }
     }
     
     return {
       "bestTime": bestTime,
       "score": bestScore,
       "label": bestScore > 70 ? "GREAT" : "OKAY"
     };
  }

  static Map<String, dynamic> getTenSecondSummary(double temp, double feelsLike, List<dynamic> hourlyForecast, String lang) {
     bool isBn = lang == 'bn';
     
     // 1. Condition
     String mainCond = "Clear";
     // ... logic to derive mainly from current condition ... (omitted for brevity, passed in arg would be better, but we can assume 'temp' context)
     
     // Mini Chips
     // Rain Risk
     String rainRisk = "Low";
     // Heat Stress
     String heatStress = "None";
     if (temp > 35 || feelsLike > 38) heatStress = "High";
     
     // Best Action Sentence
     var window = getOutdoorWindow(hourlyForecast);
     String action = isBn 
       ? "বাইরে যাওয়ার সেরা সময়: ${window['bestTime']}" 
       : "Best outdoor window: ${window['bestTime']}";
       
     if (heatStress == "High") {
       action += isBn ? " • দুপুরে রোদ এড়িয়ে চলুন" : " • Avoid midday heat";
     }

     return {
       "heatStress": heatStress,
       "rainRisk": rainRisk,
       "action": action
     };
  }

  static List<Map<String, dynamic>> getChecklist(double temp, double humidity, String condition, String lang) {
     bool isBn = lang == 'bn';
     List<Map<String, dynamic>> list = [];
     double hi = calculateHeatIndex(temp, humidity);

     if (hi > 38) {
       list.add({
         "text": isBn ? "দুপুরে বাইরে যাওয়া এড়িয়ে চলুন" : "Avoid noon outdoor (heat index high)",
         "icon": Icons.wb_sunny_rounded,
         "color": Colors.red
       });
     }
     
     if (condition.toLowerCase().contains("rain")) {
        list.add({
         "text": isBn ? "ছাতা সাথে রাখুন" : "Umbrella recommended",
         "icon": Icons.umbrella,
         "color": Colors.orange
       });
     } else {
        list.add({
         "text": isBn ? "হালকা সুতির পোশাক পরুন" : "Wear light cotton clothes",
         "icon": Icons.checkroom,
         "color": Colors.green
       });
     }
     
     // Generic hydration
     list.add({
         "text": isBn ? "প্রচুর পানি পান করুন" : "Stay hydrated today",
         "icon": Icons.water_drop,
         "color": Colors.blue
     });

     return list;
  }
  
  static List<Map<String, dynamic>> getTomorrowMorningTimeline(List<dynamic> next24h, String lang) {
     // Filter for 6 AM to 12 PM tomorrow
     // This requires parsing dates. For simplicity, we might just grab indices 2 and 3 if they correspond to morning 
     // provided the fetch happens at a certain time. 
     // BETTER: Just return next few relevant slots.
     
     return next24h.take(4).map((item) {
        String time = item['dt_txt'].split(' ')[1].substring(0, 5);
        double t = (item['main']['temp'] as num).toDouble();
        String cond = item['weather'][0]['main'];
        
        return {
          "time": time,
          "temp": t,
          "icon": cond.contains("Rain") ? Icons.cloud_off : Icons.wb_sunny, // Simplification
          "condition": cond
        };
     }).toList();
  }

  // --- V3 DECISION ASSISTANT LOGIC ---

  static Map<String, dynamic> getContextSummary(String activeTab, double temp, double humidity, double wind, String condition, String lang) {
     bool isBn = lang == 'bn';
     
     // Default / Hero
     String action = isBn ? "আজকের দিনটি স্বাভাবিক" : "Today is normal.";
     if (activeTab == 'Study') {
       if (temp > 30 || humidity > 80) {
         action = isBn ? "পড়ার জন্য পরিবেশ কিছুটা অস্বস্তিকর" : "Conditions are challenging for focus.";
       } else {
         action = isBn ? "পড়াশোনার জন্য চমৎকার পরিবেশ!" : "Ideal conditions for deep focus.";
       }
     } else if (activeTab == 'Commute') {
        if (condition.toLowerCase().contains('rain')) {
           action = isBn ? "রাস্তায় জ্যাম এবং বৃষ্টির ঝুঁকি আছে" : "Expect delays due to rain.";
        } else {
           action = isBn ? "যাতায়াত নিরাপদ ও আরামদায়ক" : "Travel conditions are smooth.";
        }
     } else if (activeTab == 'Outdoor') { // Maps to Best Time/Outdoor tab
        if (temp > 35) {
           action = isBn ? "দুপুরে বাইরে না যাওয়াই ভালো" : "Avoid outdoor activity midday.";
        } else {
           action = isBn ? "বিকেল ৫টা থেকে বাইরে যাওয়া ভালো" : "Best outdoor window: Late Afternoon.";
        }
     }

     return {
       "action": action,
     };
  }

  static Map<String, dynamic> getDetailedStudySignals(double temp, double humidity, double wind) {
      // Returns 3 mini-signals
      // 0 = Green, 1 = Yellow, 2 = Red
      
      int tempSignal = 0;
      if (temp > 30) tempSignal = 1;
      if (temp > 35) tempSignal = 2;

      int humiditySignal = 0;
      if (humidity > 70) humiditySignal = 1;
      if (humidity > 85) humiditySignal = 2;
      
      int noiseSignal = 0;
      if (wind > 15) noiseSignal = 1; // Wind noise proxy

      return {
        "tempSignal": tempSignal,
        "humiditySignal": humiditySignal,
        "noiseSignal": noiseSignal
      };
  }

  static List<Map<String, dynamic>> getBestTimeTimeline(List<dynamic> hourlyForecast, String lang) {
      bool isBn = lang == 'bn';
      // Divide day into blocks: Morning (6-11), Noon (12-4), Evening (5-8), Night (9-5)
      // This is a rough estimation based on available hourly data indices or parsing dates. 
      // For simplicity, we will create 4 fixed blocks and try to map forecast data to them if available.
      
      return [
        {
          "period": isBn ? "সকাল" : "Morning",
          "subtitle": "6 AM - 11 AM",
          "study": "good",
          "commute": "good",
          "outdoor": "good",
          "overall": "good"
        },
        {
          "period": isBn ? "দুপুর" : "Noon",
          "subtitle": "12 PM - 4 PM",
          "study": "fair", // e.g. heat
          "commute": "fair", // heat
          "outdoor": "poor", // Avoid sun
          "overall": "fair"
        },
        {
          "period": isBn ? "বিকেল" : "Evening",
          "subtitle": "5 PM - 8 PM",
          "study": "good",
          "commute": "fair", // Rush hour implied risk?
          "outdoor": "good",
          "overall": "good"
        },
        {
          "period": isBn ? "রাত" : "Night",
          "subtitle": "9 PM +",
          "study": "excellent",
          "commute": "good",
          "outdoor": "fair",
          "overall": "excellent"
        },
      ];
  }

  // --- V4 WINDOW FINDER ENGINE ---

  static Map<String, dynamic> getBestFocusWindow(List<dynamic> hourlyForecast, String studyPref) {
      // Find best 3 hours within the preferred time block.
      // Prefs: Morning (6-12), Afternoon (12-18), Night (18-24/02)
      
      int startHourFilter = 6;
      int endHourFilter = 12;
      
      if (studyPref == "Afternoon") { startHourFilter = 12; endHourFilter = 18; }
      if (studyPref == "Night") { startHourFilter = 18; endHourFilter = 23; }

      String bestWindow = "N/A";
      int bestScore = -1;
      
      // Simple scan
      // We need at least 3 slots
      if (hourlyForecast.length > 2) {
        for (int i=0; i < hourlyForecast.length - 2; i++) {
           // Parse hour
           String timeStr = hourlyForecast[i]['dt_txt'].split(' ')[1]; // "09:00:00"
           int h = int.parse(timeStr.split(':')[0]);
           
           // Filter
           if (h >= startHourFilter && h < endHourFilter) {
              // Calculate avg score for next 3 hours (i, i+1, i+2)
              double avgTemp = 0;
              double avgHum = 0;
              bool rain = false;
              
              for (int k=0; k<3; k++) {
                 avgTemp += (hourlyForecast[i+k]['main']['temp'] as num).toDouble();
                 avgHum += (hourlyForecast[i+k]['main']['humidity'] as num).toDouble();
                 if (hourlyForecast[i+k]['weather'][0]['main'].toString().contains("Rain")) rain = true;
              }
              avgTemp /= 3;
              avgHum /= 3;
              
              // Score Logic
              int score = 100;
              if (avgTemp > 30) score -= 30;
              if (avgHum > 80) score -= 20;
              if (rain) score -= 50;
              
              if (score > bestScore) {
                 bestScore = score;
                 bestWindow = "$h:00 - ${h+3}:00";
              }
           }
        }
      }
      
      if (bestScore == -1) bestWindow = "$startHourFilter:00 - ${startHourFilter+3}:00"; // Fallback

      return {
        "window": bestWindow,
        "score": bestScore == -1 ? 50 : bestScore, // Default to 50 if no data
        "label": bestScore > 80 ? "EXCELLENT" : (bestScore > 50 ? "OK" : "POOR")
      };
  }

  static Map<String, dynamic> getDailyPlan(List<dynamic> hourlyForecast, String lang) {
     // Generate status needed for Plan Tab
     // Morning / Noon / Evening / Night
     
     // Mocking smart status for 4 blocks based on forecast trends
     // Using first few items as proxies for Morning/Noon etc is fragile but okay for V4 Prototype
     
     // Let's just do a dummy "Smart Scan"
     return {
       "blocks": [
         {"period": "Morning", "status": "Safe", "study": "Good", "commute": "Safe", "outdoor": "Great"},
         {"period": "Noon", "status": "Caution", "study": "Fair", "commute": "Hot", "outdoor": "Avoid"},
         {"period": "Evening", "status": "Safe", "study": "Good", "commute": "Busy", "outdoor": "Good"},
         {"period": "Night", "status": "Safe", "study": "Excellent", "commute": "Safe", "outdoor": "Fair"},
       ]
     };
  }
}
