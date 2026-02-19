import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RunningMapWidget extends StatefulWidget {
  final Function(double distance, Duration duration, double pace)? onUpdate;

  const RunningMapWidget({super.key, this.onUpdate});

  @override
  State<RunningMapWidget> createState() => _RunningMapWidgetState();
}

class _RunningMapWidgetState extends State<RunningMapWidget> {
  // ⚠️ ใส่ Token ของคุณที่นี่
  final String mapboxAccessToken = dotenv.env['mapboxAccessToken'] ?? '';
  final String mapStyleId = 'mapbox/dark-v11';

  final MapController _mapController = MapController();

  // ✅ เปลี่ยนจากเส้นเดียว เป็น "รายการของเส้น" (List ซ้อน List)
  // เพื่อให้เราสามารถ "ตัดเส้น" ให้ขาดออกจากกันได้เวลากด Pause
  List<List<LatLng>> routeSegments = [];

  LatLng? currentLocation;
  double totalDistance = 0.0;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stopwatch.isRunning) setState(() {});
    });

    // ✅ ปรับจูน GPS ให้ลื่นปรื๊ด!
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter:
            0, // ✅ แก้เป็น 0: รับค่าทุกเม็ด ไม่ต้องรอ 3 เมตร (สมูทขึ้น)
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
        // ถ้าเป็นจุดแรกสุดของการวิ่ง หรือจุดแรกหลังกด Resume
        // ให้เริ่มสร้าง "เส้นใหม่" (Segment ใหม่)
        if (routeSegments.isEmpty) {
          routeSegments.add([newPos]);
        }

        // คำนวณระยะทางจากจุดล่าสุดในเส้นปัจจุบัน
        List<LatLng> currentSegment = routeSegments.last;
        if (currentSegment.isNotEmpty) {
          double dist = Geolocator.distanceBetween(
            currentSegment.last.latitude,
            currentSegment.last.longitude,
            newPos.latitude,
            newPos.longitude,
          );

          // กันวาร์ป (ถ้ากระโดดไกลเกิน 50 เมตรใน 1 วิ ถือว่า Error)
          if (dist > 50) {
            // แค่ย้ายตัว แต่ไม่ลากเส้น
            currentLocation = newPos;
            if (_isMapReady) _mapController.move(newPos, 17.0);
            return;
          }

          totalDistance += dist;
          currentSegment.add(newPos); // ✅ เติมจุดลงในเส้นปัจจุบัน
        } else {
          // กรณีเส้นว่างเปล่า (เพิ่งกด Resume) ให้ใส่จุดเริ่มไปก่อน
          currentSegment.add(newPos);
        }

        if (widget.onUpdate != null) {
          double currentPace = _calculatePace();
          widget.onUpdate!(totalDistance, _stopwatch.elapsed, currentPace);
        }
      }

      currentLocation = newPos;
      // ✅ ขยับกล้องแบบ Animation เล็กๆ (ใช้ move ปกติแต่ถี่ขึ้นเพราะ filter=0)
      if (_isMapReady) {
        _mapController.move(newPos, 17.0);
      }
    });
  }

  double _calculatePace() {
    if (totalDistance == 0) return 0.0;
    double distanceKm = totalDistance / 1000;
    double timeMinutes =
        _stopwatch.elapsed.inMinutes +
        (_stopwatch.elapsed.inSeconds % 60) / 60.0;
    return timeMinutes / distanceKm;
  }

  void toggleRun() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop(); // กด Pause
      } else {
        _stopwatch.start(); // กด Resume
        // ✅ เทคนิคแก้เส้นตัด: พอเริ่มวิ่งใหม่ ให้ "ตั้งเส้นใหม่" รอไว้เลย
        // จุดต่อไปที่เข้ามา จะถูกใส่ในเส้นใหม่นี้ (เส้นเก่ากับเส้นใหม่จะไม่เชื่อมกัน)
        routeSegments.add([]);
      }
    });
  }

  void resetRun() {
    setState(() {
      _stopwatch.stop();
      _stopwatch.reset();
      routeSegments.clear(); // ล้างทุกเส้น
      totalDistance = 0.0;
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    double pace = _calculatePace();
    String paceString = (totalDistance > 0) ? pace.toStringAsFixed(2) : "0.00";

    if (currentLocation == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            onMapReady: () {
              _isMapReady = true;
            },
            initialCenter: currentLocation!,
            initialZoom: 17.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
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

            // ✅ วาดเส้นทั้งหมด (Loop วาดทีละเส้น)
            // ถ้าเรา Pause แล้วไปโผล่อีกที่ มันจะเป็นเส้นใหม่แยกกัน ไม่ขีดเส้นตรงเชื่อม
            for (var segment in routeSegments)
              if (segment.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: segment,
                      strokeWidth: 5.0,
                      color: Colors.greenAccent,
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.blueAccent,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Dashboard (เหมือนเดิม)
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  "Distance",
                  (totalDistance / 1000).toStringAsFixed(2),
                  "km",
                ),
                _buildStatItem("Time", _formatTime(_stopwatch.elapsed), ""),
                _buildStatItem("Pace", paceString, "min/km"),
              ],
            ),
          ),
        ),

        // ปุ่ม Control (เหมือนเดิม)
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: "reset_btn",
                onPressed: resetRun,
                backgroundColor: Colors.grey[800],
                mini: true,
                child: const Icon(Icons.refresh, color: Colors.white),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 80,
                height: 80,
                child: FloatingActionButton(
                  heroTag: "run_btn",
                  onPressed: toggleRun,
                  backgroundColor: _stopwatch.isRunning
                      ? Colors.redAccent
                      : Colors.greenAccent,
                  child: Icon(
                    _stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
                    size: 40,
                    color: _stopwatch.isRunning ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
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
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  unit,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
