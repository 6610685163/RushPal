import 'dart:convert';
import 'package:http/http.dart' as http;

class PartyService {
  // 🌟 อย่าลืมเปลี่ยน IP ตรงนี้ให้ตรงกับ baseUrl เดิมที่คุณใช้ในแอปนะครับ
  // (เช่น 'http://10.0.2.2:3000/api/parties' หรือ 'http://localhost:3000/api/parties')
  static const String baseUrl = 'http://10.0.2.2:3000/api/parties';

  // --- 1. สร้างห้องปาร์ตี้ (Host) ---
  static Future<String?> createParty({
    required String uid,
    required String username,
    required String skinId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'username': username, 'skinId': skinId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ สร้างห้องสำเร็จ Party ID: ${data['partyId']}");
        return data['partyId']; // ส่ง partyId (ซึ่งก็คือ UID) กลับไปให้ UI
      }
      return null;
    } catch (e) {
      print("❌ API Error (Create Party): $e");
      return null;
    }
  }

  // --- 2. ส่งคำเชิญให้เพื่อน (Host -> Guest) ---
  static Future<bool> inviteFriend({
    required String myPartyId,
    required String friendUid,
    required String myUsername,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'myPartyId': myPartyId,
          'friendUid': friendUid,
          'myUsername': myUsername,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ ส่งคำเชิญสำเร็จ");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ API Error (Invite Friend): $e");
      return false;
    }
  }

  // --- 3. กดยอมรับคำเชิญ (Guest -> Host) ---
  static Future<bool> acceptInvite({
    required String partyId,
    required String myUid,
    required String myUsername,
    required String mySkinId,
    required Map<String, dynamic> inviteObject,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'partyId': partyId, // ID ห้องที่จะเข้า
          'myUid': myUid,
          'myUsername': myUsername,
          'mySkinId': mySkinId,
          'inviteObject': inviteObject, // ส่งก้อนคำเชิญไปลบทิ้งที่หลังบ้านด้วย
        }),
      );

      if (response.statusCode == 200) {
        print("✅ ตอบรับคำเชิญและเข้าห้องสำเร็จ");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ API Error (Accept Invite): $e");
      return false;
    }
  }

  // --- 4. เข้าร่วมห้องด้วยรหัส 5 หลัก (Join by Code) ---
  static Future<String?> joinPartyByCode({
    required String partyCode,
    required String uid,
    required String username,
    required String skinId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/join-by-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'partyCode': partyCode,
          'uid': uid,
          'username': username,
          'skinId': skinId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ เข้าร่วมห้องสำเร็จ Party ID: ${data['partyId']}");
        return data['partyId']; // คืนค่ารหัสห้องที่แปลงเป็นตัวพิมพ์ใหญ่แล้วกลับไป
      } else {
        print("❌ เข้าห้องไม่ได้: ${response.body}");
        return null; // ถ้ารหัสผิด หรือห้องเริ่มไปแล้ว จะได้ค่า null
      }
    } catch (e) {
      print("❌ API Error (Join by Code): $e");
      return null;
    }
  }

  // --- 5. สลับสถานะ Ready (Toggle Ready) ---
  static Future<bool> toggleReady({
    required String partyCode,
    required String uid,
    required bool isReady,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ready'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'partyCode': partyCode,
          'uid': uid,
          'isReady': isReady,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ API Error (Toggle Ready): $e");
      return false;
    }
  }

  // --- 6. ออกจากห้อง (Leave Party) ---
  static Future<bool> leaveParty({
    required String partyCode,
    required String uid,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'partyCode': partyCode, 'uid': uid}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ API Error (Leave Party): $e");
      return false;
    }
  }

  // --- 7. เริ่มปาร์ตี้วิ่ง (Start Party) ---
  static Future<bool> startParty({required String partyCode}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'partyCode': partyCode}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ API Error (Start Party): $e");
      return false;
    }
  }
}
