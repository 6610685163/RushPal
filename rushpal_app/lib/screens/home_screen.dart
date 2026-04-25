import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:o3d/o3d.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'start_run_screen.dart';
import 'party_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rushpal/services/party_service.dart';

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
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        setState(() {
          username = doc['username'] ?? "User";
        });
      }
    } catch (e) {
      setState(() {
        username = "Guest";
      });
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
                              child: O3D(
                                src: 'assets/models/guy.glb',
                                controller: _controller,
                                autoPlay: true,
                                autoRotate: false,
                                cameraControls: false,
                                animationName: 'mixamo.com',
                                backgroundColor: Colors.transparent,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                    ), // ลด Padding เพื่อให้มีพื้นที่จัดวาง
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

  Widget _buildStartButton() {
    // กำหนดขนาดความกว้างของปุ่ม Party และระยะห่าง เพื่อใช้คำนวณตัวถ่วงดุล
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
          // กล่องล่องหนด้านซ้าย
          // ใส่ไว้เพื่อถ่วงน้ำหนักให้ปุ่ม START อยู่ตรงกลางหน้าจอเป๊ะๆ
          const SizedBox(width: totalSideOffset),

          // ปุ่ม START (อยู่ตรงกลาง)
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

          // ระยะห่าง
          const SizedBox(width: gapSize),

          // ปุ่ม Party
          GestureDetector(
            onTap: () async {
              final resultCode = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PartyScreen(initialPartyCode: currentPartyCode),
                ),
              );

              setState(() {
                currentPartyCode = resultCode;
              });
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
                                  "Player Name",
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

  // --- UI 1: ระบบดักจับคำเชิญ และแสดง Popup แบบ Real-time ---
  Widget _buildInviteListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      // ดักฟังการเปลี่ยนแปลงในกล่องจดหมายของเราตลอดเวลา
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> invites = userData['partyInvites'] ?? [];

        // ถ้าไม่มีใครเชิญมา ก็ไม่ต้องโชว์อะไร
        if (invites.isEmpty) return const SizedBox.shrink();

        // 🌟 ถ้ามีคนเชิญมา ดึงใบแรกสุดมาโชว์เป็น Popup กลางจอ!
        final invite = invites.first;

        return Positioned(
          top: 130, // ให้ลอยอยู่ตรงหน้าอกตัวละคร 3D
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85), // สีดำโปร่งแสงดูลึกลับ
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppTheme.primaryRed, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRed.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.celebration,
                          color: AppTheme.primaryRed,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Party Invite!",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              "${invite['hostName']} ชวนคุณเข้าปาร์ตี้!",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ปุ่มปฏิเสธ (Decline)
                      TextButton(
                        onPressed: () async {
                          // ลบบัตรเชิญทิ้งเฉยๆ
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser.uid)
                              .update({
                                'partyInvites': FieldValue.arrayRemove([
                                  invite,
                                ]),
                              });
                        },
                        child: const Text(
                          "Decline",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                      // ปุ่มยอมรับ (Accept)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () async {
                          // เรียก API กดยอมรับ
                          bool success = await PartyService.acceptInvite(
                            partyId: invite['partyId'],
                            myUid: currentUser.uid,
                            myUsername: username,
                            mySkinId:
                                'skin_m_1', // อนาคตค่อยดึงค่าสกินจริงมาใส่
                            inviteObject: invite,
                          );

                          if (success) {
                            setState(() {
                              // 🌟 ไฮไลท์! พอเข้าห้องสำเร็จ เปลี่ยนรหัสห้องให้แอปจำไว้
                              currentPartyCode = invite['partyId'];
                            });
                          }
                        },
                        child: const Text(
                          "ACCEPT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- UI 2: ระบบโชว์การ์ดชื่อเพื่อนลอยฟ้าแบบ Real-time ---
  Widget _buildRealtimePartyList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parties')
          .doc(currentPartyCode)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        var partyData = snapshot.data!.data() as Map<String, dynamic>;
        var members = partyData['members'] as Map<String, dynamic>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: members.entries.map((entry) {
            String uid = entry.key;
            Map<String, dynamic> data = entry.value;
            bool isReady = data['isReady'] ?? false;

            // ซ่อนชื่อเราเอง
            if (uid == FirebaseAuth.instance.currentUser!.uid) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isReady ? Colors.green : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data['username'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
