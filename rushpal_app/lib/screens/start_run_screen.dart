import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'run_complete_screen.dart';

class StartRunScreen extends StatefulWidget {
  const StartRunScreen({super.key});

  @override
  State<StartRunScreen> createState() => _StartRunScreenState();
}

class _StartRunScreenState extends State<StartRunScreen> {
  // === 📍 ตัวแปรแผนที่ (จากโค้ดของคุณ) ===
  final String mapboxAccessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  final String mapStyleId = 'mapbox/dark-v11';
  final MapController _mapController = MapController();
  List<List<LatLng>> routeSegments = [];
  LatLng? currentLocation;
  bool _isMapReady = false;

  // === ⏱️ ตัวแปรสถิติการวิ่ง ===
  double totalDistance = 0.0;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool hasStarted = false; // เช็คว่าเคยกดปุ่ม Start ใหญ่ไปหรือยัง

  @override
  void initState() {
    super.initState();
    _initLocation();

    // อัปเดต UI (เวลา) ทุกๆ 1 วินาที
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stopwatch.isRunning) {
        setState(() {}); // รีเฟรชหน้าจอให้เวลาเดิน
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // === ลอจิก GPS และ Map ===
  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position position) {
    if (!mounted) return;

    setState(() {
      LatLng newPos = LatLng(position.latitude, position.longitude);

      if (_stopwatch.isRunning) {
        if (routeSegments.isEmpty) {
          routeSegments.add([newPos]);
        }

        List<LatLng> currentSegment = routeSegments.last;
        if (currentSegment.isNotEmpty) {
          double dist = Geolocator.distanceBetween(
            currentSegment.last.latitude,
            currentSegment.last.longitude,
            newPos.latitude,
            newPos.longitude,
          );

          if (dist > 50) {
            currentLocation = newPos;
            if (_isMapReady) _mapController.move(newPos, 17.0);
            return;
          }

          totalDistance += dist;
          currentSegment.add(newPos);
        } else {
          currentSegment.add(newPos);
        }
      }

      currentLocation = newPos;
      if (_isMapReady) {
        _mapController.move(newPos, 17.0);
      }
    });
  }

  // === ลอจิกคำนวณสถิติ ===
  String _formatPace() {
    if (totalDistance == 0) return "0:00";
    double distanceKm = totalDistance / 1000;
    double timeMinutes =
        _stopwatch.elapsed.inMinutes +
        (_stopwatch.elapsed.inSeconds % 60) / 60.0;
    double paceDecimal = timeMinutes / distanceKm;

    int minutes = paceDecimal.floor();
    int seconds = ((paceDecimal - minutes) * 60).round();
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  // === ลอจิกปุ่มกด ===
  void _toggleRun() {
    setState(() {
      hasStarted = true;
      if (_stopwatch.isRunning) {
        _stopwatch.stop(); // กด Pause
      } else {
        _stopwatch.start(); // กด Resume
        routeSegments.add([]); // ตัดเส้นใหม่
      }
    });
  }

  void _finishRun() {
    _stopwatch.stop();
    _timer?.cancel();

    int calories = (totalDistance / 1000 * 60).toInt(); // สูตรจำลอง

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RunCompleteScreen(
          duration: _stopwatch.elapsed,
          distance: double.parse((totalDistance / 1000).toStringAsFixed(2)),
          calories: calories,
          routeSegments: routeSegments,
        ),
      ),
    );
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
            if (_stopwatch.elapsed.inSeconds > 0) {
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
          // === 1. พื้นที่ Map (แทนที่ Placeholder ของเพื่อนด้วยของจริง) ===
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: currentLocation == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryRed,
                        ),
                      )
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          onMapReady: () => _isMapReady = true,
                          initialCenter: currentLocation!,
                          initialZoom: 17.0,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                            additionalOptions: {
                              'accessToken': mapboxAccessToken,
                              'id': mapStyleId,
                            },
                          ),
                          for (var segment in routeSegments)
                            if (segment.length > 1)
                              if (segment.isNotEmpty)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: segment,
                                      strokeWidth: 6.0,
                                      color: AppTheme
                                          .primaryRed, // เปลี่ยนเส้นเป็นสีแดงตามธีมแอป
                                    ),
                                  ],
                                ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentLocation!,
                                width: 24,
                                height: 24,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primaryRed,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // === 2. Stats & Controls ของเพื่อน (เอาข้อมูลจริงมาใส่) ===
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
                // เวลาที่วิ่งจริง
                Text(
                  _formatTime(_stopwatch.elapsed),
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Text("Total Time", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),

                // ตัวเลขสถิติที่เปลี่ยนตามจริง
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      "Distance",
                      (totalDistance / 1000).toStringAsFixed(2),
                      "km",
                    ),
                    _buildStat("Pace", _formatPace(), "/km"),
                    _buildStat(
                      "Calories",
                      ((totalDistance / 1000 * 60).toInt()).toString(),
                      "kcal",
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // ลอจิกปุ่มกด
                if (!hasStarted)
                  _buildLargeButton(Icons.play_arrow, _toggleRun)
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSmallButton(
                        _stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
                        _toggleRun,
                      ),
                      const SizedBox(width: 30),
                      _buildLargeButton(Icons.stop, _finishRun),
                      const SizedBox(width: 30),
                      const SizedBox(width: 60),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === Helper ของ UI (เหมือนของเพื่อนเป๊ะ) ===
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
