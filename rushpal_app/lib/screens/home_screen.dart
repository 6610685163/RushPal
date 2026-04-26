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
import 'package:rushpal/widgets/user_avatar.dart';

// RouteObserver สำหรับตรวจจับว่า HomeScreen กลับมา visible หรือไม่
final RouteObserver<ModalRoute<void>> homeRouteObserver =
    RouteObserver<ModalRoute<void>>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final O3DController _controller = O3DController();
  String username = "Loading...";
  String? profileImageUrl; // ตัวแปรสำหรับเก็บ URL รูป

  // ตัวแปรสำหรับข้อมูล Database
  int userLevel = 1;
  int userPoints = 0;
  int userExp = 0;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  String? currentPartyCode;
  List<PartyMember> partyMembers = [];
  StreamSubscription<DocumentSnapshot>? _partySubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // subscribe RouteObserver เพื่อรับ callback ตอน pop กลับมา
    homeRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // ถูกเรียกเมื่อ screen ด้านบน (เช่น market) ถูก pop กลับมาที่ home
    // force อัปเดต PlayerState จาก Firestore ล่าสุด
    _refreshAnimationFromFirestore();
  }

  Future<void> _refreshAnimationFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final newIdle = data['equipped_idle'] ?? 'idle';
      final newReady = data['equipped_ready'] ?? 'ready';
      // force set ค่าใหม่เสมอ เพื่อให้ ValueListenableBuilder rebuild O3D
      PlayerState.currentIdle.value = '';
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        PlayerState.currentIdle.value = newIdle;
        PlayerState.currentReady.value = newReady;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _listenToUserData();
    _checkExistingParty();
  }

  @override
  void dispose() {
    homeRouteObserver.unsubscribe(this);
    _userSubscription?.cancel();
    _partySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingParty() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPartyCode = prefs.getString('partyCode');

    if (savedPartyCode != null && savedPartyCode.isNotEmpty) {
      if (mounted) {
        setState(() {
          currentPartyCode = savedPartyCode;
        });
        _loadPartyMembers();
      }
    }
  }

  void _listenToUserData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists && doc.data() != null) {
              final data = doc.data()!;

              if (mounted) {
                setState(() {
                  username = data['username'] ?? "User";
                  userLevel = data['level'] ?? 1;
                  userPoints = data['points'] ?? 0;
                  userExp = data['exp'] ?? 0;
                  profileImageUrl =
                      data['profileImageUrl']; // รับค่า URL รูปมาเก็บไว้
                });
              }

              if (data.containsKey('characterId') &&
                  data.containsKey('skinId')) {
                try {
                  final foundChar = myCharacters.firstWhere(
                    (c) => c.id == data['characterId'],
                  );
                  final foundSkin = foundChar.skins.firstWhere(
                    (s) => s.id == data['skinId'],
                  );

                  final newIdle = data['equipped_idle'] ?? 'idle';
                  final newReady = data['equipped_ready'] ?? 'ready';

                  // อัปเดต ValueNotifier นอก setState เพื่อให้ ValueListenableBuilder rebuild ถูกต้อง
                  // เช็คก่อนเซ็ตเพื่อป้องกัน Firestore snapshot เก่า overwrite ค่าใหม่
                  PlayerState.currentCharacter.value = foundChar;
                  PlayerState.currentSkin.value = foundSkin;
                  // อัปเดต PlayerState จาก Firestore เสมอ
                  // market อัปเดต Firestore ก่อน ดังนั้น snapshot นี้จะได้ค่าใหม่ถูกต้อง
                  PlayerState.currentIdle.value = newIdle;
                  PlayerState.currentReady.value = newReady;

                  if (mounted) setState(() {});
                } catch (e) {
                  _navigateToSelectCharacter();
                }
              } else {
                _navigateToSelectCharacter();
              }
            } else {
              _navigateToSelectCharacter();
            }
          },
          onError: (e) {
            if (mounted) setState(() => username = "Guest");
          },
        );
  }

  void _loadPartyMembers() {
    _partySubscription?.cancel();

    if (currentPartyCode == null) {
      if (mounted) setState(() => partyMembers = []);
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
            List<PartyMember> loaded = [];
            bool isMeStillInParty = false;

            membersMap.forEach((uid, memberData) {
              if (uid == myUid) {
                isMeStillInParty = true;
                return;
              }

              try {
                String skinId = memberData['skinId'] ?? "skin_m_1";
                String idleId = memberData['idleId'] ?? 'idle';
                String readyId = memberData['readyId'] ?? 'ready';
                bool found = false;

                for (var char in myCharacters) {
                  for (var skin in char.skins) {
                    if (skin.id == skinId) {
                      loaded.add(
                        PartyMember(
                          skin: skin,
                          idleId: idleId,
                          readyId: readyId,
                        ),
                      );
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

            if (!isMeStillInParty) {
              if (mounted) {
                setState(() {
                  currentPartyCode = null;
                  partyMembers = [];
                });
              }
              SharedPreferences.getInstance().then(
                (prefs) => prefs.remove('partyCode'),
              );
              return;
            }

            if (mounted) {
              setState(() {
                partyMembers = loaded;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                currentPartyCode = null;
                partyMembers = [];
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
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: 160,
              left: 0,
              right: 0,
              height: 550,
              child: ValueListenableBuilder<String>(
                valueListenable: PlayerState.currentIdle,
                builder: (context, currentIdle, child) {
                  return ValueListenableBuilder<String>(
                    valueListenable: PlayerState.currentReady,
                    builder: (context, currentReady, child) {
                      return ValueListenableBuilder<Skin?>(
                        valueListenable: PlayerState.currentSkin,
                        builder: (context, currentSkin, child) {
                          if (currentSkin == null) {
                            return const SizedBox.shrink();
                          }

                          // สร้าง PartyMember สำหรับตัวเราเองโดยดึง animation จาก builder
                          final myMember = PartyMember(
                            skin: currentSkin,
                            idleId: currentIdle,
                            readyId: currentReady,
                          );
                          List<PartyMember> allMembers = [
                            myMember,
                            ...partyMembers,
                          ];
                          List<Widget> characterStack = [];

                          Widget buildCharacter(
                            PartyMember member,
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
                                      key: ValueKey(
                                        "home_char_${member.skin.id}_${index == 0 ? currentIdle : member.idleId}_$index",
                                      ),
                                      controller: index == 0
                                          ? _controller
                                          : null,
                                      src: member.skin.modelPath,
                                      autoPlay: true,
                                      autoRotate: false,
                                      cameraControls: false,
                                      backgroundColor: Colors.transparent,
                                      exposure: 0.9,
                                      animationName: index == 0
                                          ? currentIdle
                                          : member.idleId,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (allMembers.length == 4) {
                            List<double> xPositions = [
                              45.0,
                              -45.0,
                              -140.0,
                              140.0,
                            ];
                            for (int i = 3; i >= 1; i--) {
                              characterStack.add(
                                buildCharacter(
                                  allMembers[i],
                                  i,
                                  xPositions[i],
                                  112,
                                ),
                              );
                            }
                            characterStack.add(
                              buildCharacter(
                                allMembers[0],
                                0,
                                xPositions[0],
                                97.0,
                              ),
                            );
                          } else if (allMembers.length == 2) {
                            // 2 คน: เรียงซ้าย-ขวาชิดกัน
                            characterStack.add(
                              buildCharacter(allMembers[1], 1, -55.0, 112),
                            );
                            characterStack.add(
                              buildCharacter(allMembers[0], 0, 55.0, 97.0),
                            );
                          } else {
                            for (int i = allMembers.length - 1; i >= 1; i--) {
                              int depth = (i + 1) ~/ 2;
                              double side = (i % 2 != 0) ? -1.0 : 1.0;
                              double xPos = depth * 85.0 * side;
                              characterStack.add(
                                buildCharacter(allMembers[i], i, xPos, 112),
                              );
                            }
                            characterStack.add(
                              buildCharacter(allMembers[0], 0, 0.0, 97.0),
                            );
                          }

                          return Stack(
                            alignment: Alignment.bottomCenter,
                            children: characterStack,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
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
                  width: 210,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
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
                      // เปลี่ยนมาใช้ UserAvatar แทน CircleAvatar เดิมที่เคยใส่ Icon ไว้
                      UserAvatar(imageUrl: profileImageUrl, radius: 22),
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
                            const SizedBox(height: 6),

                            Builder(
                              builder: (context) {
                                int expNeeded = userLevel * 50;

                                double progress = expNeeded > 0
                                    ? (userExp / expNeeded).clamp(0.0, 1.0)
                                    : 0.0;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey.shade300,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              AppTheme.primaryPink,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Lv. $userLevel",
                                          style: const TextStyle(
                                            color: AppTheme.primaryPink,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "$userExp / $expNeeded EXP",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
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
                "$userPoints G",
                Icons.monetization_on_rounded,
                Colors.amber,
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.textLight.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.celebration_rounded,
                        color: AppTheme.primaryPink,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Party",
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
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
          color: Colors.white.withOpacity(0.9),
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
        color: Colors.white.withOpacity(0.9),
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
