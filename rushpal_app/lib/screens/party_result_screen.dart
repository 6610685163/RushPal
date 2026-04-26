import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/services/party_service.dart';
import 'package:rushpal/widgets/user_avatar.dart';

class PartyResultScreen extends StatefulWidget {
  final String partyCode;
  final Duration duration;
  final double distance;
  final int calories;
  final List<List<LatLng>> routeSegments;

  const PartyResultScreen({
    super.key,
    required this.partyCode,
    required this.duration,
    required this.distance,
    required this.calories,
    required this.routeSegments,
  });

  @override
  State<PartyResultScreen> createState() => _PartyResultScreenState();
}

class _PartyResultScreenState extends State<PartyResultScreen> {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> _fetchPartyStats() async {
    // รอ 1 วินาทีให้ backend บันทึกลง Supabase เสร็จก่อน
    await Future.delayed(const Duration(seconds: 1));
    final response = await supabase
        .from('runs')
        .select()
        .eq('partycode', widget.partyCode)
        .order('distance', ascending: false);
    return response as List<dynamic>;
  }

  // ฟังก์ชันคำนวณสถิติของตัวเอง
  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  String _formatMyPace() {
    if (widget.distance <= 0 || widget.duration.inSeconds <= 0) return '--:--';
    final paceSeconds = (widget.duration.inSeconds / widget.distance).round();
    final paceMin = paceSeconds ~/ 60;
    final paceSec = paceSeconds % 60;
    return '$paceMin:${paceSec.toString().padLeft(2, '0')}';
  }

