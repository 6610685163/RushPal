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

  // สร้าง Base URL สำหรับระบบ Shop
  String get _shopBaseUrl {
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api/shop'
        : 'http://localhost:3000/api/shop';
  }

  // โหลดร้านค้า
  Future<Map<String, dynamic>?> fetchMarketItems() async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final url = '$_shopBaseUrl/market/$userId';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
      }
      return null;
    } catch (error) {
      print("❌ Error fetching market items: $error");
      return null;
    }
  }

  // ซื้อไอเทม
  Future<bool> buyItem(String itemId) async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final url = '$_shopBaseUrl/buy';
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uid': userId, 'itemId': itemId}),
        );
        return response.statusCode == 200;
      }
      return false;
    } catch (error) {
      print("❌ Error buying item: $error");
      return false;
    }
  }

  // สวมใส่ไอเทม / ท่าทาง
  Future<bool> equipItem(String category, String itemKeyOrId) async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final url = '$_shopBaseUrl/equip';
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'uid': userId,
            'category': category, // 'Skin', 'Idle', หรือ 'Ready'
            'itemKeyOrId':
                itemKeyOrId, // รหัส skin หรือชื่อท่า (เช่น 'idle_01')
          }),
        );
        return response.statusCode == 200;
      }
      return false;
    } catch (error) {
      print("❌ Error equipping item: $error");
      return false;
    }
  }
}
