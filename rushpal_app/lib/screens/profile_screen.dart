import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';
import '../services/database_service.dart';
import 'package:rushpal/widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = "Loading...";
  int level = 1;
  int friendsCount = 0;
  int trophiesCount = 0;
  String? profileImageUrl;

  bool _isLoadingStats = true;
  double totalDistance = 0.0;
  String bestPace = "0:00 /km";
  double totalTimeHrs = 0.0;
  int totalCalories = 0;

  bool _isLoadingHistory = true;
  List<Map<String, dynamic>> _runs = [];

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _listenToUserData();
    _fetchTotalStats();
    _fetchRunHistory();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

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
                level = data['level'] ?? 1;
                final friendsList = data['friends'] as List<dynamic>? ?? [];
                friendsCount = friendsList.length;
                profileImageUrl = data['profileImageUrl'];
              });
            }
          }
        });
  }

  Future<void> _fetchTotalStats() async {
    final db = DatabaseService();
    final stats = await db.fetchUserStats('all');
    if (stats != null && mounted) {
      setState(() {
        totalDistance = (stats['total_distance'] as num?)?.toDouble() ?? 0.0;
        int totalSeconds = (stats['total_time_seconds'] as num?)?.toInt() ?? 0;
        totalCalories = (stats['total_calories'] as num?)?.toInt() ?? 0;
        totalTimeHrs = totalSeconds / 3600.0;
        double? bestPaceDecimal = (stats['best_pace'] as num?)?.toDouble();
        if (bestPaceDecimal != null && bestPaceDecimal > 0) {
          int minutes = bestPaceDecimal.floor();
          int seconds = ((bestPaceDecimal - minutes) * 60).round();
          bestPace = "$minutes:${seconds.toString().padLeft(2, '0')} /km";
        } else {
          bestPace = "0:00 /km";
        }
        _isLoadingStats = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingStats = false);
    }
  }

  // ดึงประวัติจาก Supabase ตาราง runs โดยตรง (เหมือนกับที่ start_run_screen บันทึก)
  Future<void> _fetchRunHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoadingHistory = false);
        return;
      }

      final response = await _supabase
          .from('runs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _runs = List<Map<String, dynamic>>.from(response as List);
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching run history: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.pureBlack, width: 3),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.pureBlack, width: 2),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppTheme.primaryRed,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'CLEAR HISTORY?',
                style: TextStyle(
                  color: AppTheme.pureBlack,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ประวัติการวิ่งทั้งหมดจะถูกลบถาวร\nไม่สามารถกู้คืนได้',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textLight.withOpacity(0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.pureBlack,
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.pureBlack,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              color: AppTheme.pureBlack,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _clearHistory();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.pureBlack,
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.pureBlack,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'DELETE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
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
  }

  Future<void> _clearHistory() async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      await _supabase.from('runs').delete().eq('user_id', userId);
      if (mounted) setState(() => _runs = []);
    } catch (e) {
      print('❌ Error clearing history: $e');
    }
  }

  String _formatDuration(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(dynamic paceRaw) {
    double pace = (paceRaw as num?)?.toDouble() ?? 0.0;
    if (pace <= 0) return '--:--';
    int minutes = pace.floor();
    int seconds = ((pace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '--';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return '--';
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '--';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.pureBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "PROFILE",
          style: TextStyle(
            color: AppTheme.pureBlack,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryPink,
        onRefresh: () async {
          await _fetchRunHistory();
          await _fetchTotalStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Profile Image & Level
              Center(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: AppTheme.pureBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.pureBlack,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: UserAvatar(imageUrl: profileImageUrl, radius: 50),
                    ),
                    Positioned(
                      bottom: -14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.pureBlack,
                            width: 3,
                          ),
                        ),
                        child: Text(
                          "Lv. $level",
                          style: const TextStyle(
                            color: AppTheme.pureBlack,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.pureBlack,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCountItem("Friends", friendsCount.toString()),
                  Container(
                    height: 40,
                    width: 3,
                    color: AppTheme.pureBlack.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                  ),
                  _buildCountItem("Trophies", trophiesCount.toString()),
                ],
              ),
              const SizedBox(height: 25),

              // Edit Profile Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppTheme.pureBlack, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: AppTheme.pureBlack,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "EDIT ACCOUNT",
                        style: TextStyle(
                          color: AppTheme.pureBlack,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ─── RUN HISTORY HEADER ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.pureBlack, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.pureBlack,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 14,
                            color: AppTheme.pureBlack,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'RUN HISTORY',
                            style: TextStyle(
                              color: AppTheme.pureBlack,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: AppTheme.pureBlack.withOpacity(0.08),
                      ),
                    ),
                    if (_runs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '${_runs.length} runs',
                          style: TextStyle(
                            color: AppTheme.textLight.withOpacity(0.5),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_runs.isNotEmpty)
                      GestureDetector(
                        onTap: _confirmClearHistory,
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.pureBlack,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppTheme.pureBlack,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 12,
                                color: AppTheme.primaryRed,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'CLEAR',
                                style: TextStyle(
                                  color: AppTheme.primaryRed,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // History List
              if (_isLoadingHistory)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryPink,
                    ),
                  ),
                )
              else if (_runs.isEmpty)
                _buildEmptyHistory()
              else
                ..._runs.asMap().entries.map(
                  (e) => _buildRunCard(e.value, e.key),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.pureBlack, width: 2.5),
          boxShadow: const [
            BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.directions_run_rounded,
              size: 40,
              color: AppTheme.pureBlack.withOpacity(0.2),
            ),
            const SizedBox(height: 10),
            Text(
              'No runs yet',
              style: TextStyle(
                color: AppTheme.textLight.withOpacity(0.5),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunCard(Map<String, dynamic> run, int index) {
    final double distance = (run['distance'] as num?)?.toDouble() ?? 0.0;
    final int durationSec = (run['duration_seconds'] as num?)?.toInt() ?? 0;
    final int calories = (run['calories'] as num?)?.toInt() ?? 0;
    final String date = _formatDate(run['created_at']);
    final String time = _formatTime(run['created_at']);
    final String pace = _formatPace(run['pace']);
    final bool isPartyRun = run['partycode'] != null;

    final List<Color> accents = [
      AppTheme.primaryPink,
      const Color(0xFFB2EBF2),
      const Color(0xFFDCEDC8),
      const Color(0xFFFFCCBC),
      const Color(0xFFE1BEE7),
    ];
    final Color accent = accents[index % accents.length];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.pureBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              border: Border(
                bottom: BorderSide(color: AppTheme.pureBlack, width: 2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.pureBlack,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_run_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  date,
                  style: const TextStyle(
                    color: AppTheme.pureBlack,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: TextStyle(
                    color: AppTheme.pureBlack.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                // Badge party run
                if (isPartyRun)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.pureBlack,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.group_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'PARTY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(
                  '#${_runs.length - index}',
                  style: TextStyle(
                    color: AppTheme.pureBlack.withOpacity(0.4),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _buildStatItem(
                  distance.toStringAsFixed(2),
                  'km',
                  'DIST',
                  Icons.straighten_rounded,
                ),
                _buildDivider(),
                _buildStatItem(
                  _formatDuration(durationSec),
                  '',
                  'TIME',
                  Icons.timer_rounded,
                ),
                _buildDivider(),
                _buildStatItem(pace, '/km', 'PACE', Icons.speed_rounded),
                _buildDivider(),
                _buildStatItem(
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

  Widget _buildStatItem(
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppTheme.pureBlack.withOpacity(0.08),
    );
  }

  Widget _buildCountItem(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.pureBlack,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.pureBlack,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyItem(String name, Color color) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.pureBlack, width: 3),
              boxShadow: const [
                BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 3)),
              ],
            ),
            child: Icon(Icons.emoji_events_rounded, color: color, size: 35),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppTheme.pureBlack,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
