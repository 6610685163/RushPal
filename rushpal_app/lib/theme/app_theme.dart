import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // สีหลักจากในรูป (สีส้มแดง)
  static const Color primaryRed = Color(0xFFFF5252);
  static const Color backgroundGrey = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xFF333333);

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryRed,
      scaffoldBackgroundColor: backgroundGrey,
      // ตั้งฟอนต์หลักให้ดูทันสมัย (เช่น Poppins หรือ Kanit)
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.poppins(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
