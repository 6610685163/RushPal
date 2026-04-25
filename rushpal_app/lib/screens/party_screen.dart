import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/services/party_service.dart';
import 'start_run_screen.dart';
import '../models/character_model.dart';

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

  // ฟังก์ชันสร้างห้องใหม่
  Future<void> _createParty() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String username = 'Host';
        // ดึง skinId ปัจจุบันของผู้ใช้
        String currentSkinId = PlayerState.currentSkin.value?.id ?? "skin_m_1";

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          username = userData['username'] ?? user.displayName ?? 'Host';
        } else {
          username = user.displayName ?? 'Host';
        }

        final code = await PartyService.createParty(
          uid: user.uid,
          username: username,
          skinId: currentSkinId, 
        );
        if (code != null) {
          setState(() => partyCode = code);
          await _savePartyCode(code);
        }
      } catch (e) {
        print('Error fetching user data: $e');
        final username = user.displayName ?? 'Host';
        final code = await PartyService.createParty(
          uid: user.uid,
          username: username,
          skinId: "skin_m_1",
        );
        if (code != null) {
          setState(() => partyCode = code);
          await _savePartyCode(code);
        }
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _loadPartyCode();
  }

  Future<void> _loadPartyCode() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.initialPartyCode != null) {
      partyCode = widget.initialPartyCode;
    } else {
      partyCode = prefs.getString('partyCode');
    }
    setState(() {});
  }

  Future<void> _savePartyCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('partyCode', code);
  }

  Future<void> _clearPartyCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('partyCode');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, partyCode); // ส่งรหัสห้องกลับไปหน้า Home
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context, partyCode),
          ),
          title: const Text(
            "Party",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          actions: [
            // ถ้ายังไม่มีห้อง ให้โชว์ปุ่ม Join
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
        body: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryRed),
                )
              : partyCode == null
              ? _buildNoPartyState() 
              : _buildPartyLobby(), 
        ),
      ),
    );
  }

  // --- UI ตอนยังไม่ได้สร้างหรือเข้าร่วมปาร์ตี้ ---
  Widget _buildNoPartyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_add, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            "You are not in a party",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _createParty,
            child: const Text(
              "CREATE NEW PARTY",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI หน้า Lobby ---
  Widget _buildPartyLobby() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parties')
          .doc(partyCode)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Text("Connecting to party..."));
        }

        if (!snapshot.data!.exists) {
          // Party ถูกลบ ลบ shared และ reset
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _clearPartyCode();
            setState(() => partyCode = null);
          });
          return const Center(child: Text("Party has been deleted."));
        }

        var partyData = snapshot.data!.data() as Map<String, dynamic>;
        var members = partyData['members'] as Map<String, dynamic>;

        // ดักจังหวะวาร์ป: ถ้าหัวหน้ากด Start แล้ว status เป็น 'running'
        if (partyData['status'] == 'running') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StartRunScreen(partyCode: partyCode!),
              ),
            );
          });
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
        bool isOthersReady = true;
        if (members.length > 1) {
          isOthersReady = members.entries
              .where((entry) => entry.key != currentUserUid)
              .every((entry) => entry.value['isReady'] == true); 
        }

        // ถ้าในปาร์ตี้มีคนเดียว หรือ ทุกคนพร้อมแล้ว = ให้เริ่มได้!
        bool canStart = members.length == 1 || isOthersReady;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Party Name",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Party Code Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Party code: ",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      partyCode!, 
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        /* Logic Copy รหัส */
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Text(
                "Members (${members.length}/4)",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Member List 
              Expanded(
                child: ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    String uid = members.keys.elementAt(index);
                    return _buildMemberCard(members[uid], uid);
                  },
                ),
              ),

              const SizedBox(height: 10),
              // --- โซนปุ่มกด Ready และ Leave ---
              Row(
                children: [
                  // ปุ่ม START / READY
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          if (isLeader) {
                            if (canStart) {
                              bool success = await PartyService.startParty(
                                partyCode: partyCode!,
                              );

                              if (!success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "เริ่มเกมไม่สำเร็จ! เช็คเซิร์ฟเวอร์ Node.js หรือเน็ตมือถือ",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("รอให้ทุกคนกด Ready ก่อน!"),
                                ),
                              );
                            }
                          } else {
                            bool myReadyStatus =
                                members[user.uid]?['isReady'] ?? false;
                            await PartyService.toggleReady(
                              partyCode: partyCode!,
                              uid: user.uid,
                              isReady: !myReadyStatus,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLeader
                              ? (canStart ? Colors.green : Colors.grey)
                              : ((members[currentUserUid]?['isReady'] ?? false)
                                    ? Colors.orange
                                    : Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isLeader
                              ? "START RUN"
                              : ((members[currentUserUid]?['isReady'] ?? false)
                                    ? "CANCEL"
                                    : "READY"),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
                            bool success = await PartyService.leaveParty(
                              partyCode: partyCode!,
                              uid: user.uid,
                            );

                            if (success) {
                              setState(() => partyCode = null);
                              await _clearPartyCode();
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
        );
      },
    );
  }

  // 💡 สร้าง StreamBuilder ไปดึง Profile ของคนคนนั้นมาโชว์จริงๆ แบบ Real-time!
  Widget _buildMemberCard(Map<String, dynamic> data, String uid) {
    bool isLeader = data['isLeader'] ?? false;
    bool isReady = data['isReady'] ?? false;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        
        // กำหนดค่าเริ่มต้นระหว่างรอข้อมูล
        String displayUsername = data['username'] ?? "Loading...";
        String displayLevel = "...";

        // ถ้าดึงข้อมูลจาก Database สำเร็จ ให้ทับด้วยข้อมูลจริง
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          displayUsername = userData['username'] ?? displayUsername;
          displayLevel = (userData['level'] ?? 1).toString();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isReady ? Colors.green.withOpacity(0.3) : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayUsername, // 💡 โชว์ชื่อจาก Database
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (isLeader) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star, color: Colors.orange, size: 16),
                        ],
                      ],
                    ),
                    Text(
                      "Lv. $displayLevel", // 💡 โชว์เลเวลจาก Database
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isReady ? Colors.green.withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLeader ? "Leader" : (isReady ? "Ready" : "Waiting"),
                  style: TextStyle(
                    color: isLeader || isReady ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }
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
                final codeInput = _joinController.text.trim();

                if (user != null && codeInput.isNotEmpty) {
                  // 💡 ดึงชื่อตัวเองจาก Database ให้ชัวร์ก่อนกด Join (แก้ปัญหา Guest_Player)
                  String myUsername = "Player";
                  try {
                    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                    if (userDoc.exists) {
                      myUsername = userDoc.data()?['username'] ?? user.displayName ?? "Player";
                    }
                  } catch (e) {
                    myUsername = user.displayName ?? "Player";
                  }

                  final joinedCode = await PartyService.joinPartyByCode(
                    partyCode: codeInput,
                    uid: user.uid,
                    username: myUsername, // ส่งชื่อจริงเข้าไป
                    skinId: PlayerState.currentSkin.value?.id ?? "skin_m_1",
                  );

                  if (joinedCode != null) {
                    Navigator.pop(context);
                    setState(() {
                      partyCode = joinedCode;
                      _joinController.clear(); 
                    });
                    await _savePartyCode(joinedCode);
                  } else {
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