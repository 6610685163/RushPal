import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import '../services/database_service.dart';
import 'package:rushpal/widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ตัวแปรเก็บข้อมูลจาก Firebase
  String username = "Loading...";
  int level = 1;
  int friendsCount = 0;
  int trophiesCount = 0;
  String? profileImageUrl;

  // ตัวแปร Stats การวิ่ง (จาก Supabase)
  bool _isLoadingStats = true;
  double totalDistance = 0.0;
  String bestPace = "0:00 /km";
  double totalTimeHrs = 0.0;
  int totalCalories = 0;

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _listenToUserData();
    _fetchTotalStats(); // สั่งดึงสถิติเมื่อเปิดหน้า
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  // 1. ฟังก์ชันดึงข้อมูลโปรไฟล์จาก Firebase
  void _listenToUserData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            if (mounted) {
              setState(() {
                username = data['username'] ?? "User";
                level = data['level'] ?? 1;
                final friendsList = data['friends'] as List<dynamic>? ?? [];
                friendsCount = friendsList.length;
                profileImageUrl = data['profileImageUrl'];
              });
            }
          }
        });
  }

  // 2. ฟังก์ชันดึงข้อมูลสถิติรวมทั้งหมดจาก Supabase
  Future<void> _fetchTotalStats() async {
    final db = DatabaseService();
    // ส่งคำว่า 'all' เพื่อให้ backend ไม่เข้าเงื่อนไขวัน/สัปดาห์/เดือน
    final stats = await db.fetchUserStats('all');

    if (stats != null && mounted) {
      setState(() {
        totalDistance = (stats['total_distance'] as num?)?.toDouble() ?? 0.0;
        int totalSeconds = (stats['total_time_seconds'] as num?)?.toInt() ?? 0;
        totalCalories = (stats['total_calories'] as num?)?.toInt() ?? 0;

        // แปลงวินาทีเป็นชั่วโมงแบบทศนิยม (เช่น 1.5 hrs)
        totalTimeHrs = totalSeconds / 3600.0;

        // ดึงค่า Best Pace ที่ Backend หามาให้ และแปลงเป็น นาที:วินาที
        double? bestPaceDecimal = (stats['best_pace'] as num?)?.toDouble();
        if (bestPaceDecimal != null && bestPaceDecimal > 0) {
          int minutes = bestPaceDecimal.floor();
          int seconds = ((bestPaceDecimal - minutes) * 60).round();
          bestPace = "$minutes:${seconds.toString().padLeft(2, '0')} /km";
        } else {
          bestPace = "0:00 /km"; // กรณีที่ยังไม่เคยวิ่ง หรือวิ่งแล้วได้เพซ 0
        }

        _isLoadingStats = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.pureBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "PROFILE",
          style: TextStyle(
            color: AppTheme.pureBlack,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Image & Level
            Center(
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppTheme.pureBlack, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: AppTheme.pureBlack,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: UserAvatar(imageUrl: profileImageUrl, radius: 50),
                  ),
                  Positioned(
                    bottom: -14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.pureBlack, width: 3),
                      ),
                      child: Text(
                        "Lv. $level",
                        style: const TextStyle(
                          color: AppTheme.pureBlack,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name
            Text(
              username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.pureBlack,
              ),
            ),

            const SizedBox(height: 20),

            // Friends & Trophies Count
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCountItem("Friends", friendsCount.toString()),
                Container(
                  height: 40,
                  width: 3,
                  color: AppTheme.pureBlack.withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                ),
                _buildCountItem("Trophies", trophiesCount.toString()),
              ],
            ),

            const SizedBox(height: 25),

            // Edit Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppTheme.pureBlack, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.pureBlack,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "EDIT PROFILE",
                      style: TextStyle(
                        color: AppTheme.pureBlack,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCountItem(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.pureBlack,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.pureBlack, width: 3),
        boxShadow: const [
          BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.pureBlack,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyItem(String name, Color color) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.pureBlack, width: 3),
              boxShadow: const [
                BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 3)),
              ],
            ),
            child: Icon(Icons.emoji_events_rounded, color: color, size: 35),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppTheme.pureBlack,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
