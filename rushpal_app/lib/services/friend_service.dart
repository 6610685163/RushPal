import 'dart:convert';
import 'package:http/http.dart' as http;

class FriendService {
  // ใช้ 10.0.2.2 สำหรับ Android Emulator เพื่อชี้มาที่ localhost ของคอมพิวเตอร์
  static const String baseUrl = 'http://192.168.1.56:3000/api/friends';

  static Future<Map<String, dynamic>?> searchFriend(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // คืนค่าข้อมูล User ที่เจอ
      } else {
        print('ไม่พบผู้ใช้: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('API Error: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getFriendsList(String uid) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/list'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // คืนค่าเป็น List ของเพื่อน
      }
      return [];
    } catch (e) {
      print('API Error: $e');
      return [];
    }
  }

  // 1. ส่งคำขอ
  static Future<bool> sendRequest(String myUid, String friendUid) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/request/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'myUid': myUid, 'friendUid': friendUid}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 2. กดยอมรับ
  static Future<bool> acceptRequest(String myUid, String friendUid) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/request/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'myUid': myUid, 'friendUid': friendUid}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 3. ปฏิเสธคำขอ
  static Future<bool> declineRequest(String myUid, String friendUid) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/request/decline'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'myUid': myUid, 'friendUid': friendUid}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 5. ลบเพื่อน
  static Future<bool> removeFriend(String myUid, String friendUid) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/remove'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'myUid': myUid, 'friendUid': friendUid}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 4. ดึงรายชื่อคนขอแอดมา
  static Future<List<dynamic>> getPendingRequests(String uid) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/request/list'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid}),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) {
      return [];
    }
  }
}
