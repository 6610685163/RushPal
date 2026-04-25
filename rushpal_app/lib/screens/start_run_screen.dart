import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'run_complete_screen.dart';

class StartRunScreen extends StatefulWidget {
  final String? partyCode;
  const StartRunScreen({super.key, this.partyCode});

  @override
  State<StartRunScreen> createState() => _StartRunScreenState();
}

class _StartRunScreenState extends State<StartRunScreen> {
  final String mapboxAccessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  final String mapStyleId = 'mapbox/dark-v11';
  final MapController _mapController = MapController();
  List<List<LatLng>> routeSegments = [];
  LatLng? currentLocation;
  bool _isMapReady = false;

  double totalDistance = 0.0;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool hasStarted = false;

  @override
  void initState() {
    super.initState();
    _initLocation();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stopwatch.isRunning) {
        setState(() {});
      }
    });
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
        } else {
          List<LatLng> currentSegment = routeSegments.last;
          if (currentSegment.isNotEmpty) {
            double dist = Geolocator.distanceBetween(
              currentSegment.last.latitude,
              currentSegment.last.longitude,
              newPos.latitude,
              newPos.longitude,
            );

            if (dist < 100) {
              totalDistance += dist;
              currentSegment.add(newPos);
            }
          } else {
            currentSegment.add(newPos);
          }
        }
      }

      currentLocation = newPos;
      if (_isMapReady) {
        _mapController.move(newPos, 17.0);
      }
    });
  }

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

  void _toggleRun() {
    setState(() {
      hasStarted = true;
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
      } else {
        _stopwatch.start();
        List<LatLng> newSegment = [];
        if (currentLocation != null) {
          newSegment.add(currentLocation!);
        }
        routeSegments.add(newSegment);
      }
    });
  }

  void _finishRun() {
    _stopwatch.stop();
    _timer?.cancel();

    int calories = (totalDistance / 1000 * 60).toInt();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RunCompleteScreen(
          duration: _stopwatch.elapsed,
          distance: double.parse((totalDistance / 1000).toStringAsFixed(2)),
          calories: calories,
          routeSegments: routeSegments,
          partyCode: widget.partyCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.pureBlack),
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
          style: TextStyle(
            color: AppTheme.pureBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.pureBlack, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.pureBlack,
                    blurRadius: 0,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: currentLocation == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryPink,
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
                          PolylineLayer(
                            polylines: routeSegments
                                .where((segment) => segment.length > 1)
                                .map(
                                  (segment) => Polyline(
                                    points: segment,
                                    strokeWidth: 6.0,
                                    color: AppTheme.primaryRed,
                                  ),
                                )
                                .toList(),
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
                                      width: 4,
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
                Text(
                  _formatTime(_stopwatch.elapsed),
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: AppTheme.textLight,
                  ),
                ),
                const Text(
                  "Total Time",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
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
                if (!hasStarted)
                  _buildLargeButton(Icons.play_arrow_rounded, _toggleRun)
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSmallButton(
                        _stopwatch.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        _toggleRun,
                      ),
                      const SizedBox(width: 30),
                      _buildLargeButton(Icons.stop_rounded, _finishRun),
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

  Widget _buildLargeButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: AppTheme.primaryPink,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.pureBlack, width: 4),
          boxShadow: const [
            BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 6)),
          ],
        ),
        child: Icon(icon, color: AppTheme.pureBlack, size: 50),
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.pureBlack, width: 3),
          boxShadow: const [
            BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: AppTheme.pureBlack, size: 35),
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
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.pureBlack,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5, left: 2),
              child: Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
