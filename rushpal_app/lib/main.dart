import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // เพิ่มการ Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      home: const LoginScreen(),
    );
  }
}
