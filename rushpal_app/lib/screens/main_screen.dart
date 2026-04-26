import 'package:flutter/material.dart';
import 'package:rushpal/screens/home_screen.dart';
import 'package:rushpal/screens/market_screen.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/screens/stats_screen.dart';
import 'package:rushpal/screens/friend_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _pendingRequestCount = 0;

  late final List<Widget> _pages = [
    const HomeScreen(),
    const MarketScreen(),
    const StatsScreen(),
    FriendScreen(
      onRequestsChanged: (count) {
        if (mounted) {
          setState(() {
            _pendingRequestCount = count;
          });
        }
      },
    ),
  ];

  // Stream สำหรับ listen pending requests แบบ real-time ที่ navbar
  Stream<DocumentSnapshot>? _userDocStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userDocStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userDocStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final pending = data['friendRequests'];
          int count = 0;
          if (pending is List) count = pending.length;

          // อัปเดต badge โดยไม่ต้องรอ onRequestsChanged callback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pendingRequestCount != count) {
              setState(() => _pendingRequestCount = count);
            }
          });
        }

        return Scaffold(
          extendBody: true,
          backgroundColor: AppTheme.backgroundCream,
          body: IndexedStack(index: _selectedIndex, children: _pages),
          bottomNavigationBar: SafeArea(child: _buildCapybaraNavbar()),
        );
      },
    );
  }

  Widget _buildCapybaraNavbar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppTheme.pureBlack, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.pureBlack.withOpacity(0.15),
            blurRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, 0, 'Home', 0),
          _buildNavItem(Icons.storefront_rounded, 1, 'Shop', 0),
          _buildNavItem(Icons.bar_chart_rounded, 2, 'Stats', 0),
          _buildNavItem(Icons.groups_rounded, 3, 'Friends', _pendingRequestCount),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label, int badgeCount) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPink : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(color: AppTheme.pureBlack, width: 2.5)
              : Border.all(color: Colors.transparent, width: 2.5),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: AppTheme.pureBlack,
                    blurRadius: 0,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppTheme.pureBlack
                      : AppTheme.textLight.withOpacity(0.5),
                  size: 28,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.pureBlack,
                  fontWeight: FontWeight.w900,
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
