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

  static String getDailyAdvice(String condition, double temp, double humidity, UserMode mode, String lang, {double rainProb = 0, double windSpeed = 0, String city = ""}) {
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

    // Specialized Mode Intelligence (Outcome Profiles)
    if (mode == UserMode.farmer) {
      if (condition.toLowerCase().contains('rain')) {
        advices.add(lang == 'bn' ? "ধানের চারা রোপনের আদর্শ সময় আজ।" : "Ideal day for transplantation. Avoid harvest.");
        advices.add(lang == 'bn' ? "বৃষ্টির কারণে আজ কীটনাশক প্রয়োগ করবেন না (লোকসান রোধ করুন)।" : "STOP: DO NOT spray pesticide today (Prevents chemical loss).");
      } else if (temp > 35) {
        advices.add(lang == 'bn' ? "মাটিতে সেচ বজায় রাখুন - ফসলের তাপ চাপ কমান।" : "Action: Irrigate soil now to reduce crop heat stress.");
      } else if (windSpeed > 25) {
        advices.add(lang == 'bn' ? "ঝড়ো বাতাস: উঁচুতে কাজ করা এবং বড় গাছের নিচে অবস্থান এড়িয়ে চলুন।" : "Warning: High wind. Avoid tall structure work.");
      } else {
        advices.add(lang == 'bn' ? "আজ সার প্রয়োগ এবং সাধারণ খামার কাজের জন্য উপযুক্ত সময়।" : "Decision: Perfect window for fertilizer application.");
      }
    }

    if (mode == UserMode.worker) {
      if (heatIndex > 38) {
        advices.add(lang == 'bn' ? "বিপজ্জনক তাপ সূচক! দুপুর ১২-৪ টা পর্যন্ত বাইরে কাজ এড়িয়ে চলুন।" : "SAFETY: UNSTABLE hours (12–4 PM). Avoid outdoor work.");
      }
      if (condition.toLowerCase().contains('storm')) {
        advices.add(lang == 'bn' ? "বজ্রপাতের উচ্চ ঝুঁকি - খোলা মাঠ বা ক্রেন থেকে দূরে থাকুন।" : "ALERT: High lightning risk. Vacate open construction sites.");
      }
      if (condition.toLowerCase().contains('rain') && (city == 'Dhaka' || city == 'Chittagong')) {
        advices.add(lang == 'bn' ? "রাস্তার জলাবদ্ধতার কারণে কাজের পরিকল্পনা পরিবর্তন করুন।" : "Commute Intelligence: Expect severe delays due to flooding.");
      }
    }

    if (mode == UserMode.student) {
      if (temp > 35) {
        advices.add(lang == 'bn' ? "অ্যাসেম্বলি বা পিটি ক্লাস ইনডোর করার অনুরোধ করুন।" : "School Safety: Request indoor assembly due to heat.");
      }
      if (condition.toLowerCase().contains('rain')) {
        advices.add(lang == 'bn' ? "স্কুলে যাতায়াতের সময় বই ও খাতা রেইনকোটের নিচে রাখুন।" : "Kit Protection: Keep books/devices sealed during commute.");
      }
      if (hour >= 7 && hour <= 9 && condition.toLowerCase().contains('fog')) {
        advices.add(lang == 'bn' ? "ঘন কুয়াশার কারণে স্কুলে যাতায়াতে সতর্কতা অবলম্বন করুন।" : "Travel Alert: Dense fog during morning school run.");
      }
    }

    // Prayer Time Related (Mock/Time-based)
    if (hour >= 17 && hour <= 19 && condition.toLowerCase().contains('rain')) {
       advices.add(lang == 'bn' ? "মাগরিবের নামাজের সময় বৃষ্টির সম্ভাবনা রয়েছে।" : "Rain expected around Maghrib prayer time.");
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

  static Map<String, dynamic> getDecisionInsights(String condition, double temp, double humidity, UserMode mode, String lang) {
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

  static Map<String, String> getNotificationCopy(OutcomeState? oldState, OutcomeState newState, UserMode mode, String lang) {
    bool isBn = lang == 'bn';
    
    if (mode == UserMode.worker) {
      if (newState == OutcomeState.unsafe) {
        return {
          "title": isBn ? "⚠️ অনিরাপদ: বিরতি নিন" : "⚠️ UNSAFE: Take a break",
          "body": isBn ? "অবস্থা: বিপজ্জনক তাপ।\nকরণীয়: কাজ বন্ধ করে ছায়ায় বিশ্রাম নিন।\nউইন্ডো: দুপুর ১২-৪ টা।" : "Status: Dangerous Heat.\nAction: Stop work and rest in shade.\nWindow: 12 PM - 4 PM."
        };
      }
      if (oldState == OutcomeState.unsafe && newState == OutcomeState.safe) {
        return {
          "title": isBn ? "✅ কাজ শুরু করুন" : "✅ SAFE: Resume Work",
          "body": isBn ? "অবস্থা: তাপমাত্রা বা বজ্রঝড় কমেছে।\nকরণীয়: স্বাভাবিক কাজ শুরু করতে পারেন।\nউইন্ডো: এখন থেকে সন্ধ্যা পর্যন্ত।" : "Status: Risks reduced.\nAction: Resume outdoor work.\nWindow: Safe until evening."
        };
      }
      if (newState == OutcomeState.caution) {
         return {
          "title": isBn ? "⚠️ সতর্কতা: তাপমাত্রা বাড়ছে" : "⚠️ CAUTION: Heat Rising",
          "body": isBn ? "অবস্থা: মাঝারি ঝুঁকি।\nকরণীয়: কাজের মাঝে অতিরিক্ত বিরতি নিন।\nউইন্ডো: পরবর্তী ৩ ঘণ্টা।" : "Status: Moderate Risk.\nAction: Take extra breaks.\nWindow: Next 3 hours."
        };
      }
    }

    if (mode == UserMode.farmer) {
      if (newState == OutcomeState.unsafe) {
        return {
          "title": isBn ? "⚠️ অ্যালার্ট: উচ্চ ফসল ঝুঁকি" : "⚠️ ALERT: High Crop Risk",
          "body": isBn ? "অবস্থা: ভারী বৃষ্টি/ঝড়।\nকরণীয়: ফসল ও সার প্রয়োগ বন্ধ রাখুন।\nউইন্ডো: পরবর্তী ২৪ ঘণ্টা।" : "Status: Heavy rain/storm.\nAction: Stop fertilizer application.\nWindow: Next 24 hours."
        };
      }
      if (oldState == OutcomeState.unsafe && newState == OutcomeState.safe) {
        return {
          "title": isBn ? "✅ নিরাপদ: সার প্রয়োগের সময়" : "✅ SAFE: Work Window Open",
          "body": isBn ? "অবস্থা: আকাশ পরিষ্কার।\nকরণীয়: দ্রুত সার বা কিটনাশক প্রয়োগ শেষ করুন।\nউইন্ডো: আগামী ৩ ঘণ্টা।" : "Status: Clear skies.\nAction: Apply fertilizer/pesticide now.\nWindow: Next 3 hours."
        };
      }
    }

    if (mode == UserMode.student) {
      if (newState == OutcomeState.unsafe) {
        return {
          "title": isBn ? "⚠️ স্কুল যাতায়াত সতর্কতা" : "⚠️ SCHOOL: Commute Risk",
          "body": isBn ? "অবস্থা: প্রতিকূল আবহাওয়া।\nকরণীয়: বিদ্যালয়ে যাতায়াতে অতিরিক্ত সতর্ক থাকুন।\nউইন্ডো: সকালের যাতায়াত সময়।" : "Status: Adverse weather.\nAction: Exercise extreme caution.\nWindow: Morning school run."
        };
      }
      if (oldState == OutcomeState.unsafe && newState == OutcomeState.safe) {
        return {
          "title": isBn ? "✅ যাতায়াত এখন নিরাপদ" : "✅ SCHOOL: Safe Commute",
          "body": isBn ? "অবস্থা: পরিস্থিতি স্বাভাবিক।\nকরণীয়: সময়মত বিদ্যালয়ে রওনা হন।\nউইন্ডো: এখন থেকে বিকাল পর্যন্ত।" : "Status: Conditions normalizing.\nAction: Safe to head to school.\nWindow: Safe until afternoon."
        };
      }
    }

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

  static Map<String, dynamic> getDailyRiskSummary(UserMode mode, double temp, String condition, String lang) {
    bool isBn = lang == 'bn';
    if (mode == UserMode.farmer) {
      return {
        "title": isBn ? "আজকের কৃষি ঝুঁকি" : "Today's Farm Risk",
        "risks": [
          {"label": isBn ? "পাহাড়ধস/প্লাবন" : "Flood/Landslide", "level": condition.contains('Rain') ? "High" : "Low", "color": condition.contains('Rain') ? Colors.red : Colors.green},
          {"label": isBn ? "তীব্র দাবদাহ" : "Heat Stress", "level": temp > 35 ? "Medium" : "Low", "color": temp > 35 ? Colors.orange : Colors.green},
          {"label": isBn ? "বজ্রপাত" : "Lightning", "level": condition.contains('Storm') ? "High" : "Low", "color": condition.contains('Storm') ? Colors.red : Colors.green},
        ]
      };
    }
    if (mode == UserMode.worker) {
      return {
        "title": isBn ? "আজকের কাজের ঝুঁকি" : "Daily Work Risk",
        "risks": [
          {"label": isBn ? "তাপমাত্রা (HI)" : "Heat Index", "level": temp > 34 ? "High" : "Low", "color": temp > 34 ? Colors.red : Colors.green},
          {"label": isBn ? "বজ্রপাত ঝুঁকি" : "Lightning Risk", "level": condition.contains('Storm') ? "High" : "Low", "color": condition.contains('Storm') ? Colors.red : Colors.green},
          {"label": isBn ? "জলাবদ্ধতা" : "Flooding", "level": condition.contains('Rain') ? "Medium" : "Low", "color": condition.contains('Rain') ? Colors.orange : Colors.green},
        ]
      };
    }
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
}
