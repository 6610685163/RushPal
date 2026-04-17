import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color pureBlack = Color(0xFF0D0D12);
  static const Color darkBlue = Color(0xFF1A1B2F);
  static const Color primaryPink = Color(0xFFFF007F);
  static const Color primaryRed = primaryPink;
  static const Color textLight = Color(0xFFF5F5F5);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF007F), Color(0xFF7A00FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryPink,
      scaffoldBackgroundColor: pureBlack,
      brightness: Brightness.dark,
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
