import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import '../services/database_service.dart';

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

  // ตัวแปร Stats การวิ่ง (จาก Supabase)
  bool _isLoadingStats = true;
  double totalDistance = 0.0;
  String bestPace = "0:00 /km"; // 👈 กลับมาใช้ bestPace
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

        // 👈 ดึงค่า Best Pace ที่ Backend หามาให้ และแปลงเป็น นาที:วินาที
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
      backgroundColor: AppTheme.pureBlack, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryPink.withOpacity(0.5),
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.darkBlue,
                      child: Icon(Icons.person, size: 60, color: AppTheme.primaryPink),               
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.pureBlack, width: 2),
                      ),
                      child: Text(
                        "Level $level",
                        style: const TextStyle(
                          color: AppTheme.pureBlack,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Name
            Text(
              username,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Friends & Trophies Count
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCountItem("Friends", friendsCount.toString()),
                Container(
                  height: 30,
                  width: 1,
                  color: AppTheme.primaryPink.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                ),
                _buildCountItem("Trophy earned", trophiesCount.toString()),
              ],
            ),

            const SizedBox(height: 20),

            // Edit Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Text(
                    "Edit profile",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Stats Grid 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _isLoadingStats 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPink))
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    children: [
                      _buildStatCard(
                        "Total Distance",
                        "${totalDistance.toStringAsFixed(1)} km",
                        Icons.directions_run,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        "Best Pace", // 👈 เปลี่ยนเป็น Best Pace 
                        bestPace,
                        Icons.timer,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        "Total Time",
                        "${totalTimeHrs.toStringAsFixed(1)} hrs",
                        Icons.access_time,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        "Calories Burned",
                        "$totalCalories cal",
                        Icons.local_fire_department,
                        Colors.red,
                      ),
                    ],
                  ),
            ),

            const SizedBox(height: 30),

            // Trophies Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Trophies",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "See all",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Trophy List
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildTrophyItem("First Run", Colors.amber),
                        _buildTrophyItem("5K Runner", Colors.grey),
                        _buildTrophyItem("10K Runner", Colors.brown),
                        _buildTrophyItem("Streak", Colors.blue),
                      ],
                    ),
                  ),
                ],
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.darkBlue.withOpacity(0.6), 
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildTrophyItem(String name, Color color) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(Icons.emoji_events, color: color, size: 30),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}