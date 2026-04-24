import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/services/party_service.dart';
import 'start_run_screen.dart';

class PartyScreen extends StatefulWidget {
  final String? initialPartyCode;
  const PartyScreen({super.key, this.initialPartyCode});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  String? partyCode; // รหัสห้อง 5 หลัก
  bool isLoading = false;
  final TextEditingController _joinController = TextEditingController();

  // 🌟 ฟังก์ชันสร้างห้องใหม่
  Future<void> _createParty() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // ดึง Username จาก Firestore (สมมติว่าคุณมีฟังก์ชันโหลดข้อมูลยูสเซอร์อยู่แล้ว)
      // ในที่นี้ขอใช้ "Host" ไปก่อนเพื่อเทส
      final code = await PartyService.createParty(
        uid: user.uid,
        username: "Host",
        skinId: "skin_m_1",
      );
      if (code != null) {
        setState(() => partyCode = code);
      }
    }
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    partyCode =
        widget.initialPartyCode; // 🌟 2. ดึงค่าจาก Home มาใส่ตอนเปิดหน้า
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureBlack, // สีดำ
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Party",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          centerTitle: true,
          actions: [
            // 🌟 ถ้ายังไม่มีห้อง ให้โชว์ปุ่ม Join
            if (partyCode == null)
              TextButton(
                onPressed: () => _showJoinDialog(context),
                child: const Text(
                  "Join Party",
                  style: TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _showJoinDialog(context),
            child: const Text(
              "CREATE NEW PARTY",
              style: TextStyle(
                color: AppTheme.primaryPink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI หน้า Lobby (ที่เพื่อนคุณทำไว้ แต่เปลี่ยนเป็น Real-time) ---
  Widget _buildPartyLobby() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parties')
          .doc(partyCode)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Connecting to party..."));
        }

        var partyData = snapshot.data!.data() as Map<String, dynamic>;
        var members = partyData['members'] as Map<String, dynamic>;

        // 🌟 1. ดักจังหวะวาร์ป: ถ้าหัวหน้ากด Start แล้ว status เป็น 'running'
        if (partyData['status'] == 'running') {
          // ใช้ addPostFrameCallback เพื่อให้ Flutter วาด UI เสร็จก่อนค่อยสั่งเปลี่ยนหน้า (กัน Error)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StartRunScreen(),
              ), // พาไปหน้าวิ่งเลย!
            );
          });
          // โชว์ข้อความรอก่อนโดนเด้ง
          return const Center(
            child: Text(
              "🏃‍♂️💨 ปาร์ตี้กำลังจะเริ่ม...",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          );
        }

        // เช็คว่าเราเป็นหัวหน้าห้องไหม
        final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
        bool isLeader = members[currentUserUid]?['isLeader'] ?? false;

        // เช็คว่าลูกทีมทุกคน (ยกเว้นเรา) กด Ready ครบหรือยัง
        bool isAllReady = members.values.every((m) => m['isReady'] == true);

        // 🌟 เพิ่มบรรทัดนี้: ถ้าในปาร์ตี้มีคนเดียว (length == 1) หรือ ทุกคนพร้อมแล้ว = ให้เริ่มได้!
        bool canStart = members.length == 1 || isAllReady;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Party Name",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkBlue.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Party code: ",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    Text(
                      partyCode!, // 🌟 โชว์รหัสจริงจากระบบ
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPink,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Members",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildMemberCard(index),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ปุ่ม LEAVE PARTY
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // 🌟 ยิง API ลบตัวเองออกจาก Database
                            bool success = await PartyService.leaveParty(
                              partyCode: partyCode!,
                              uid: user.uid,
                            );

                            if (success) {
                              // ถ้าลบสำเร็จ ค่อยรีเซ็ตหน้าจอ
                              setState(() => partyCode = null);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "LEAVE",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.primaryPink)
          ),
          title: const Text(
            "Join Party",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter party code",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: AppTheme.pureBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Join", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> data, String uid) {
    bool isLeader = data['isLeader'] ?? false;
    bool isReady = data['isReady'] ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBlue.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.pureBlack,
              image: DecorationImage(
                image: AssetImage('assets/images/home_bg.png'),
                fit: BoxFit.cover,
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
                    Text(
                      data['username'] ?? "Unknown",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    if (isLeader) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                    ],
                  ],
                ),
                Text(
                  levels[index],
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLeader ? Colors.green.withOpacity(0.2) : Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isLeader ? "Leader" : (isReady ? "Ready" : "Waiting"),
              style: TextStyle(
                color: isLeader ? Colors.greenAccent : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Join Party"),
          content: TextField(
            controller: _joinController,
            decoration: const InputDecoration(hintText: "Enter 5-digit code"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                final codeInput = _joinController.text
                    .trim(); // เอาช่องว่างหัวท้ายออก

                if (user != null && codeInput.isNotEmpty) {
                  // 🌟 เรียกใช้ API ที่เพิ่งสร้าง
                  final joinedCode = await PartyService.joinPartyByCode(
                    partyCode: codeInput,
                    uid: user.uid,
                    username:
                        "Guest_Player", // TODO: อนาคตค่อยดึงชื่อจริงจาก Firestore
                    skinId: "skin_m_1",
                  );

                  if (joinedCode != null) {
                    // ถ้าเข้าสำเร็จ ปิด Dialog และเปลี่ยนหน้าจอไปที่ Lobby
                    Navigator.pop(context);
                    setState(() {
                      partyCode = joinedCode;
                      _joinController.clear(); // ล้างช่องกรอกเผื่อไว้
                    });
                  } else {
                    // ถ้าเข้าไม่ได้ (รหัสผิด/ห้องไม่มีจริง) โชว์แจ้งเตือน
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "รหัสห้องไม่ถูกต้อง หรือปาร์ตี้เริ่มไปแล้ว!",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Join", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
