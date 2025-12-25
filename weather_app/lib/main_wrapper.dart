import 'package:flutter/material.dart';
import 'weather_screen.dart';
import 'screens/forecast_7day_screen.dart';
import 'alerts_screen.dart';
import 'news_feed_screen.dart';
import 'settings_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const WeatherScreen(),
    const Forecast7DayScreen(),
    const AlertsScreen(),
    const NewsFeedScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.teal.shade800,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          elevation: 0,
          items: [
            _buildNavItem(Icons.home_outlined, Icons.home, "Home", 0),
            _buildNavItem(Icons.wb_sunny_outlined, Icons.wb_sunny, "Forecast", 1),
            _buildNavItem(Icons.warning_amber_outlined, Icons.warning, "Alerts", 2),
            _buildNavItem(Icons.newspaper_outlined, Icons.newspaper, "News", 3),
            _buildNavItem(Icons.settings_outlined, Icons.settings, "Settings", 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: _AnimatedNavIcon(icon: icon, isSelected: isSelected),
      activeIcon: _AnimatedNavIcon(icon: activeIcon, isSelected: isSelected),
      label: label,
    );
  }
}

class _AnimatedNavIcon extends StatefulWidget {
  final IconData icon;
  final bool isSelected;

  const _AnimatedNavIcon({required this.icon, required this.isSelected});

  @override
  State<_AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<_AnimatedNavIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(widget.icon),
    );
  }
}
