import 'package:flutter/material.dart';
import 'package:rushpal/screens/home_screen.dart';
import 'package:rushpal/screens/market_screen.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/screens/stats_screen.dart';
import 'package:rushpal/screens/friend_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const MarketScreen(),
    const StatsScreen(),
    const FriendScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.pureBlack,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 45),
        child: _buildCustomBottomBar(),
      ),
    );
  }

  Widget _buildCustomBottomBar() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        _buildNavItem(Icons.directions_run_rounded, 0),
        _buildNavItem(Icons.shopping_bag_rounded, 1),
        _buildNavItem(Icons.bar_chart_rounded, 2),
        _buildNavItem(Icons.groups_rounded, 3),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 65,
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.primaryPink.withOpacity(0.85),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPink.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              )
            : BoxDecoration(
                color: AppTheme.darkBlue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white24, width: 1),
              ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white54,
          size: 32,
        ),
      ),
    );
  }
}
