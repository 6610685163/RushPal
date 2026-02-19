import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';

class RunCompleteScreen extends StatelessWidget {
  final Duration duration;
  final double distance;
  final int calories;

  const RunCompleteScreen({
    super.key,
    required this.duration,
    required this.distance,
    required this.calories,
  });

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Summary",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Map Snapshot (Placeholder)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Text("Route Map", style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 30),

            // Date & Time
            Text(
              "Tuesday, 17 Feb 2026",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const Text(
              "Morning Run",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Big Stats Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBigStat("Distance", "$distance", "km"),
                Container(width: 1, height: 50, color: Colors.grey[300]),
                _buildBigStat("Time", _formatTime(duration), ""),
                Container(width: 1, height: 50, color: Colors.grey[300]),
                _buildBigStat("Calories", "$calories", "kcal"),
              ],
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            // Detailed Stats
            _buildDetailRow("Avg Pace", "6:30 /km", Icons.speed, Colors.blue),
            _buildDetailRow(
              "Elevation Gain",
              "120 m",
              Icons.terrain,
              Colors.green,
            ),
            _buildDetailRow(
              "Heart Rate",
              "145 bpm",
              Icons.favorite,
              Colors.red,
            ),

            const SizedBox(height: 50),

            // Back Home Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // กลับไปหน้าแรกสุด (Home)
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: AppTheme.primaryRed.withOpacity(0.4),
                ),
                child: const Text(
                  "Back to Home",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
            color: Colors.grey,
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 2),
                child: Text(
                  unit,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
