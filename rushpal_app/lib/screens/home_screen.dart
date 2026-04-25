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
  String? currentPartyCode;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('characterId') && data.containsKey('skinId')) {
          try {
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
            _navigateToSelectCharacter();
          }
        } else {
          _navigateToSelectCharacter();
        }
      } else {
        _navigateToSelectCharacter();
      }
    } catch (e) {
      if (mounted) setState(() => username = "Guest");
    }
  }

  void _navigateToSelectCharacter() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => const SelectCharacterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundCream,
        body: Stack(
          children: [
            // 1. พื้นหลัง (เอา colorBlendMode ออกเพื่อให้ภาพสว่าง)
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.jpg',
                fit: BoxFit.cover,
                // หากภาพพื้นหลังเดิมมืดไป สามารถปรับแต่งความโปร่งใสที่นี่
              ),
            ),

            // 2. ตัวละคร 3D
            Positioned.fill(
              bottom: 60, // ดันขึ้นเล็กน้อยหลบ Navbar ใหม่
              child: ValueListenableBuilder<Skin?>(
                valueListenable: PlayerState.currentSkin,
                builder: (context, currentSkin, child) {
                  if (currentSkin == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryPink,
                      ),
                    );
                  }
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 200,
                        child: Container(
                          width: 160,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: const BorderRadius.all(
                              Radius.elliptical(80, 8),
                            ),
                          ),
                        ),
                      ),
                      O3D(
                        key: ValueKey(currentSkin.modelPath),
                        src: currentSkin.modelPath,
                        controller: _controller,
                        autoPlay: true,
                        autoRotate: false,
                        cameraControls: false,
                        backgroundColor: Colors.transparent,
                        exposure: 0.8,
                        animationName: 'Idle',
                      ),
                    ],
                  );
                },
              ),
            ),

            // 4. UI HUD ด้านบน และปุ่ม Start ด้านล่าง
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_buildGameHUD(context), _buildBottomControls()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHUD(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ฝั่งซ้าย: โปรไฟล์ และ Coin
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const ProfileScreen()),
                ),
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.textLight.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.backgroundCream,
                        child: Icon(
                          Icons.person_rounded,
                          color: AppTheme.primaryPink,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(
                                color: AppTheme.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: const LinearProgressIndicator(
                                value: 0.7,
                                minHeight: 6,
                                backgroundColor: AppTheme.backgroundCream,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryPink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Lv. 99",
                              style: TextStyle(
                                color: AppTheme.primaryPink,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildBadge(
                "1,000",
                Icons.monetization_on_rounded,
                AppTheme.primaryRed,
              ),
            ],
          ),

          // ฝั่งขวา: Noti, Settings, Streak, Party
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 15),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopIconButton(Icons.notifications_none_rounded, () {}),
                  const SizedBox(width: 10),
                  _buildTopIconButton(Icons.settings_rounded, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const SettingsScreen()),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 15),
              _buildBadge(
                "Streak 5",
                Icons.local_fire_department_rounded,
                Colors.orange,
              ),
              const SizedBox(height: 8),
              // 🌟 2. แก้ไขปุ่ม Party ให้ส่งค่าไปและรอรับค่ากลับมา
              GestureDetector(
                onTap: () async {
                  // ส่งรหัสเดิมไป (ถ้ามี) และรอรับรหัสใหม่กลับมาตอนกด Back
                  final String? returnedCode = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      // ส่ง initialPartyCode ไปให้หน้า PartyScreen ด้วยนะ
                      builder: (context) =>
                          PartyScreen(initialPartyCode: currentPartyCode),
                    ),
                  );

                  // อัปเดตความจำให้หน้า Home
                  if (mounted) {
                    setState(() {
                      currentPartyCode = returnedCode;
                    });
                  }
                },
                child: _buildBadge(
                  "Party",
                  Icons.celebration_rounded,
                  AppTheme.primaryPink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.textLight.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.textLight, size: 24),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.textLight.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50), // ดันปุ่มให้พ้น Navbar
      child: Center(
        child: _GameStartButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StartRunScreen()),
            );
          },
        ),
      ),
    );
  }
}

class _GameStartButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _GameStartButton({required this.onPressed});

  @override
  __GameStartButtonState createState() => __GameStartButtonState();
}

class __GameStartButtonState extends State<_GameStartButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // เมื่อนิ้วแตะโดนปุ่ม
      onTapDown: (_) => setState(() => _isPressed = true),
      // เมื่อปล่อยนิ้ว (สั่งให้ทำงาน)
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      // เมื่อลากนิ้วออกนอกปุ่มแล้วปล่อย
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        // ถ้านิ้วกดอยู่ ให้ปุ่มเลื่อนลงมาด้านล่าง (ยุบตัว)
        margin: EdgeInsets.only(top: _isPressed ? 8.0 : 0.0),
        width: 240,
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.primaryPink, // พื้นหลังสีเหลือง
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: AppTheme.pureBlack, // เส้นขอบปุ่มสีดำหนา
            width: 4,
          ),
          // ถ้านิ้วกดอยู่ เงาจะหายไป (เพราะปุ่มยุบลงไปติดพื้น)
          boxShadow: _isPressed
              ? []
              : [
                  const BoxShadow(
                    color: AppTheme.pureBlack, // เงาทึบสีดำ
                    blurRadius: 0, // ไม่เบลอเงาเลย
                    offset: Offset(0, 8), // ความหนาของเงาปุ่ม
                  ),
                ],
        ),
        child: const Center(
          child: Text(
            "TAP TO RUN",
            style: TextStyle(
              color: AppTheme.pureBlack,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
        ),
      ),
    );
  }
}
