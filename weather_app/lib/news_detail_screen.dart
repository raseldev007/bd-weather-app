import 'package:flutter/material.dart';
import 'services/news_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'news_webview_screen.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsItem news;
  final bool isBn;

  const NewsDetailScreen({super.key, required this.news, required this.isBn});

  Future<void> _launchUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch original article.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOfficial = news.sourceCategory == 'Official';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(isBn ? "আইনসক্রিন ও সংবাদ" : "Insights & News"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  news.imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: InkWell(
                    onTap: () => _launchUrl(news.url, context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOfficial ? Colors.blue.shade900.withOpacity(0.8) : Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(isOfficial ? Icons.verified_user : Icons.verified, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            news.source,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(news.time, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const Spacer(),
                      if (news.type == 'warning')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            isBn ? "জরুরি" : "EMERGENCY",
                            style: TextStyle(color: Colors.red.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isBn ? news.bnTitle : news.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isBn ? news.bnSummary : news.summary,
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  if (news.insight != null) _buildInsightCard(news.insight!),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          isBn ? "বিস্তারিত সংবাদের জন্য মূল উৎসটি দেখুন" : "View original source for full details",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewsWebviewScreen(
                                  url: news.url,
                                  title: news.source,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: Text(
                            isBn ? "মূল সংবাদ পড়ুন (${news.source})" : "Read Full News (${news.source})",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(InsightLayer insight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.teal),
              const SizedBox(width: 12),
              Text(
                isBn ? "বিশেষ বিশ্লেষণ (আইনসক্রিন)" : "Specialized Insight",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightSection(isBn ? "কেন এটি গুরুত্বপূর্ণ" : "Why it matters", isBn ? insight.bnWhy : insight.why),
          const SizedBox(height: 16),
          _buildInsightSection(isBn ? "কারা আক্রান্ত হতে পারে" : "Who is affected", isBn ? insight.bnWho : insight.who),
          const SizedBox(height: 16),
          _buildInsightSection(isBn ? "আপনার করণীয়" : "What to do", isBn ? insight.bnAction : insight.action, isLast: true),
        ],
      ),
    );
  }

  Widget _buildInsightSection(String title, String content, {bool isLast = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
        if (!isLast) const SizedBox(height: 8),
      ],
    );
  }
}
