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
      backgroundColor: AppTheme.backgroundCream,
      body: _pages[_selectedIndex],
      bottomNavigationBar: SafeArea(child: _buildCapybaraNavbar()),
    );
  }

  // วาด Navbar สไตล์ Capybara Go
  Widget _buildCapybaraNavbar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(40),
        // 1. เส้นขอบหนาสีน้ำตาลเข้มสไตล์การ์ตูน
        border: Border.all(color: AppTheme.pureBlack, width: 3),
        // 2. เงาทึบ (Hard Shadow) ไม่มีความเบลอ
        boxShadow: [
          BoxShadow(
            color: AppTheme.pureBlack.withOpacity(0.15),
            blurRadius: 0, // ปรับเป็น 0 เพื่อให้เงาคมชัดแบบเกม 2D
            offset: const Offset(0, 6), // ดันเงาลงมาด้านล่าง
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, 0, 'Home'),
          _buildNavItem(Icons.storefront_rounded, 1, 'Shop'),
          _buildNavItem(Icons.bar_chart_rounded, 2, 'Stats'),
          _buildNavItem(Icons.groups_rounded, 3, 'Party'),
        ],
      ),
    );
  }

  // วาดปุ่มด้านใน Navbar
  Widget _buildNavItem(IconData icon, int index, String label) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack, // ให้มีจังหวะเด้งดึ๋งเล็กน้อย
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          // ถ้าถูกเลือก ให้พื้นหลังเป็นสีเหลือง
          color: isSelected ? AppTheme.primaryPink : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          // ถ้าถูกเลือก ให้มีเส้นขอบและเงาของตัวเองเด้งขึ้นมา
          border: isSelected
              ? Border.all(color: AppTheme.pureBlack, width: 2.5)
              : Border.all(color: Colors.transparent, width: 2.5),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: AppTheme.pureBlack,
                    blurRadius: 0,
                    offset: Offset(0, 3), // เงาของปุ่มที่ถูกกด
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              // สีไอคอนเข้มขึ้นเมื่อถูกเลือก
              color: isSelected
                  ? AppTheme.pureBlack
                  : AppTheme.textLight.withOpacity(0.5),
              size: 28,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.pureBlack,
                  fontWeight:
                      FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
