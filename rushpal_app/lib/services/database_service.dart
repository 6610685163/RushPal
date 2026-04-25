import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  String get _baseUrl {
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api/runs'
        : 'http://localhost:3000/api/runs';
  }

  Future<void> saveNewRun({
    required double distance,
    required double pace,
    required int seconds,
    required int calories,
  }) async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final Map<String, dynamic> runData = {
          'user_id': userId,
          'distance': distance,
          'pace': pace,
          'duration_seconds': seconds,
          'calories': calories,
        };

        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(runData),
        );

        if (response.statusCode == 201) {
          print("✅ บันทึกข้อมูลการวิ่งสำเร็จ!");
        }
      }
    } catch (error) {
      print("❌ เกิดข้อผิดพลาดในการเชื่อมต่อ Backend: $error");
    }
  }

  Future<Map<String, dynamic>?> fetchUserStats(String timeFrame) async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final url = '$_baseUrl/stats/$userId?time_frame=$timeFrame';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
      }
      return null;
    } catch (error) {
      print("❌ Error fetching stats: $error");
      return null;
    }
  }
}
