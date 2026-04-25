import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/services/party_service.dart';
import 'package:rushpal/widgets/user_avatar.dart';

class PartyResultScreen extends StatefulWidget {
  final String partyCode;
  const PartyResultScreen({super.key, required this.partyCode});

  @override
  State<PartyResultScreen> createState() => _PartyResultScreenState();
}

class _PartyResultScreenState extends State<PartyResultScreen> {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> _fetchPartyStats() async {
    final response = await supabase
        .from('runs')
        .select()
        .eq('partycode', widget.partyCode)
        .order('distance', ascending: false);
    return response as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parties')
            .doc(widget.partyCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryPink),
            );

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Data missing...",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }

          var partyData = snapshot.data!.data() as Map<String, dynamic>;
          var members = partyData['members'] as Map<String, dynamic>;

          int finishedCount = members.values
              .where((m) => m['status'] == 'finished')
              .length;
          bool isAllFinished = finishedCount == members.length;

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "PARTY RESULT",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.pureBlack,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  "ROOM: ${widget.partyCode}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 25),

                if (!isAllFinished)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.orange, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 15),
                        Text(
                          "WAITING FRIENDS ($finishedCount/${members.length})",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _fetchPartyStats(),
                    builder: (context, statsSnapshot) {
                      if (statsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryPink,
                          ),
                        );
                      }

                      final stats = statsSnapshot.data ?? [];

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          String uid = members.keys.elementAt(index);
                          var memberInfo = members[uid];

                          int statIndex = stats.indexWhere(
                            (s) => s['user_id'] == uid,
                          );
                          var userStat = statIndex != -1
                              ? stats[statIndex]
                              : null;

                          return _buildResultCard(
                            memberInfo['username'] ?? "Unknown",
                            userStat,
                            uid == FirebaseAuth.instance.currentUser?.uid,
                            uid,
                          );
                        },
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GestureDetector(
                    onTap: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await PartyService.leaveParty(
                          partyCode: widget.partyCode,
                          uid: user.uid,
                        );
                      }
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink,
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(color: AppTheme.pureBlack, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.pureBlack,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "BACK TO HOME",
                          style: TextStyle(
                            color: AppTheme.pureBlack,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCard(String name, dynamic stat, bool isMe, String uid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe ? AppTheme.primaryPink : AppTheme.pureBlack,
          width: 4,
        ),
        boxShadow: const [
          BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, snapshot) {
              String? imageUrl;
              if (snapshot.hasData && snapshot.data!.exists) {
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                imageUrl = userData['profileImageUrl'];
              }
              return UserAvatar(imageUrl: imageUrl, radius: 24);
            },
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? "$name (Me)" : name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppTheme.pureBlack,
                  ),
                ),
                if (stat != null)
                  Text(
                    "${stat['distance']} km | ${stat['pace']} /km",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  )
                else
                  const Text(
                    "Running...",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          if (stat != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${stat['calories']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryRed,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  "KCAL",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
