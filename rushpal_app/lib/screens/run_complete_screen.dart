import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class RunCompleteScreen extends StatelessWidget {
  final Duration duration;
  final double distance;
  final int calories;
  final List<List<LatLng>> routeSegments;
  final String? partyCode;

  const RunCompleteScreen({
    super.key,
    required this.duration,
    required this.distance,
    required this.calories,
    required this.routeSegments,
    this.partyCode,
  });

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  // Calculate pace (min/km) from real data
  String _formatPace() {
    if (distance <= 0 || duration.inSeconds <= 0) return '--:--';
    final paceSeconds = (duration.inSeconds / distance).round();
    final paceMin = paceSeconds ~/ 60;
    final paceSec = paceSeconds % 60;
    return '$paceMin:${paceSec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    LatLng? startPoint;
    if (routeSegments.isNotEmpty && routeSegments.first.isNotEmpty) {
      startPoint = routeSegments.first.first;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: Stack(
        children: [
          // Dot pattern background
          Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                'RUN COMPLETE',
                                style: TextStyle(
                                  color: AppTheme.pureBlack,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Mission\nAccomplished!',
                              style: TextStyle(
                                color: AppTheme.pureBlack,
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
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
                      border: Border.all(color: AppTheme.pureBlack, width: 2.5),
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
                                    color: AppTheme.textLight.withOpacity(0.3),
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
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                                  additionalOptions: {
                                    'accessToken':
                                        dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
                                    'id': 'mapbox/streets-v11',
                                  },
                                ),
                                for (var segment in routeSegments)
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

                  // ─── Main stats (real data only) ───
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.pureBlack, width: 2.5),
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
                          distance.toStringAsFixed(2),
                          'km',
                          Icons.straighten_rounded,
                        ),
                        _buildDivider(),
                        _buildBigStat(
                          'TIME',
                          _formatTime(duration),
                          '',
                          Icons.timer_rounded,
                        ),
                        _buildDivider(),
                        _buildBigStat(
                          'CALORIES',
                          '$calories',
                          'kcal',
                          Icons.local_fire_department_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Pace stat (calculated from real data) ───
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.pureBlack, width: 2.5),
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
                              _formatPace(),
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

                  // ─── Continue button ───
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () async {
                        showDialog(
                          context: ctx,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryPink,
                            ),
                          ),
                        );

                        // คอมเมนต์ส่วนนี้ทิ้งเพื่อป้องกันการบันทึกข้อมูลซ้ำ
                        // เนื่องจากมีการบันทึกลง Supabase ไปเรียบร้อยแล้วในหน้า start_run_screen
                        /*
                        double calculatedPace = distance > 0
                            ? (duration.inSeconds / 60) / distance
                            : 0.0;

                        final dbService = DatabaseService();
                        await dbService.saveNewRun(
                          distance: distance,
                          pace: calculatedPace,
                          seconds: duration.inSeconds,
                          calories: calories,
                        );
                        */

                        if (partyCode != null) {
                          await FirebaseFirestore.instance
                              .collection('parties')
                              .doc(partyCode)
                              .delete();
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          Navigator.popUntil(ctx, (route) => route.isFirst);
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
                            'CONTINUE',
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
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1.5,
      height: 52,
      color: AppTheme.pureBlack.withOpacity(0.12),
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
