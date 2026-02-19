import 'package:flutter/material.dart';
import 'feature/running/running_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized(); 
  
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // เราสร้าง Scaffold (โครงหน้าจอ) ครอบไว้ชั่วคราว เพื่อทดสอบ Widget แผนที่
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Navigator Test Mode'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        // เรียกใช้กล่องแผนที่ของเราตรงนี้!
        body: const RunningMapWidget(),
      ),
    );
  }
}
