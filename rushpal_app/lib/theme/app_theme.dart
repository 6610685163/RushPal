import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color pureBlack = Color(0xFF2C2520); // สีน้ำตาลเข้ม
  static const Color darkBlue = Color(0xFFFFFFFF); // สีขาวสำหรับพื้นผิว/การ์ด

  // โทนสีเหลืองแบบใหม่
  static const Color primaryPink = Color(
    0xFFFFCA28,
  ); // สีเหลืองสดใส (สีหลักใหม่)
  static const Color primaryRed = Color(
    0xFFFF7043,
  ); // สีส้มอมแดง (สำหรับแจ้งเตือนหรือปุ่มรอง)

  static const Color textLight = Color(
    0xFF5D4037,
  ); // สีข้อความ (น้ำตาลตุ่น เข้ากับสีเหลือง)
  static const Color backgroundCream = Color(0xFFFFFDF5); // สีพื้นหลังครีมสว่าง

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFCA28), Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryPink,
      scaffoldBackgroundColor: backgroundCream,
      brightness: Brightness.light,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textLight,
        displayColor: textLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: GoogleFonts.poppins(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
