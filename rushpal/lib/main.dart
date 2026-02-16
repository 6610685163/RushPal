import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:geolocator/geolocator.dart'; // เพิ่มตัวนี้

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // ตัวแปรสำหรับเก็บค่าพิกัด
  String locationMessage = "กดปุ่มเพื่อเริ่มจับตำแหน่ง";
  double speed = 0.0;

  // ฟังก์ชันขออนุญาตและดึงพิกัด
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. เช็คว่าเปิด GPS หรือยัง
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => locationMessage = "กรุณาเปิด GPS ด้วยครับ");
      return;
    }

    // 2. ขออนุญาตเข้าถึงตำแหน่ง
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => locationMessage = "ไม่ได้รับอนุญาตให้ใช้ GPS");
        return;
      }
    }

    // 3. เริ่มจับตำแหน่งแบบ Real-time
    setState(() => locationMessage = "กำลังจับสัญญาณ...");

    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        // อัปเดตข้อความบนหน้าจอ
        locationMessage =
            "Lat: ${position.latitude.toStringAsFixed(4)}\n"
            "Long: ${position.longitude.toStringAsFixed(4)}";

        // ความเร็ว (หน่วยเป็น เมตร/วินาที -> แปลงเป็น กม./ชม. คูณ 3.6)
        speed = position.speed * 3.6;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('RushPal GPS Test'),
          backgroundColor: Colors.redAccent, // เปลี่ยนเป็นสีแดงตามธีมหลัก
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ส่วนโชว์โมเดล 3D (เหมือนเดิม)
              SizedBox(
                height: 350,
                width: double.infinity,
                child: ModelViewer(
                  src:
                      'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
                  alt: "A 3D model of an astronaut",
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: const Color.fromARGB(255, 209, 128, 128),
                  // ถ้าความเร็วมากกว่า 1 กม./ชม. ให้เล่น Animation วิ่ง (อนาคต)
                  animationName: speed > 1.0 ? "Run" : "Idle",
                ),
              ),

              const SizedBox(height: 20),

              // ส่วนโชว์ข้อมูล GPS
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Text(
                      "ความเร็ว: ${speed.toStringAsFixed(1)} km/h",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange, // สีเหลืองทอง
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      locationMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ปุ่มกดเริ่ม
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.play_arrow),
                label: const Text("เปิด GPS"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
