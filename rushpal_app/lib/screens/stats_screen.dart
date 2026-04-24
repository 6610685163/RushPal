import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Stats",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeFilter("Day", false),
                _buildTimeFilter("Week", true),
                _buildTimeFilter("Month", false),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar("Mon", 0.4),
                  _buildBar("Tue", 0.6),
                  _buildBar("Wed", 0.3),
                  _buildBar("Thu", 0.8),
                  _buildBar("Fri", 0.5),
                  _buildBar("Sat", 0.9),
                  _buildBar("Sun", 0.7),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildStatCard(
              "Distance",
              "999.9 km",
              Icons.directions_run,
              Colors.blue,
            ),
            const SizedBox(height: 15),
            _buildStatCard(
              "Time",
              "180.2 hrs",
              Icons.access_time,
              Colors.purple,
            ),
            const SizedBox(height: 15),
            _buildStatCard(
              "Calories burned",
              "2,000 cal",
              Icons.local_fire_department,
              AppTheme.primaryPink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilter(String text, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryPink
              : AppTheme.darkBlue.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.white : Colors.white24),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String day, double heightFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: 150 * heightFactor,
          decoration: BoxDecoration(
            color: AppTheme.primaryPink,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPink.withOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(fontSize: 12, color: Colors.white70)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkBlue.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
