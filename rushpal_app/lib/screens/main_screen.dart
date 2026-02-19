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
    const HomeScreen(), // index 0
    const MarketScreen(), // index 1
    const StatsScreen(), // index 2
    const FriendScreen(), // index 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ตั้งค่านี้เพื่อให้เนื้อหา (สีแดงของ Home) ยืดไปอยู่หลังแถบเมนู
      extendBody: true,
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
            color: Colors.black.withOpacity(
              0.1,
            ), // ปรับเงาให้ชัดขึ้น
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_rounded, 0),
          _buildNavItem(Icons.shopping_bag_outlined, 1),
          _buildNavItem(Icons.bar_chart_rounded, 2),
          _buildNavItem(Icons.groups_outlined, 3),
        ],
      ),
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
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? AppTheme.primaryRed : Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}
