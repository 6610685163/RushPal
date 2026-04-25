import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/services/party_service.dart';

class PartyResultScreen extends StatefulWidget {
  final String partyCode;
  const PartyResultScreen({super.key, required this.partyCode});

  @override
  State<PartyResultScreen> createState() => _PartyResultScreenState();
}

class _PartyResultScreenState extends State<PartyResultScreen> {
  final supabase = Supabase.instance.client;

  // ฟังก์ชันดึงสถิติของทุกคนจาก Supabase โดยใช้ partycode
  Future<List<dynamic>> _fetchPartyStats() async {
    final response = await supabase
        .from('runs')
        .select()
        .eq('partycode', widget.partyCode)
        .order('distance', ascending: false); // เรียงลำดับคนวิ่งเยอะสุดขึ้นก่อน
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
            return const Center(child: CircularProgressIndicator());

          if (!snapshot.data!.exists) {
            return const Center(child: Text("Data missing..."));
          }

          var partyData = snapshot.data!.data() as Map<String, dynamic>;
          var members = partyData['members'] as Map<String, dynamic>;

          // นับจำนวนคนที่วิ่งเสร็จแล้ว
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
                  ),
                ),
                Text(
                  "Room: ${widget.partyCode}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // ส่วนแสดงสถานะการรอเพื่อน
                if (!isAllFinished)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 15),
                        Text(
                          "Waiting for friends... ($finishedCount/${members.length})",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
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
                        return const Center(child: CircularProgressIndicator());
                      }

                      final stats = statsSnapshot.data ?? [];

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          // ดึง UID ของสมาชิกแต่ละคนมาเช็ค
                          String uid = members.keys.elementAt(index);
                          var memberInfo = members[uid];

                          // ค้นหาสถิติของคนนี้จาก Supabase List
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
                          );
                        },
                      );
                    },
                  ),
                ),

                // ปุ่มกลับหน้า Home พร้อมลบชื่อออกจากปาร์ตี้
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          // 🌟 สั่ง Leave Party เพื่อเคลียร์ชื่อตัวเองออก
                          await PartyService.leaveParty(
                            partyCode: widget.partyCode,
                            uid: user.uid,
                          );
                        }
                        // กลับไปหน้า Home และล้างหน้าจอเก่าออกให้หมด
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(
                            color: AppTheme.pureBlack,
                            width: 3,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "BACK TO HOME",
                        style: TextStyle(
                          color: AppTheme.pureBlack,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCard(String name, dynamic stat, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe ? AppTheme.primaryPink : AppTheme.pureBlack,
          width: isMe ? 4 : 2,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.backgroundCream,
            child: Icon(Icons.person, color: AppTheme.primaryRed),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? "$name (Me)" : name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (stat != null)
                  Text(
                    "Distance: ${stat['distance']} km | Pace: ${stat['pace']}",
                    style: const TextStyle(color: Colors.grey),
                  )
                else
                  const Text(
                    "Still running...",
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (stat != null)
            Text(
              "${stat['calories']} kcal",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryRed,
              ),
            ),
        ],
      ),
    );
  }
}
