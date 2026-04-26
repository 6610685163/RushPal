import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import '../services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedTimeFrame = 'weekly';
  bool _isLoading = true;

  double _totalDistance = 0.0;
  int _totalSeconds = 0;
  int _totalCalories = 0;

  List<double> _chartData = [];
  double _maxChartValue = 1.0;

  @override
  void initState() {
    super.initState();
    _fetchStatsData(_selectedTimeFrame);
  }

  Future<void> _fetchStatsData(String timeFrame) async {
    setState(() {
      _isLoading = true;
      _selectedTimeFrame = timeFrame;
      _chartData = [];
    });

    final db = DatabaseService();
    final stats = await db.fetchUserStats(timeFrame);

    print("📊 ข้อมูลที่ได้จาก Backend: $stats");

    if (stats != null && mounted) {
      setState(() {
        _totalDistance = (stats['total_distance'] as num?)?.toDouble() ?? 0.0;
        _totalSeconds = (stats['total_time_seconds'] as num?)?.toInt() ?? 0;
        _totalCalories = (stats['total_calories'] as num?)?.toInt() ?? 0;

        if (stats['chart_data'] != null) {
          List<dynamic> rawData = stats['chart_data'];
          _chartData = rawData.map((e) => (e as num).toDouble()).toList();

          // หาค่าที่สูงที่สุดเพื่อเป็นเพดานกราฟ (กัน Error หารด้วย 0)
          if (_chartData.isNotEmpty) {
            _maxChartValue = _chartData.reduce(
              (curr, next) => curr > next ? curr : next,
            );
          }
          if (_maxChartValue == 0) _maxChartValue = 1.0;
        } else {
          _chartData = []; // ถ้าไม่มีข้อมูลให้เป็น Array ว่าง
        }

        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _totalDistance = 0.0;
        _totalSeconds = 0;
        _totalCalories = 0;
      });
    }
  }

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
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "MY STATS",
          style: TextStyle(
            color: AppTheme.pureBlack,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนตัวกรองเวลา
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeFilter("DAY", 'daily'),
                _buildTimeFilter("WEEK", 'weekly'),
                _buildTimeFilter("MONTH", 'monthly'),
              ],
            ),
            const SizedBox(height: 40),

            // 🌟 กราฟเส้น (Line Chart) พร้อมรายละเอียด
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // เพิ่มหัวข้อกราฟ
                const Padding(
                  padding: EdgeInsets.only(left: 10, bottom: 20),
                  child: Text(
                    "DISTANCE PROGRESS (KM)",
                    style: TextStyle(
                      color: AppTheme.pureBlack, // เปลี่ยนเป็นสีดำให้เข้ากับธีม
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: _chartData.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryPink,
                          ),
                        ) // โชว์วงกลมโหลดรอ
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: _maxChartValue > 0
                                  ? _maxChartValue / 4
                                  : 1,
                              getDrawingHorizontalLine: (value) => const FlLine(
                                color: Colors
                                    .black12, // 🌟 เปลี่ยนเส้นประพื้นหลังเป็นสีเข้ม
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              // ตัวเลขแกน Y (ระยะทาง)
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const SizedBox();
                                    return Text(
                                      value.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: AppTheme
                                            .pureBlack, // 🌟 เปลี่ยนสีตัวอักษรเป็นสีดำ
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // ข้อความแกน X (เวลา/วัน)
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: _selectedTimeFrame == 'monthly'
                                      ? 5
                                      : (_selectedTimeFrame == 'daily' ? 4 : 1),
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index < 0 ||
                                        index >= _chartData.length) {
                                      return const SizedBox();
                                    }

                                    String label = "";
                                    if (_selectedTimeFrame == 'weekly') {
                                      const days = [
                                        "Mon",
                                        "Tue",
                                        "Wed",
                                        "Thu",
                                        "Fri",
                                        "Sat",
                                        "Sun",
                                      ];
                                      // 🌟 ป้องกัน Error Index Out of Bounds
                                      label = index < days.length
                                          ? days[index]
                                          : "";
                                    } else if (_selectedTimeFrame ==
                                        'monthly') {
                                      label = "${index + 1}";
                                    } else if (_selectedTimeFrame == 'daily') {
                                      label = "$index:00";
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                          color: AppTheme
                                              .pureBlack, // 🌟 เปลี่ยนสีตัวอักษรเป็นสีดำ
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: false,
                            ), // ปิดกรอบกราฟ
                            minX: 0,
                            maxX: (_chartData.length - 1).toDouble(),
                            minY: 0,
                            maxY:
                                _maxChartValue *
                                1.2, // เผื่อที่ว่างด้านบนนิดนึงให้ดูกว้าง
                            // 🌟 การตั้งค่าเส้นกราฟ
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(_chartData.length, (
                                  index,
                                ) {
                                  return FlSpot(
                                    index.toDouble(),
                                    _chartData[index],
                                  );
                                }),
                                isCurved: true, // ทำให้เส้นโค้งมนสมูทๆ
                                color: AppTheme.primaryPink, // ใช้สีชมพูธีมแอป
                                barWidth: 4, // ความหนาของเส้น
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppTheme.primaryPink.withOpacity(
                                    0.2,
                                  ), // สีเงา
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ส่วนแสดงข้อมูลตัวเลข
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
                        Icons.directions_run_rounded,
                        Colors.blue,
                      ),
                      const SizedBox(height: 15),
                      _buildStatCard(
                        "Time",
                        _formatTime(_totalSeconds),
                        Icons.access_time_rounded,
                        Colors.purple,
                      ),
                      const SizedBox(height: 15),
                      _buildStatCard(
                        "Calories burned",
                        "$_totalCalories cal",
                        Icons.local_fire_department_rounded,
                        AppTheme.primaryRed,
                      ),
                    ],
                  ),
            const SizedBox(height: 80), // เผื่อที่ให้ Bottom Nav
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilter(String text, String timeFrameValue) {
    bool isActive = _selectedTimeFrame == timeFrameValue;

    return GestureDetector(
      onTap: () {
        if (!isActive) _fetchStatsData(timeFrameValue);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryPink : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.pureBlack, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppTheme.pureBlack,
              offset: isActive ? const Offset(0, 4) : const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? AppTheme.pureBlack : Colors.grey.shade600,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
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
          width: 18,
          height: 150 * heightFactor,
          decoration: BoxDecoration(
            color: AppTheme.primaryPink,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.pureBlack, width: 2),
            boxShadow: const [
              BoxShadow(color: AppTheme.pureBlack, offset: Offset(2, 2)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          day,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.pureBlack, width: 3),
        boxShadow: const [
          BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
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
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.pureBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
