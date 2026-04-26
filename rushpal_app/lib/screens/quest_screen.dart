import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:rushpal/theme/app_theme.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  bool _isLoading = true;
  String? _partyCode;

  double _personalDistance = 0;
  double _partyDistance = 0;
  bool _isPersonalClaimed = false;
  bool _isPartyClaimed = false;

  bool _isClaimingPersonal = false;
  bool _isClaimingParty = false;

  static const double _personalGoal = 1.0; // km
  static const double _partyGoal = 4.0;    // km

  String get _baseUrl => 'https://rushpal.onrender.com/api/runs';

  @override
  void initState() {
    super.initState();
    _loadPartyCodeAndFetch();
  }

  Future<void> _loadPartyCodeAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _partyCode = prefs.getString('partyCode');
    await _fetchQuestStatus();
  }

  Future<void> _fetchQuestStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      String url = '$_baseUrl/quest/$uid';
      if (_partyCode != null && _partyCode!.isNotEmpty) {
        url += '?partycode=$_partyCode';
      }

      debugPrint('[Quest] Fetching: $url');
      final response = await http.get(Uri.parse(url));
      debugPrint('[Quest] Response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _personalDistance = (data['personalDistance'] as num).toDouble();
          _partyDistance = (data['partyDistance'] as num).toDouble();
          _isPersonalClaimed = data['isPersonalClaimed'] ?? false;
          _isPartyClaimed = data['isPartyClaimed'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Quest fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _claimReward(String questType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      if (questType == 'personal') _isClaimingPersonal = true;
      else _isClaimingParty = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/claim'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': uid, 'quest_type': questType}),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final newLevel = data['newLevel'];
        final rewardG = data['rewardG'];

        // รีเฟรชสถานะเควส
        await _fetchQuestStatus();

        if (mounted) {
          _showRewardDialog(rewardG, 100, newLevel);
        }
      } else if (mounted) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'เกิดข้อผิดพลาด'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (questType == 'personal') _isClaimingPersonal = false;
          else _isClaimingParty = false;
        });
      }
    }
  }

  void _showRewardDialog(int gold, int exp, int newLevel) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.backgroundCream,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.pureBlack, width: 3),
                  boxShadow: const [BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 4), blurRadius: 0)],
                ),
                child: const Icon(Icons.star_rounded, color: AppTheme.pureBlack, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'รับรางวัลสำเร็จ!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.pureBlack,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _rewardChip(Icons.monetization_on_rounded, '+$gold G', Colors.amber),
                  const SizedBox(width: 12),
                  _rewardChip(Icons.bolt_rounded, '+$exp EXP', Colors.blue),
                ],
              ),
              if (newLevel > 1) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPink,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.pureBlack, width: 2),
                  ),
                  child: Text(
                    '🎉 Level Up! → Lv.$newLevel',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.pureBlack),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.pureBlack,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: AppTheme.primaryPink, offset: Offset(0, 4), blurRadius: 0)],
                  ),
                  child: const Center(
                    child: Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.pureBlack, width: 2),
                            boxShadow: const [BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 3), blurRadius: 0)],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.pureBlack),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPink,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.pureBlack, width: 1.5),
                              boxShadow: const [BoxShadow(color: AppTheme.pureBlack, offset: Offset(1, 2), blurRadius: 0)],
                            ),
                            child: const Text('DAILY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                          ),
                          const SizedBox(height: 2),
                          const Text('QUESTS', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.pureBlack)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _fetchQuestStatus,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.pureBlack, width: 2),
                            boxShadow: const [BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 3), blurRadius: 0)],
                          ),
                          child: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.pureBlack),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'เควสรีเซ็ตทุกเที่ยงคืน',
                    style: TextStyle(color: AppTheme.textLight.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 20),

                if (_isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.primaryPink)))
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Solo Quest
                          _QuestCard(
                            icon: Icons.directions_run_rounded,
                            title: 'Solo Runner',
                            description: 'วิ่งคนเดียว 1 กิโลเมตร',
                            currentValue: _personalDistance,
                            goalValue: _personalGoal,
                            unit: 'km',
                            rewardGold: 20,
                            rewardExp: 100,
                            isClaimed: _isPersonalClaimed,
                            isClaiming: _isClaimingPersonal,
                            onClaim: () => _claimReward('personal'),
                          ),

                          const SizedBox(height: 20),

                          // Party Quest
                          _QuestCard(
                            icon: Icons.groups_rounded,
                            title: 'Party Power',
                            description: 'ปาร์ตี้วิ่งรวมกัน 4 กิโลเมตร',
                            currentValue: _partyDistance,
                            goalValue: _partyGoal,
                            unit: 'km',
                            rewardGold: 20,
                            rewardExp: 100,
                            isClaimed: _isPartyClaimed,
                            isClaiming: _isClaimingParty,
                            onClaim: () => _claimReward('party'),
                            isPartyQuest: true,
                            isInParty: _partyCode != null && _partyCode!.isNotEmpty,
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double currentValue;
  final double goalValue;
  final String unit;
  final int rewardGold;
  final int rewardExp;
  final bool isClaimed;
  final bool isClaiming;
  final VoidCallback onClaim;
  final bool isPartyQuest;
  final bool isInParty;

  const _QuestCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.currentValue,
    required this.goalValue,
    required this.unit,
    required this.rewardGold,
    required this.rewardExp,
    required this.isClaimed,
    required this.isClaiming,
    required this.onClaim,
    this.isPartyQuest = false,
    this.isInParty = false,
  });

  bool get _isCompleted => currentValue >= goalValue;
  double get _progress => (currentValue / goalValue).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.pureBlack, width: 2.5),
        boxShadow: const [BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 5), blurRadius: 0)],
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isClaimed ? Colors.grey.shade200 : AppTheme.primaryPink,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.pureBlack, width: 2),
                    boxShadow: const [BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 3), blurRadius: 0)],
                  ),
                  child: Icon(icon, color: isClaimed ? Colors.grey : AppTheme.pureBlack, size: 28),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.pureBlack),
                          ),
                          if (isPartyQuest) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                              ),
                              child: const Text('PARTY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.deepPurple)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(description, style: TextStyle(fontSize: 13, color: AppTheme.textLight.withOpacity(0.7), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),

                // Status badge
                if (isClaimed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 1.5),
                    ),
                    child: const Text('DONE', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
          ),

          // Progress section
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isClaimed ? Colors.green : (_isCompleted ? Colors.green : AppTheme.primaryPink),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${currentValue.toStringAsFixed(2)} / ${goalValue.toStringAsFixed(1)} $unit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _isCompleted ? Colors.green : AppTheme.textLight,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Reward + Button row
                Row(
                  children: [
                    // Rewards
                    _miniReward(Icons.monetization_on_rounded, '+$rewardGold G', Colors.amber),
                    const SizedBox(width: 8),
                    _miniReward(Icons.bolt_rounded, '+$rewardExp EXP', Colors.blue),
                    const Spacer(),

                    // Claim button
                    if (isPartyQuest && !isInParty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade400, width: 1.5),
                        ),
                        child: Text('ต้องอยู่ใน Party', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
                      )
                    else
                      GestureDetector(
                        onTap: (!isClaimed && _isCompleted && !isClaiming) ? onClaim : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isClaimed
                                ? Colors.grey.shade200
                                : (_isCompleted ? AppTheme.pureBlack : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isClaimed ? Colors.grey.shade300 : (_isCompleted ? AppTheme.pureBlack : Colors.grey.shade300),
                              width: 2,
                            ),
                            boxShadow: (!isClaimed && _isCompleted)
                                ? const [BoxShadow(color: AppTheme.primaryPink, offset: Offset(0, 4), blurRadius: 0)]
                                : [],
                          ),
                          child: isClaiming
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  isClaimed ? 'รับแล้ว' : (_isCompleted ? 'รับรางวัล!' : 'ยังไม่ถึง'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: isClaimed ? Colors.grey : (_isCompleted ? Colors.white : Colors.grey),
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniReward(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textLight)),
      ],
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