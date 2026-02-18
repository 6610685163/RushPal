import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'screens/login_screen.dart'; // import login screen

void main() {
  runApp(RushpalApp());
}

class RushpalApp extends StatelessWidget {
  const RushpalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rushpal',
      theme: AppTheme.theme,
      home: const LoginScreen(), // เปลี่ยนจาก HomeScreen() เป็น LoginScreen()
    );
  }
}
