import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PartyService {
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

  // --- 8. ดึงข้อมูลสมาชิกในปาร์ตี้---
  static Future<List<dynamic>?> getPartyDetails(String partyCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/details/$partyCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['members']; // คืนค่าเป็น List กลับไปให้หน้า Home วาดโมเดล
      } else {
        print("❌ ไม่พบข้อมูลปาร์ตี้: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ API Error (Get Party Details): $e");
      return null;
    }
  }

  // --- 9. อัปเดตสกินให้เพื่อนในปาร์ตี้เห็นแบบ Real-time ---
  static Future<void> syncSkinToParty(String newSkinId, String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final partyCode = prefs.getString('partyCode');

      // เช็คว่าเรากำลังอยู่ในปาร์ตี้หรือไม่
      if (partyCode != null && partyCode.isNotEmpty) {
        // อัปเดตข้อมูลสกินของเราใน Firestore ของปาร์ตี้นั้นๆ
        await FirebaseFirestore.instance
            .collection('parties')
            .doc(partyCode)
            .update({'members.$uid.skinId': newSkinId});
        print("✅ ซิงค์สกินใหม่เข้าปาร์ตี้สำเร็จ เพื่อนจะเห็นแล้ว!");
      }
    } catch (e) {
      // ไม่ต้องแจ้ง Error ถือว่าผู้ใช้เปลี่ยนสกินตอนที่ไม่ได้อยู่ในปาร์ตี้
      print("ℹ️ เปลี่ยนสกินตอนไม่ได้อยู่ในปาร์ตี้ หรือ Error: $e");
    }
  }

  // --- 10. อัปเดต animation ให้เพื่อนในปาร์ตี้เห็นแบบ Real-time ---
  static Future<void> syncAnimationToParty({
    required String uid,
    required String idleKey,
    required String readyKey,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final partyCode = prefs.getString('partyCode');

      if (partyCode != null && partyCode.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('parties')
            .doc(partyCode)
            .update({
              'members.$uid.idleId': idleKey,
              'members.$uid.readyId': readyKey,
            });
        print("✅ ซิงค์ animation เข้าปาร์ตี้สำเร็จ!");
      }
    } catch (e) {
      print("ℹ️ ซิงค์ animation: ไม่ได้อยู่ในปาร์ตี้ หรือ Error: $e");
    }
  }
}
