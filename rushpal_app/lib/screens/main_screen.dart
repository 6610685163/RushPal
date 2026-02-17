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

  // ✅ แก้ไขตรงนี้: ลบ Scaffold() ว่างๆ ออก ให้เหลือแค่ 4 หน้าตามปุ่ม
  final List<Widget> _pages = [
    const HomeScreen(), // index 0
    const MarketScreen(), // index 1
    const StatsScreen(), // index 2 (จะตรงกับปุ่ม bar_chart)
    const FriendScreen(), // index 3 (จะตรงกับปุ่ม group)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 30),
        child: _buildCustomBottomBar(),
      ),
    );
  }

  Widget _buildCustomBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_rounded, 0),
          _buildNavItem(Icons.storefront_rounded, 1),
          _buildNavItem(
            Icons.bar_chart_rounded,
            2,
          ), // ปุ่มนี้จะเปิด StatsScreen แล้ว
          _buildNavItem(
            Icons.group_rounded,
            3,
          ), // ปุ่มนี้จะเปิด FriendScreen แล้ว
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: isActive
            ? BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(
          icon,
          size: 26,
          color: isActive ? AppTheme.primaryRed : Colors.grey[400],
        ),
      ),
    );
  }
}
