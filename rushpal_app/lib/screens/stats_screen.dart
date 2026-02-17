import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading:
            false, // ซ่อนปุ่มย้อนกลับเพราะอยู่ใน Main Tab
        title: const Text(
          "Stats",
          style: TextStyle(
            color: Colors.black,
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
            // 1. ส่วนเลือกช่วงเวลา (Day, Week, Month)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeFilter("Day", false),
                _buildTimeFilter("Week", true), // Active
                _buildTimeFilter("Month", false),
              ],
            ),
            const SizedBox(height: 30),

            // 2. กราฟจำลอง (Bar Chart)
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

            // 3. ข้อมูลสรุป (Stat Cards)
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
              Colors.orange,
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
          color: isActive ? AppTheme.primaryRed : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black54,
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
          height: 150 * heightFactor, // ความสูงตาม factor
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withOpacity(0.8),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
                  color: Colors.grey,
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
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
