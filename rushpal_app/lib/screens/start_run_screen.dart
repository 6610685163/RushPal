import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'run_complete_screen.dart';

class StartRunScreen extends StatefulWidget {
  const StartRunScreen({super.key});

  @override
  State<StartRunScreen> createState() => _StartRunScreenState();
}

class _StartRunScreenState extends State<StartRunScreen> {
  bool isRunning = false;
  Duration duration = Duration.zero;
  Timer? timer;

  // ฟังก์ชันเริ่ม/หยุดเวลา (Pause/Resume)
  void _toggleRun() {
    setState(() {
      isRunning = !isRunning;
    });

    if (isRunning) {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          duration = Duration(seconds: duration.inSeconds + 1);
        });
      });
    } else {
      timer?.cancel();
    }
  }

  // ฟังก์ชันจบการวิ่ง (Stop)
  void _finishRun() {
    timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RunCompleteScreen(
          duration: duration,
          distance: 5.25, // ค่าสมมติ
          calories: 350, // ค่าสมมติ
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            if (duration.inSeconds > 0) {
              _finishRun();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          "Running",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. พื้นที่ Map (Placeholder)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 50, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      "Map Placeholder",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Stats & Controls
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Timer
                Text(
                  _formatTime(duration),
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Text("Total Time", style: TextStyle(color: Colors.grey)),

                const SizedBox(height: 30),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat("Distance", "5.25", "km"),
                    _buildStat("Pace", "6:30", "/km"),
                    _buildStat("Calories", "350", "kcal"),
                  ],
                ),

                const SizedBox(height: 40),

                // --- Controls Area ---
                if (duration.inSeconds == 0 && !isRunning)
                  // สถานะเริ่มต้น: ปุ่ม Start ปุ่มเดียวตรงกลาง
                  _buildLargeButton(Icons.play_arrow, _toggleRun)
                else
                  // สถานะกำลังวิ่ง/หยุดชั่วคราว
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ปุ่มเล็กด้านซ้าย (Pause/Resume)
                      _buildSmallButton(
                        isRunning ? Icons.pause : Icons.play_arrow,
                        _toggleRun,
                      ),

                      const SizedBox(width: 30), // ระยะห่าง
                      // ปุ่มใหญ่ตรงกลาง (Stop/Finish)
                      _buildLargeButton(Icons.stop, _finishRun),

                      // ✅ แก้ไข: เพิ่มพื้นที่ว่างด้านขวา เพื่อดุลน้ำหนักให้ปุ่มใหญ่อยู่กลางจอ
                      const SizedBox(width: 30), // ระยะห่างเท่าด้านซ้าย
                      const SizedBox(width: 60), // ขนาดเท่าปุ่มเล็ก (60px)
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: ปุ่มใหญ่ (Gradient) - ขนาด 100
  Widget _buildLargeButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRed,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 50),
      ),
    );
  }

  // Helper: ปุ่มเล็ก (สีเทา) - ขนาด 60
  Widget _buildSmallButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black54, size: 30),
      ),
    );
  }

  Widget _buildStat(String label, String value, String unit) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 2),
              child: Text(
                unit,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
