import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(RushpalApp());
}

class RushpalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rushpal',
      theme: AppTheme.theme,
      home: HomeScreen(),
    );
  }
}