  // ฟังก์ชันคำนวณสถิติของคนในปาร์ตี้ (จาก Supabase)
  String _formatSupabasePace(dynamic paceRaw) {
    double pace = (paceRaw as num?)?.toDouble() ?? 0.0;
    if (pace <= 0) return '--:--';
    int minutes = pace.floor();
    int seconds = ((pace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSupabaseDuration(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    LatLng? startPoint;
    if (widget.routeSegments.isNotEmpty &&
        widget.routeSegments.first.isNotEmpty) {
      startPoint = widget.routeSegments.first.first;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: Stack(
        children: [
          // Dot pattern background
          Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),

          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('parties')
                  .doc(widget.partyCode)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryPink,
                    ),
                  );
                }

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

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Header ───
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryPink,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.pureBlack,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppTheme.pureBlack,
                                        blurRadius: 0,
                                        offset: Offset(2, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'PARTY RESULT',
                                    style: TextStyle(
                                      color: AppTheme.pureBlack,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ROOM: ${widget.partyCode}',
                                  style: const TextStyle(
                                    color: AppTheme.pureBlack,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 28,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Trophy icon
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPink,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.pureBlack,
                                width: 2.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppTheme.pureBlack,
                                  blurRadius: 0,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: AppTheme.pureBlack,
                              size: 38,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ─── Map ───
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.pureBlack,
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.pureBlack,
                              blurRadius: 0,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17.5),
                          child: startPoint == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.map_outlined,
                                        size: 40,
                                        color: AppTheme.textLight.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No route data',
                                        style: TextStyle(
                                          color: AppTheme.textLight.withOpacity(
                                            0.5,
                                          ),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : FlutterMap(
                                  options: MapOptions(
                                    initialCenter: startPoint,
                                    initialZoom: 15.0,
                                    interactionOptions:
                                        const InteractionOptions(
                                          flags: InteractiveFlag.none,
                                        ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                                      additionalOptions: {
                                        'accessToken':
                                            dotenv.env['MAPBOX_ACCESS_TOKEN'] ??
                                            '',
                                        'id': 'mapbox/streets-v11',
                                      },
                                    ),
                                    for (var segment in widget.routeSegments)
                                      if (segment.length > 1)
                                        PolylineLayer(
                                          polylines: [
                                            Polyline(
                                              points: segment,
                                              strokeWidth: 5.0,
                                              color: AppTheme.primaryPink,
                                            ),
                                          ],
                                        ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: startPoint,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryPink,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppTheme.pureBlack,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.place_rounded,
                                              color: AppTheme.pureBlack,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ─── Main stats (My Run) ───
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 22,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.pureBlack,
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.pureBlack,
                              blurRadius: 0,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildBigStat(
                              'DISTANCE',
                              widget.distance.toStringAsFixed(2),
                              'km',
                              Icons.straighten_rounded,
                            ),
                            _buildDivider(),
                            _buildBigStat(
                              'TIME',
                              _formatTime(widget.duration),
                              '',
                              Icons.timer_rounded,
                            ),
                            _buildDivider(),
                            _buildBigStat(
                              'CALORIES',
                              '${widget.calories}',
                              'kcal',
                              Icons.local_fire_department_rounded,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ─── Pace stat (My Run) ───
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.pureBlack,
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.pureBlack,
                              blurRadius: 0,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.pureBlack,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.speed_rounded,
                                color: AppTheme.primaryPink,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AVG PACE',
                                  style: TextStyle(
                                    color: AppTheme.pureBlack,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatMyPace(),
                                  style: const TextStyle(
                                    color: AppTheme.pureBlack,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Text(
                              'min/km',
                              style: TextStyle(
                                color: AppTheme.pureBlack,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        "PARTY LEADERBOARD",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.pureBlack,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // สถานะรอเพื่อน
                      if (!isAllFinished)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.orange,
                                offset: Offset(0, 4),
                              ),
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

                      // รายชื่อและสถิติเพื่อนในตี้ (ดึงใหม่ทุกครั้งที่ Firestore เปลี่ยน)
                      FutureBuilder<List<dynamic>>(
                        future: _fetchPartyStats(),
                        // key ผูกกับ finishedCount ทำให้ rebuild + ดึงข้อมูลใหม่ทุกครั้งที่มีคนวิ่งเสร็จ
                        key: ValueKey(finishedCount),
                        builder: (context, statsSnapshot) {
                          if (statsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryPink,
                                ),
                              ),
                            );
                          }

                          final stats = statsSnapshot.data ?? [];

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              String uid = members.keys.elementAt(index);
                              var memberInfo = members[uid];
                              final currentUid = FirebaseAuth.instance.currentUser?.uid;
                              final isMe = uid == currentUid;

                              int statIndex = stats.indexWhere(
                                (s) => s['user_id'] == uid,
                              );
                              // ถ้าเป็นตัวเอง ใช้ข้อมูลจาก widget โดยตรงเลย (ไม่ต้องรอ Supabase)
                              dynamic userStat;
                              if (isMe) {
                                userStat = {
                                  'distance': widget.distance,
                                  'duration_seconds': widget.duration.inSeconds,
                                  'calories': widget.calories,
                                  'pace': widget.distance > 0
                                      ? (widget.duration.inSeconds / 60.0) / widget.distance
                                      : 0.0,
                                };
                              } else {
                                userStat = statIndex != -1 ? stats[statIndex] : null;
                              }

                              return _buildResultCard(
                                memberInfo['username'] ?? "Unknown",
                                userStat,
                                isMe,
                                uid,
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      // ─── Back Button ───
                      GestureDetector(
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await PartyService.leaveParty(
                              partyCode: widget.partyCode,
                              uid: user.uid,
                            );
                          }
                          if (context.mounted) {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.pureBlack,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.pureBlack,
                              width: 2.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppTheme.primaryPink,
                                blurRadius: 0,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'BACK TO HOME',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigStat(String label, String value, String unit, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryPink, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textLight.withOpacity(0.6),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.pureBlack,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: TextStyle(
              color: AppTheme.textLight.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1.5,
      height: 52,
      color: AppTheme.pureBlack.withOpacity(0.12),
    );
  }

  Widget _buildResultCard(String name, dynamic stat, bool isMe, String uid) {
    final double distance = stat != null
        ? (stat['distance'] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final int durationSec = stat != null
        ? (stat['duration_seconds'] as num?)?.toInt() ?? 0
        : 0;
    final int calories = stat != null
        ? (stat['calories'] as num?)?.toInt() ?? 0
        : 0;
    final String pace = stat != null
        ? _formatSupabasePace(stat['pace'])
        : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
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
      child: Column(
        children: [
          // Name row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                      var userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      imageUrl = userData['profileImageUrl'];
                    }
                    return UserAvatar(imageUrl: imageUrl, radius: 24);
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isMe ? "$name (Me)" : name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: AppTheme.pureBlack,
                    ),
                  ),
                ),
                if (stat == null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange, width: 1.5),
                    ),
                    child: const Text(
                      "Running...",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Stats row (เฉพาะคนที่วิ่งเสร็จแล้ว)
          if (stat != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppTheme.primaryPink.withOpacity(0.12)
                    : AppTheme.backgroundCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.pureBlack.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildStatCell(
                    distance.toStringAsFixed(2),
                    'km',
                    'DIST',
                    Icons.straighten_rounded,
                  ),
                  _buildCellDivider(),
                  _buildStatCell(
                    _formatSupabaseDuration(durationSec),
                    '',
                    'TIME',
                    Icons.timer_rounded,
                  ),
                  _buildCellDivider(),
                  _buildStatCell(pace, '/km', 'PACE', Icons.speed_rounded),
                  _buildCellDivider(),
                  _buildStatCell(
                    '$calories',
                    'kcal',
                    'CALS',
                    Icons.local_fire_department_rounded,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCell(
    String value,
    String unit,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryPink, size: 14),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.pureBlack,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 1),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: AppTheme.pureBlack.withOpacity(0.4),
                      fontWeight: FontWeight.w700,
                      fontSize: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textLight.withOpacity(0.45),
              fontWeight: FontWeight.w700,
              fontSize: 8,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppTheme.pureBlack.withOpacity(0.08),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.pureBlack.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}