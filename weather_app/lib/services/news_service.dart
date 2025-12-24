import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InsightLayer {
  final String why;
  final String bnWhy;
  final String who;
  final String bnWho;
  final String action;
  final String bnAction;
  final String confidence; // 'High', 'Medium', 'Low'
  final double riskLevel; // 0.0 to 1.0

  InsightLayer({
    required this.why,
    required this.bnWhy,
    required this.who,
    required this.bnWho,
    required this.action,
    required this.bnAction,
    this.confidence = 'High',
    this.riskLevel = 0.5,
  });
}

class NewsItem {
  final String title;
  final String bnTitle;
  final String summary;
  final String bnSummary;
  final String source;
  final String sourceCategory; // 'Official', 'Verified Media'
  final String time;
  final String type; // 'news', 'video', 'warning'
  final String category; // 'cyclone', 'flood', 'heatwave', 'general'
  final String imageUrl;
  final String url; // Original article link
  final InsightLayer? insight;
  final Map<String, String>? trends; // e.g., {'temp': 'Rising', 'rain': 'Higher than normal'}
  final String district; // For personalization

  NewsItem({
    required this.title,
    required this.bnTitle,
    required this.summary,
    required this.bnSummary,
    required this.source,
    this.sourceCategory = 'Official',
    required this.time,
    required this.type,
    required this.category,
    required this.imageUrl,
    required this.url,
    this.insight,
    this.trends,
    this.district = 'All',
  });
}

class NewsService extends ChangeNotifier {
  List<NewsItem> _allItems = [];
  bool _isLoading = false;

  List<NewsItem> get allItems => _allItems;
  bool get isLoading => _isLoading;

  final String _baseUrl = "http://localhost:8000/api/v1";

  NewsService() {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_news_data');
    if (cached != null) {
      _parseAndSetNews(json.decode(cached));
    }
    refreshNews();
  }

  void _parseAndSetNews(Map<String, dynamic> data) {
    if (data['items'] == null) return;
    final List items = data['items'];
    _allItems = items.map((item) {
      final news = item.containsKey('news') ? item['news'] : {};
      final insight = item.containsKey('insight') ? item['insight'] : {};
      
      return NewsItem(
        title: news['headline'] ?? "Weather Update",
        bnTitle: news['bn_headline'] ?? "আবহাওয়া সংবাদ",
        summary: insight['why_it_matters'] ?? "Stay updated with recent changes.",
        bnSummary: insight['bn_why_it_matters'] ?? "বর্তমান পরিবর্তনের সাথে আপডেট থাকুন।",
        source: news['source'] ?? "BMD",
        sourceCategory: 'Verified Media',
        time: "Just Now",
        type: news['type'] ?? "news",
        category: news['category'] ?? "general",
        imageUrl: "https://images.unsplash.com/photo-1547683905-f686c993aae5?q=80&w=800&auto=format&fit=crop",
        url: news['url'] ?? "https://www.bmd.gov.bd",
        district: news['district'] ?? "All",
        insight: InsightLayer(
           why: insight['why_it_matters'] ?? "Safety awareness.",
           bnWhy: insight['bn_why_it_matters'] ?? "সতর্কতা বৃদ্ধি।",
           who: insight['who_is_affected'] ?? "Residents",
           bnWho: insight['bn_who_is_affected'] ?? "বাসিন্দারা",
           action: (insight['what_to_do'] as List?)?.join(". ") ?? "Stay alert.",
           bnAction: (insight['bn_what_to_do'] as List?)?.join(". ") ?? "সতর্ক থাকুন।",
           confidence: insight['confidence'] ?? "High"
        )
      );
    }).toList();
    notifyListeners();
  }

