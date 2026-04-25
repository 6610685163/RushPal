import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:o3d/o3d.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  // ตัวแปรสำหรับข้อมูล Database
  int userLevel = 1;
  int userPoints = 0;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  String? currentPartyCode;
  List<Skin> partyMembersSkins = [];
  StreamSubscription<DocumentSnapshot>? _partySubscription;

  @override
  void initState() {
    super.initState();
    _listenToUserData(); // เปลี่ยนมาใช้ฟังก์ชันแบบ Real-time
    _checkExistingParty(); // เรียกใช้ฟังก์ชันเช็คปาร์ตี้ค้างตั้งแต่เปิดหน้าจอ
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _partySubscription?.cancel();
    super.dispose();
  }

  // ฟังก์ชันเช็คว่าเราเคยเข้าร่วมปาร์ตี้ไว้แล้วหรือยัง
  Future<void> _checkExistingParty() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPartyCode = prefs.getString('partyCode');

    if (savedPartyCode != null && savedPartyCode.isNotEmpty) {
      if (mounted) {
        setState(() {
          currentPartyCode = savedPartyCode;
        });
        _loadPartyMembers(); // ถ้ามีรหัสห้อง ให้โหลดโมเดลเพื่อนมาโชว์เลย
      }
    }
  }

  // ฟังก์ชันดึงข้อมูลผู้ใช้แบบ Real-time (อัปเดตเงิน/เลเวลทันที)
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
            userLevel = data['level'] ?? 1;
            userPoints = data['points'] ?? 0;
          });
        }

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
    }, onError: (e) {
      if (mounted) setState(() => username = "Guest");
    });
  }

  void _loadPartyMembers() {
    _partySubscription?.cancel();

    if (currentPartyCode == null) {
      if (mounted) setState(() => partyMembersSkins = []);
      return;
    }

    _partySubscription = FirebaseFirestore.instance
        .collection('parties')
        .doc(currentPartyCode)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final partyData = snapshot.data() as Map<String, dynamic>;
            final membersMap =
                partyData['members'] as Map<String, dynamic>? ?? {};

            final myUid = FirebaseAuth.instance.currentUser?.uid;
            List<Skin> loadedSkins = [];
            bool isMeStillInParty = false;

            membersMap.forEach((uid, memberData) {
              if (uid == myUid) {
                isMeStillInParty = true;
                return;
              }

              try {
                String skinId = memberData['skinId'] ?? "skin_m_1";
                bool found = false;

                for (var char in myCharacters) {
                  for (var skin in char.skins) {
                    if (skin.id == skinId) {
                      loadedSkins.add(skin);
                      found = true;
                      break;
                    }
                  }
                  if (found) break;
                }
              } catch (e) {
                print("Skin matching error: $e");
              }
            });

            // ถ้าระบบพบว่าเราโดนเตะ หรือออกห้องไปแล้ว ให้เคลียร์ข้อมูลทิ้ง
            if (!isMeStillInParty) {
              if (mounted) {
                setState(() {
                  currentPartyCode = null;
                  partyMembersSkins = [];
                });
              }
              SharedPreferences.getInstance().then(
                (prefs) => prefs.remove('partyCode'),
              );
              return;
            }

            if (mounted) {
              setState(() {
                partyMembersSkins = loadedSkins;
              });
            }
          } else {
            // ถ้าห้องปาร์ตี้โดนยุบทิ้ง (เอกสารใน Firestore หายไป)
            if (mounted) {
              setState(() {
                currentPartyCode = null;
                partyMembersSkins = [];
              });
            }
            SharedPreferences.getInstance().then(
              (prefs) => prefs.remove('partyCode'),
            );
          }
        });
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
            // 1. พื้นหลัง
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // 2. โซนตัวละคร (1-3 คนเป็นตัว V, 4 คนเป็นหน้ากระดาน)
            Positioned(
              bottom: 160,
              left: 0,
              right: 0,
              height: 550,
              child: ValueListenableBuilder<Skin?>(
                valueListenable: PlayerState.currentSkin,
                builder: (context, currentSkin, child) {
                  if (currentSkin == null) {
                    return const SizedBox.shrink();
                  }

                  List<Skin> allSkins = [currentSkin, ...partyMembersSkins];
                  List<Widget> characterStack = [];

                  Widget buildCharacter(
                    Skin skin,
                    int index,
                    double xOffset,
                    double shadowBottom,
                  ) {
                    return Transform.translate(
                      offset: Offset(xOffset, 0),
                      child: SizedBox(
                        width: index == 0 ? 350 : 280,
                        height: 550,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Positioned(
                              bottom: shadowBottom,
                              child: Container(
                                width: index == 0 ? 140 : 100,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.12),
                                  borderRadius: const BorderRadius.all(
                                    Radius.elliptical(80, 15),
                                  ),
                                ),
                              ),
                            ),
                            O3D(
                              // เพิ่มเวลาเข้าไปใน ValueKey เพื่อบังคับให้รีโหลดเสมอเมื่อข้อมูลเปลี่ยน
                              key: ValueKey("home_char_${skin.id}_$index"),
                              // เปลี่ยนจาก _controller มาเป็นการเช็คว่าถ้าเป็นตัวเรา ถึงใช้ _controller ถ้าเป็นเพื่อนไม่ต้องใช้
                              controller: index == 0 ? _controller : null,
                              src: skin.modelPath,
                              autoPlay: true,
                              autoRotate: false,
                              cameraControls: false,
                              backgroundColor: Colors.transparent,
                              exposure: 0.9,
                              animationName: 'Idle',
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (allSkins.length == 4) {
                    List<double> xPositions = [45.0, -45.0, -140.0, 140.0];
                    for (int i = 3; i >= 1; i--) {
                      characterStack.add(
                        buildCharacter(allSkins[i], i, xPositions[i], 120.0),
                      );
                    }
                    characterStack.add(
                      buildCharacter(allSkins[0], 0, xPositions[0], 80.0),
                    );
                  } else {
                    for (int i = allSkins.length - 1; i >= 1; i--) {
                      int depth = (i + 1) ~/ 2;
                      double side = (i % 2 != 0) ? -1.0 : 1.0;
                      double xPos = depth * 100.0 * side;
                      characterStack.add(
                        buildCharacter(allSkins[i], i, xPos, 140.0),
                      );
                    }
                    characterStack.add(
                      buildCharacter(allSkins[0], 0, 0.0, 80.0),
                    );
                  }

                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: characterStack,
                  );
                },
              ),
            ),
            
            // 3. UI HUD และปุ่ม Start
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
                            // อัปเดต เลเวลตรงนี้
                            Text(
                              "Lv. $userLevel",
                              style: const TextStyle(
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
              // อัปเดต เงินตรงนี้
              _buildBadge(
                "$userPoints G",
                Icons.monetization_on_rounded,
                AppTheme.primaryRed,
              ),
            ],
          ),
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
              GestureDetector(
                onTap: () async {
                  final dynamic returnedCode = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PartyScreen(initialPartyCode: currentPartyCode),
                    ),
                  );
                  if (mounted && returnedCode is String?) {
                    setState(() => currentPartyCode = returnedCode);
                    _loadPartyMembers();
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
      padding: const EdgeInsets.only(bottom: 50),
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
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: _isPressed ? 8.0 : 0.0),
        width: 240,
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.primaryPink,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: AppTheme.pureBlack, width: 4),
          boxShadow: _isPressed
              ? []
              : [
                  const BoxShadow(
                    color: AppTheme.pureBlack,
                    blurRadius: 0,
                    offset: Offset(0, 8),
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