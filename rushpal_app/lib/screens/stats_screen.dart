import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import '../services/database_service.dart'; // 👈 อย่าลืม import service ของเรา

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // ตัวแปรเก็บสถานะ
  String _selectedTimeFrame =
      'weekly'; // ค่าเริ่มต้นคือรายสัปดาห์ ('daily', 'weekly', 'monthly')
  bool _isLoading = true;

  // ตัวแปรเก็บข้อมูลสถิติ
  double _totalDistance = 0.0;
  int _totalSeconds = 0;
  int _totalCalories = 0;

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลทันทีที่เปิดหน้านี้ขึ้นมา
    _fetchStatsData(_selectedTimeFrame);
  }

  // ฟังก์ชันดึงข้อมูลจาก Backend
  Future<void> _fetchStatsData(String timeFrame) async {
    setState(() {
      _isLoading = true; // เปิดวงกลมโหลด
      _selectedTimeFrame = timeFrame; // อัปเดตปุ่มที่ถูกเลือก
    });

    final db = DatabaseService();
    final stats = await db.fetchUserStats(timeFrame);

    if (stats != null && mounted) {
      setState(() {
        // อัปเดตค่าที่ได้จาก Backend ลงไปในตัวแปร
        _totalDistance = (stats['total_distance'] as num?)?.toDouble() ?? 0.0;
        _totalSeconds = (stats['total_time_seconds'] as num?)?.toInt() ?? 0;
        _totalCalories = (stats['total_calories'] as num?)?.toInt() ?? 0;
        _isLoading = false; // ปิดโหลด
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        // กรณีดึงข้อมูลไม่ได้ ให้รีเซ็ตเป็น 0
        _totalDistance = 0.0;
        _totalSeconds = 0;
        _totalCalories = 0;
      });
    }
  }

  // ฟังก์ชันช่วยแปลงวินาที เป็น ชั่วโมง/นาที ให้อ่านง่ายๆ
  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else {
      return "${minutes}m";
    }
  }

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
            // ส่วนตัวกรองเวลา (กดได้)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeFilter("Day", 'daily'),
                _buildTimeFilter("Week", 'weekly'),
                _buildTimeFilter("Month", 'monthly'),
              ],
            ),
            const SizedBox(height: 30),

            // กราฟแท่ง (ตรงนี้ยังเป็น UI จำลองไว้ก่อนนะครับ เพราะ Backend ส่งมายอดรวม)
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

            // ส่วนแสดงข้อมูลตัวเลข
            // ถ้ากำลังโหลดข้อมูลอยู่ ให้โชว์วงกลมหมุนๆ แทน
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryPink,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _buildStatCard(
                        "Distance",
                        "${_totalDistance.toStringAsFixed(2)} km",
                        Icons.directions_run,
                        Colors.blue,
                      ),
                      const SizedBox(height: 15),
                      _buildStatCard(
                        "Time",
                        _formatTime(_totalSeconds),
                        Icons.access_time,
                        Colors.purple,
                      ),
                      const SizedBox(height: 15),
                      _buildStatCard(
                        "Calories burned",
                        "$_totalCalories cal", // แปลงตัวเลขตรงๆ ได้เลย
                        Icons.local_fire_department,
                        AppTheme.primaryPink,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // แก้ไขปุ่มฟิลเตอร์ให้กดได้ด้วย GestureDetector
  Widget _buildTimeFilter(String text, String timeFrameValue) {
    bool isActive = _selectedTimeFrame == timeFrameValue;

    return GestureDetector(
      onTap: () {
        // เมื่อกดปุ่ม ให้เรียกฟังก์ชันโหลดข้อมูลใหม่พร้อมกับเวลาที่เลือก
        if (!isActive) {
          _fetchStatsData(timeFrameValue);
        }
      },
      child: Padding(
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
