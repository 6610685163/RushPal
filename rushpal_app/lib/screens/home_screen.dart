import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:o3d/o3d.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/character_model.dart';
import 'select_character_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'start_run_screen.dart';
import 'party_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final O3DController _controller = O3DController();
  String username = "Loading...";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // ดึงข้อมูลผู้ใช้จาก Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // ตรวจสอบว่าเคยเลือกตัวละครหรือยัง
        if (data.containsKey('characterId') && data.containsKey('skinId')) {
          try {
            // หาข้อมูลตัวละครและสกินจาก ID ใน Database มาเก็บไว้ที่ Global State
            final foundChar = myCharacters.firstWhere(
              (c) => c.id == data['characterId'],
            );
            final foundSkin = foundChar.skins.firstWhere(
              (s) => s.id == data['skinId'],
            );

            if (mounted) {
              setState(() {
                PlayerState.currentCharacter.value = foundChar;
                PlayerState.currentSkin.value = foundSkin;
                username = data['username'] ?? "User";
              });
            }
          } catch (e) {
            // กรณี ID ในฐานข้อมูลไม่ตรงกับก้อนข้อมูลในแอป ให้ไปหน้าเลือกตัวละครใหม่
            _navigateToSelectCharacter();
          }
        } else {
          // ถ้ายังไม่มีข้อมูลตัวละครในฐานข้อมูล ให้ไปหน้าเลือกตัวละคร
          _navigateToSelectCharacter();
        }
      } else {
        // กรณีไม่มีเอกสารผู้ใช้ใน Firestore
        _navigateToSelectCharacter();
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      if (mounted) {
        setState(() {
          username = "Guest";
        });
      }
    }
  }

  void _navigateToSelectCharacter() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const SelectCharacterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.primaryRed,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 10),

                  // --- Character Card (Avatar) ---
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/home_bg.png',
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    Container(color: Colors.grey[200]),
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              top: 0,
                              child: ValueListenableBuilder<Skin?>(
                                valueListenable: PlayerState.currentSkin,
                                builder: (context, currentSkin, child) {
                                  // ถ้ายังโหลดข้อมูลไม่เสร็จ ให้แสดงตัวหมุน
                                  if (currentSkin == null) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.primaryRed,
                                      ),
                                    );
                                  }

                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // --- จำลองเงาใต้โมเดล ---
                                      Positioned(
                                        bottom: 20, // ปรับความสูงต่ำของเงาที่นี่
                                        child: Container(
                                          width: 140, // ปรับความกว้างของเงา
                                          height: 25, // ปรับความแบนของเงา
                                          decoration: const BoxDecoration(
                                            color: Colors
                                                .black26, // ความเข้มของเงา
                                            borderRadius: BorderRadius.all(
                                              Radius.elliptical(140, 25),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // ----------------------

                                      // --- โมเดล 3D ---
                                      SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: O3D(
                                          key: ValueKey(currentSkin.modelPath),
                                          src: currentSkin.modelPath,
                                          controller: _controller,
                                          autoPlay: true,
                                          autoRotate: false,
                                          cameraControls: false,
                                          backgroundColor: Colors.transparent,
                                          exposure: 0.6,
                                          animationName: 'Idle',
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 20,
                              left: 20,
                              child: _buildBadge(
                                "Streak 5",
                                Icons.local_fire_department,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- Control Area ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildStartButton(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    const double partyButtonSize = 50.0;
    const double gapSize = 10.0;
    const double totalSideOffset = partyButtonSize + gapSize;

    return SizedBox(
      height: 90,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: totalSideOffset),
          Container(
            width: 230,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StartRunScreen(),
                    ),
                  );
                },
                child: const Center(
                  child: Text(
                    "START",
                    style: TextStyle(
                      color: AppTheme.primaryRed,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: gapSize),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PartyScreen()),
              );
            },
            child: Container(
              width: partyButtonSize,
              height: partyButtonSize,
              color: Colors.transparent,
              child: const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 34,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const ProfileScreen()),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          color: AppTheme.primaryRed,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Lv. 99",
                                  style: TextStyle(
                                    color: AppTheme.primaryRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: const LinearProgressIndicator(
                              value: 0.7,
                              minHeight: 8,
                              backgroundColor: Color(0xFFEEEEEE),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(
                                Icons.monetization_on_rounded,
                                size: 18,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "1,000 G",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const SettingsScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Icon(
                  Icons.hexagon_outlined,
                  color: Colors.black87,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
