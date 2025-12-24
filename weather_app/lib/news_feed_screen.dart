import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/news_service.dart';
import 'services/profile_service.dart';
import 'services/settings_service.dart';
import 'news_detail_screen.dart';
import 'video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'utils/weather_theme.dart';
import 'news_webview_screen.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  String selectedCategory = 'All';

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch original article.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final newsService = Provider.of<NewsService>(context); // Keep newsService
    final profileService = Provider.of<ProfileService>(context); // Added profileService
    final userDistrict = profileService.location.split(',').first.trim();
    final isBn = settings.language == 'bn'; // Keep isBn

    // Smart Ranking: Emergency cards first, then local
    final displayNews = newsService.getNews(selectedCategory, userDistrict: userDistrict);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: newsService.isLoading && newsService.allItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => newsService.refreshNews(district: userDistrict),
              child: CustomScrollView(
                slivers: [
                  _buildStickyHeader(isBn, userDistrict, newsService),
                  SliverToBoxAdapter(child: _buildCategoryFilter(isBn)),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: newsService.allItems.isEmpty && !newsService.isLoading
                        ? const SliverFillRemaining(child: Center(child: Text("No news available for your region.")))
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final news = displayNews[index];
                                return _buildInsightfulCard(news, isBn, settings.lowDataMode, userDistrict);
                              },
                              childCount: displayNews.length,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStickyHeader(bool isBn, String district, NewsService service) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        isBn ? "আবহাওয়া সংবাদ — বাংলাদেশ" : "Weather News — Bangladesh",
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.teal),
          onPressed: () => service.refreshNews(district: district),
        )
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            isBn ? "আপনার অবস্থান: $district" : "Based on your location: $district",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isBn) {
    final categories = ['All', 'cyclone', 'flood', 'heatwave', 'monsoon'];
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat;
          String label = cat;
          if (isBn) {
            if (cat == 'All') label = "সব";
            if (cat == 'cyclone') label = "ঘূর্ণিঝড়";
            if (cat == 'flood') label = "বন্যা";
            if (cat == 'heatwave') label = "তাপপ্রবাহ";
            if (cat == 'monsoon') label = "বর্ষা";
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => selectedCategory = cat);
              },
              selectedColor: Colors.teal,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightfulCard(NewsItem news, bool isBn, bool lowData, String userDistrict) {
    final isEmergency = news.type == 'warning';
    final hasInsight = news.insight != null;
    final isLocal = news.district == userDistrict;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isEmergency ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: WeatherTheme.getGlassyDecoration(opacity: 0.9).copyWith(
               border: Border.all(
                 color: isEmergency ? Colors.red.shade100 : Colors.white.withOpacity(0.2),
                 width: 1,
               ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(news, isBn, isEmergency, isLocal),
                if (!lowData) _buildCardMedia(news, isBn),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainContent(news, isBn),
                      if (news.trends != null) _buildTrends(news.trends!, isBn),
                      if (hasInsight) _buildInsightLayer(news.insight!, isBn, isLocal),
                      const SizedBox(height: 16),
                      _buildFooter(news, isBn),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(NewsItem news, bool isBn, bool isEmergency, bool isLocal) {
    final isOfficial = news.sourceCategory == 'Official';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isEmergency ? Colors.red.shade50 : Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewsWebviewScreen(url: news.url, title: news.source),
                ),
              );
            },
            child: Row(
              children: [
                Icon(
                  isEmergency ? Icons.warning_amber_rounded : (isOfficial ? Icons.verified_user : Icons.verified),
                  size: 16,
                  color: isEmergency ? Colors.red.shade700 : (isOfficial ? Colors.blue.shade700 : Colors.teal.shade700),
                ),
                const SizedBox(width: 8),
                Text(
                  isEmergency
                    ? (isBn ? "জরুরি সতর্কতা" : "EMERGENCY ALERT")
                    : (isBn ? (isOfficial ? "সরকারি তথ্য" : "ভেরিফাইড নিউজ") : news.sourceCategory.toUpperCase()),
                  style: TextStyle(
                    color: isEmergency ? Colors.red.shade700 : (isOfficial ? Colors.blue.shade700 : Colors.teal.shade700),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (isLocal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isBn ? "আপনার এলাকা" : "Your Area",
                style: TextStyle(color: Colors.teal.shade900, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardMedia(NewsItem news, bool isBn) {
    return GestureDetector(
      onTap: () {
        if (news.type == 'video') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VideoPlayerScreen(news: news, isBn: isBn)),
          );
        }
      },
      child: Stack(
        children: [
          Image.network(
            news.imageUrl,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          if (news.type == 'video')
            const Positioned.fill(
              child: Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(NewsItem news, bool isBn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isBn ? news.bnTitle : news.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
        ),
        const SizedBox(height: 8),
        Text(
          isBn ? news.bnSummary : news.summary,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildTrends(Map<String, String> trends, bool isBn) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        spacing: 12,
        children: trends.entries.map((e) {
          final isRising = e.value.contains('Rising') || e.value.contains('Higher');
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRising ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isRising ? Colors.orange.shade700 : Colors.blue.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                "${e.key.toUpperCase()}: ${e.value}",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightLayer(InsightLayer insight, bool isBn, bool isLocal) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBn ? "প্রাসঙ্গিক বিশ্লেষণ" : "Insight Analysis",
                style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              _buildConfidenceIndicator(insight.confidence, isBn),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightSection(isBn ? "কেন এটি গুরুত্বপূর্ণ:" : "Why this matters:", isBn ? insight.bnWhy : insight.why, Icons.psychology_outlined),
          const SizedBox(height: 10),
          _buildInsightSection(isBn ? "কারা আক্রান্ত হতে পারে:" : "Who is affected:", isBn ? insight.bnWho : insight.who, Icons.groups_outlined),
          const SizedBox(height: 10),
          _buildInsightSection(isBn ? "আপনার করণীয়:" : "What you should do:", isBn ? insight.bnAction : insight.action, Icons.task_alt, isAction: true),

          if (isLocal) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBn ? "আপনার এলাকার জন্য বিশেষ অর্থ: যাতায়াত বিঘ্নিত হতে পারে।" : "What this means for you: Expect transit delays in your area.",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightSection(String label, String content, IconData icon, {bool isAction = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isAction ? Colors.green.shade700 : Colors.teal.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(content, style: const TextStyle(fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceIndicator(String level, bool isBn) {
    Color color = Colors.green;
    if (level == 'Medium') color = Colors.orange;
    if (level == 'Low') color = Colors.red;

    return Row(
      children: [
        Text(
          isBn ? "নির্ভরযোগ্যতা: " : "Confidence: ",
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        Text(
          level,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildFooter(NewsItem news, bool isBn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _launchUrl(news.url),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(news.source, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 10, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(news.time, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
             TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news, isBn: isBn)),
                );
              },
              child: Text(isBn ? "আইনসক্রিন" : "Insights", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewsWebviewScreen(url: news.url, title: news.source),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(isBn ? "মূল সংবাদ" : "Full News", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
