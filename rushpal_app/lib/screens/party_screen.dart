import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/services/party_service.dart';
import 'start_run_screen.dart';
import '../models/character_model.dart';
import 'package:rushpal/widgets/user_avatar.dart';

class PartyScreen extends StatefulWidget {
  final String? initialPartyCode;
  const PartyScreen({super.key, this.initialPartyCode});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  String? partyCode;
  bool isLoading = false;
  final TextEditingController _joinController = TextEditingController();

  Future<void> _createParty() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        String username = 'Host';
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
        Navigator.pop(context, partyCode);
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundCream,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.pureBlack),
            onPressed: () => Navigator.pop(context, partyCode),
          ),
          title: const Text(
            "PARTY",
            style: TextStyle(
              color: AppTheme.pureBlack,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
          actions: [
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

  Widget _buildNoPartyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_add, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            "You are not in a party",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: _createParty,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.pureBlack, width: 3),
                boxShadow: const [
                  BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 4)),
                ],
              ),
              child: const Text(
                "CREATE NEW PARTY",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyLobby() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parties')
          .doc(partyCode)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Text(
              "Connecting to party...",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }

        if (!snapshot.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _clearPartyCode();
            setState(() => partyCode = null);
          });
          return const Center(
            child: Text(
              "Party has been deleted.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }

        var partyData = snapshot.data!.data() as Map<String, dynamic>;
        var members = partyData['members'] as Map<String, dynamic>;

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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          );
        }

        final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
        bool isLeader = members[currentUserUid]?['isLeader'] ?? false;

        bool isOthersReady = true;
        if (members.length > 1) {
          isOthersReady = members.entries
              .where((entry) => entry.key != currentUserUid)
              .every((entry) => entry.value['isReady'] == true);
        }

        bool canStart = members.length == 1 || isOthersReady;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Lobby",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.pureBlack,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppTheme.pureBlack, width: 3),
                  boxShadow: const [
                    BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Text(
                      "Code: ",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      partyCode!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryRed,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: AppTheme.pureBlack,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Text(
                "Members (${members.length}/4)",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),

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
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
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
                                    content: Text("เริ่มเกมไม่สำเร็จ!"),
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
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: isLeader
                              ? (canStart ? Colors.green : Colors.grey)
                              : ((members[currentUserUid]?['isReady'] ?? false)
                                    ? Colors.orange
                                    : Colors.green),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.pureBlack,
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.pureBlack,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isLeader
                                ? "START RUN"
                                : ((members[currentUserUid]?['isReady'] ??
                                          false)
                                      ? "CANCEL"
                                      : "READY"),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
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
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.pureBlack,
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.pureBlack,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "LEAVE",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> data, String uid) {
    bool isLeader = data['isLeader'] ?? false;
    bool isReady = data['isReady'] ?? false;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        String displayUsername = data['username'] ?? "Loading...";
        String displayLevel = "...";
        String? profileImageUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          displayUsername = userData['username'] ?? displayUsername;
          displayLevel = (userData['level'] ?? 1).toString();
          profileImageUrl = userData['profileImageUrl'];
        }

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
          child: Row(
            children: [
              UserAvatar(imageUrl: profileImageUrl, radius: 25),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayUsername,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppTheme.pureBlack,
                          ),
                        ),
                        if (isLeader) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      "Lv. $displayLevel",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isReady
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isReady ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Text(
                  isLeader ? "Leader" : (isReady ? "Ready" : "Wait"),
                  style: TextStyle(
                    color: isLeader || isReady ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.pureBlack, width: 3),
          ),
          title: const Text(
            "JOIN PARTY",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: TextField(
            controller: _joinController,
            decoration: const InputDecoration(
              hintText: "Enter 5-digit code",
              hintStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CANCEL",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                final codeInput = _joinController.text.trim();

                if (user != null && codeInput.isNotEmpty) {
                  String myUsername = "Player";
                  try {
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();
                    if (userDoc.exists) {
                      myUsername =
                          userDoc.data()?['username'] ??
                          user.displayName ??
                          "Player";
                    }
                  } catch (e) {
                    myUsername = user.displayName ?? "Player";
                  }

                  final joinedCode = await PartyService.joinPartyByCode(
                    partyCode: codeInput,
                    uid: user.uid,
                    username: myUsername,
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
                        content: Text("รหัสห้องไม่ถูกต้อง!"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.pureBlack, width: 2),
                ),
              ),
              child: const Text(
                "JOIN",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
