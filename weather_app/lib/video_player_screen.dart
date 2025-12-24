import 'package:flutter/material.dart';
import 'services/news_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final NewsItem news;
  final bool isBn;

  const VideoPlayerScreen({super.key, required this.news, required this.isBn});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool isPlaying = true;
  double progress = 0.3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Video Background
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Image.network(
                    widget.news.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(color: Colors.black.withOpacity(0.3)),
                  if (!isPlaying)
                    const Center(
                      child: Icon(Icons.play_arrow, color: Colors.white, size: 80),
                    ),
                ],
              ),
            ),
          ),
          
          // Header
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    isBn ? widget.news.bnTitle : widget.news.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        "0:45",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Expanded(
                        child: Slider(
                          value: progress,
                          activeColor: Colors.teal,
                          inactiveColor: Colors.white24,
                          onChanged: (val) => setState(() => progress = val),
                        ),
                      ),
                      const Text(
                        "2:30",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white, size: 30),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () => setState(() => isPlaying = !isPlaying),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                        child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white, size: 30),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get isBn => widget.isBn;
}