  Future<void> refreshNews({String district = "Dhaka"}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse("$_baseUrl/news-insights?district=$district")).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _parseAndSetNews(data);
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cached_news_data', response.body);
      } else {
        _setFallbackData();
      }
    } catch (e) {
      print("Error fetching news: $e");
      if (_allItems.isEmpty) {
        _setFallbackData();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void _setFallbackData() {
    // Robust fallback to ensure the user always sees something
    _allItems = [
      NewsItem(
        title: "Cyclone Remal Warning Signal 4 Issued",
        bnTitle: "ঘূর্ণিঝড় রেমাল: ৪ নম্বর হুঁশিয়ারি সংকেত",
        summary: "Maritime ports asked to hoist local cautionary signal no. 4.",
        bnSummary: "সমুদ্রবন্দরগুলোকে ৪ নম্বর স্থানীয় হুঁশিয়ারি সংকেত দেখাতে বলা হয়েছে।",
        source: "BMD Official",
        time: "10 mins ago",
        type: "warning",
        category: "cyclone",
        imageUrl: "https://images.unsplash.com/photo-1579766946654-20d440c4a85c?q=80&w=800&auto=format&fit=crop", // Stormy
        url: "https://www.bmd.gov.bd",
        district: "Coastal",
        insight: InsightLayer(
          why: "Approaching severe cyclonic storm.",
          bnWhy: "প্রবল ঘূর্ণিঝড় ধেয়ে আসছে।",
          who: "Coastal residents and fishermen.",
          bnWho: "উপকূলীয় বাসিন্দা এবং জেলেরা।",
          action: "Move to shelter if requested. Secure loose items.",
          bnAction: "নির্দেশনা পেলে আশ্রয়কেন্দ্রে যান।",
          confidence: "High",
          riskLevel: 0.9,
        )
      ),
      NewsItem(
        title: "Dhaka Heatwave: Feels Like 42°C",
        bnTitle: "ঢাকায় প্রচণ্ড তাপদাহ: অনুভূত হচ্ছে ৪২°C",
        summary: "Urban Heat Island effect intensifying misery in the capital.",
        bnSummary: "রাজধানীতে আরবান হিট আইল্যান্ড এফেক্ট জনজীবন বিপর্যস্ত করছে।",
        source: "Weather BD Analysis",
        time: "1 hour ago",
        type: "news",
        category: "heatwave",
        imageUrl: "https://images.unsplash.com/photo-1504370805625-d32c54b16100?q=80&w=800&auto=format&fit=crop", // Sun/Heat
        url: "https://www.bmd.gov.bd",
        district: "Dhaka",
        trends: {'Temp': 'Rising', 'Humidity': 'High'},
        insight: InsightLayer(
          why: "Concrete structures trapping heat.",
          bnWhy: "কংক্রিটের স্থাপনা তাপ আটকে রাখছে।",
          who: "Pedestrians and rickshaw pullers.",
          bnWho: "পথচারী এবং রিকশাচালকরা।",
          action: "Avoid outdoors between 12-3 PM.",
          bnAction: "দুপুর ১২টা থেকে ৩টা পর্যন্ত বাইরে থাকা এড়িয়ে চলুন।",
          confidence: "High",
          riskLevel: 0.7,
        )
      ),
       NewsItem(
        title: "Flash Flood Risk in Sylhet Region",
        bnTitle: "সিলেট অঞ্চলে আকস্মিক বন্যার ঝুঁকি",
        summary: "Heavy upstream rainfall may cause Surma river to overflow.",
        bnSummary: "উজানের ভারী বৃষ্টিপাতে সুরমা নদীর পানি বিপদসীমা অতিক্রম করতে পারে।",
        source: "FFWC",
        time: "2 hours ago",
        type: "news",
        category: "flood",
        imageUrl: "https://images.unsplash.com/photo-1456291937962-42173f448c94?q=80&w=800&auto=format&fit=crop", // Flood/River
        url: "https://www.ffwc.gov.bd",
        district: "Sylhet",
        insight: InsightLayer(
          why: "Heavy rainfall in Cherrapunji.",
          bnWhy: "চেরাপুঞ্জিতে ভারী বৃষ্টিপাত।",
          who: "Low-lying area residents.",
          bnWho: "নিচু এলাকার বাসিন্দারা।",
          action: "Prepare emergency dry food stocks.",
          bnAction: "শুকনা খাবার মজুদ রাখুন।",
          confidence: "Medium",
          riskLevel: 0.6,
        )
      ),
      NewsItem(
        title: "Monsoon Preparedness Tips",
        bnTitle: "বর্ষাকালের প্রস্তুতি ও সতর্কতা",
        summary: "General guidelines for the upcoming monsoon season.",
        bnSummary: "আসন্ন বর্ষাকালের জন্য সাধারণ নির্দেশিকা।",
        source: "Health Ministry",
        time: "1 day ago",
        type: "video",
        category: "monsoon",
        imageUrl: "https://images.unsplash.com/photo-1519692933481-e162a57d6721?q=80&w=800&auto=format&fit=crop", // Rain
        url: "https://dghs.gov.bd",
        district: "All",
        insight: InsightLayer(
          why: "Seasonal disease prevention.",
          bnWhy: "মৌসুমি রোগ প্রতিরোধ।",
          who: "General public",
          bnWho: "সর্বসাধারণ",
          action: "Clean stagnant water around home.",
          bnAction: "বাড়ির আশেপাশে জমে থাকা পানি পরিষ্কার করুন।",
          confidence: "High",
          riskLevel: 0.3,
        )
      )
    ];
    notifyListeners();
  }

  List<NewsItem> getNews(String category, {String? userDistrict}) {
    List<NewsItem> filtered = _allItems;
    
    if (category != 'All') {
      filtered = filtered.where((item) => item.category == category).toList();
    }

    // Sort by emergency first, then relevance to district
    filtered.sort((a, b) {
      if (a.type == 'warning' && b.type != 'warning') return -1;
      if (a.type != 'warning' && b.type == 'warning') return 1;
      
      if (userDistrict != null) {
        if (a.district == userDistrict && b.district != userDistrict) return -1;
        if (a.district != userDistrict && b.district == userDistrict) return 1;
      }
      return 0;
    });

    return filtered;
  }
}
