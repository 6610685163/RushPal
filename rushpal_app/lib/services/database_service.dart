import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  // สร้าง URL ของ Backend อัตโนมัติ
  String get _baseUrl {
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api/runs'
        : 'http://localhost:3000/api/runs';
  }

  // 1. ฟังก์ชันเซฟข้อมูล (เพิ่ม calories)
  Future<void> saveNewRun({
    required double distance,
    required double pace,
    required int seconds,
    required int calories, // 👈 รับค่าแคลอรีเพิ่ม
  }) async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final Map<String, dynamic> runData = {
          'user_id': userId,
          'distance': distance,
          'pace': pace,
          'duration_seconds': seconds,
          'calories': calories, // 👈 ส่งแคลอรีไป Backend
        };

        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(runData),
        );

        if (response.statusCode == 201) {
          print("✅ บันทึกข้อมูลพร้อม Calories สำเร็จ!");
        }
      }
    } catch (error) {
      print("❌ เกิดข้อผิดพลาดในการเชื่อมต่อ Backend: $error");
    }
  }

  // 2. ฟังก์ชันดึงสถิติไปโชว์หน้า Stats (ใหม่)
  // ใส่ timeFrame เป็น 'daily', 'weekly', 'monthly', หรือ 'all'
  Future<Map<String, dynamic>?> fetchUserStats(String timeFrame) async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final url = '$_baseUrl/stats/$userId?time_frame=$timeFrame';

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data; // ส่ง Map ของข้อมูลกลับไปให้หน้า UI
        }
      }
      return null;
    } catch (error) {
      print("❌ Error fetching stats: $error");
      return null;
    }
  }
}
