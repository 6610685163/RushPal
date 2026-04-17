import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rushpal/theme/app_theme.dart';

class RunCompleteScreen extends StatelessWidget {
  final Duration duration;
  final double distance;
  final int calories;
  final List<List<LatLng>> routeSegments;

  const RunCompleteScreen({
    super.key,
    required this.duration,
    required this.distance,
    required this.calories,
    required this.routeSegments,
  });

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    LatLng? startPoint;
    if (routeSegments.isNotEmpty && routeSegments.first.isNotEmpty) {
      startPoint = routeSegments.first.first;
    }

    return Scaffold(
      backgroundColor: AppTheme.pureBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Summary",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.darkBlue.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryPink.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPink.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: startPoint == null
                    ? const Center(
                        child: Text(
                          "No Route Data",
                          style: TextStyle(color: Colors.white54),
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
                              'id': 'mapbox/dark-v11',
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
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.greenAccent,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),

            Text(
              "MISSION ACCOMPLISHED",
              style: TextStyle(
                color: AppTheme.primaryPink.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Morning Run",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.darkBlue.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBigStat("Distance", "$distance", "km"),
                  Container(width: 1, height: 50, color: Colors.white24),
                  _buildBigStat("Time", _formatTime(duration), ""),
                  Container(width: 1, height: 50, color: Colors.white24),
                  _buildBigStat("Calories", "$calories", "kcal"),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildDetailRow("Avg Pace", "6:30 /km", Icons.speed, Colors.blue),
            _buildDetailRow(
              "Elevation Gain",
              "120 m",
              Icons.terrain,
              Colors.greenAccent,
            ),
            _buildDetailRow(
              "Heart Rate",
              "145 bpm",
              Icons.favorite,
              AppTheme.primaryPink,
            ),

            const SizedBox(height: 50),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: AppTheme.primaryPink.withOpacity(0.4),
                ),
                child: const Text(
                  "CONTINUE",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigStat(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 2),
                child: Text(
                  unit,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBlue.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
