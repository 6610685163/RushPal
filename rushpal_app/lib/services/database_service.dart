import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final supabase = Supabase.instance.client;

  Future<void> saveNewRun({
    required double distance,
    required double pace,
    required int seconds,
  }) async {
    // ดึง UID ของ User ปัจจุบันจาก Firebase
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      // บันทึกลงตาราง 'runs' ใน Supabase
      await supabase.from('runs').insert({
        'user_id': userId,
        'distance': distance,
        'pace': pace,
        'duration_seconds': seconds,
      });
      print("บันทึกข้อมูลการวิ่งสำเร็จ!");
    }
  }
}
