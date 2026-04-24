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

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('characterId') && data.containsKey('skinId')) {
          try {
            final foundChar = myCharacters.firstWhere((c) => c.id == data['characterId']);
            final foundSkin = foundChar.skins.firstWhere((s) => s.id == data['skinId']);

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
      ),
      child: Scaffold(
        backgroundColor: AppTheme.pureBlack,
        body: Stack(
          children: [
            // 1. พื้นหลังเกม
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.4),
                colorBlendMode: BlendMode.darken,
              ),
            ),

            // 2. ตัวละคร 3D
            Positioned.fill(
              bottom: 100,
              child: ValueListenableBuilder<Skin?>(
                valueListenable: PlayerState.currentSkin,
                builder: (context, currentSkin, child) {
                  if (currentSkin == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryPink),
                    );
                  }
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: MediaQuery.of(context).size.height * 0.18,
                        child: Container(
                          width: 150,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.all(Radius.elliptical(160, 20)),
                            
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

            // 3. UI HUD
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGameHUD(context),
                  _buildBottomControls(),
                ],
              ),
            ),

            _buildInviteListener(),

            // 🌟 3. เพิ่ม Layer โชว์รายชื่อเพื่อนลอยฟ้า (จะโชว์ก็ต่อเมื่อ currentPartyCode != null)
            if (currentPartyCode != null)
              Positioned(
                top: 100, // ปรับความสูงให้อยู่ใต้ Header
                right: 20,
                child: _buildRealtimePartyList(),
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
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())),
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBlue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.pureBlack,
                        child: Icon(Icons.person, color: AppTheme.primaryPink, size: 26),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: const LinearProgressIndicator(
                                value: 0.7,
                                minHeight: 6,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPink),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Lv. 99",
                              style: TextStyle(color: AppTheme.primaryPink, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildBadge("1,000", Icons.monetization_on_rounded, Colors.amber),
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
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 15),
              _buildBadge("Streak 5", Icons.local_fire_department, Colors.orange),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PartyScreen())),
                child: _buildBadge("Party", Icons.celebration_rounded, AppTheme.primaryPink),
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
          color: AppTheme.darkBlue.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkBlue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60), 
      child: Center(
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StartRunScreen())),
          child: Container(
            width: 260,
            height: 75,
            decoration: BoxDecoration(
              color: AppTheme.primaryPink.withOpacity(0.9),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPink.withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
            ),
            child: const Center(
              child: Text(
                "TAP TO RUN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  shadows: [Shadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 6)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
