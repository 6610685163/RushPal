import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/character_model.dart'; // Import โมเดลข้อมูลที่คุณสร้างไว้

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final O3DController _controller = O3DController();

  // ใช้สำหรับลองชุดชั่วคราวในหน้า Market
  Skin? previewSkin;

  @override
  void initState() {
    super.initState();
    // เริ่มต้นให้ previewSkin เป็นสกินที่ใส่อยู่ปัจจุบัน
    previewSkin = PlayerState.currentSkin.value;
  }

  // ฟังก์ชันสวมใส่สกิน (อัปเดตทั้ง Firebase และ Global State)
  Future<void> _equipSkin(Skin skin) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 1. อัปเดตข้อมูลใน Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'skinId': skin.id,
      });

      // 2. อัปเดต Global State เพื่อให้หน้า Home เปลี่ยนตามทันที
      PlayerState.currentSkin.value = skin;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สวมใส่ชุด ${skin.name} เรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error equipping skin: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลตัวละครปัจจุบันจาก Global State
    final character = PlayerState.currentCharacter.value;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Skin Shop",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: character == null
          ? const Center(child: Text("กรุณาเลือกตัวละครก่อน"))
          : Column(
              children: [
                // 1. ส่วนแสดงโมเดล 3D (Preview)
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      ValueListenableBuilder<Skin?>(
                        valueListenable: PlayerState.currentSkin,
                        builder: (context, currentEquippedSkin, _) {
                          // ใช้ previewSkin ถ้ามีการกดลองชุด ถ้าไม่มีให้ใช้สกินที่ใส่อยู่
                          final displayModel =
                              previewSkin?.modelPath ??
                              currentEquippedSkin?.modelPath ??
                              "";

                          return O3D(
                            key: ValueKey(displayModel),
                            src: displayModel,
                            controller: _controller,
                            autoPlay: true,
                            autoRotate: true,
                            cameraControls: true,
                            animationName: 'Idle',
                            backgroundColor: Colors.transparent,
                            exposure: 0.6, // แก้สีผิวซีดตามที่เคยแนะนำ
                          );
                        },
                      ),

                      // ปุ่มกด "สวมใส่" จะปรากฏเมื่อสกินที่ลองอยู่ ไม่ใช่สกินที่ใส่อยู่ปัจจุบัน
                      if (previewSkin != null &&
                          previewSkin!.id != PlayerState.currentSkin.value?.id)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: ElevatedButton(
                              onPressed: () => _equipSkin(previewSkin!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRed,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "USE THIS SKIN",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 2. ส่วนเลือก Skin (แทนที่ Grid เดิม)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
                        child: Text(
                          "Available Skins for ${character.name}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          scrollDirection: Axis.horizontal,
                          itemCount: character.skins.length,
                          itemBuilder: (context, index) {
                            final skin = character.skins[index];
                            final bool isPreviewing =
                                previewSkin?.id == skin.id;
                            final bool isEquipped =
                                PlayerState.currentSkin.value?.id == skin.id;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  previewSkin = skin;
                                });
                              },
                              child: Container(
                                width: 140,
                                margin: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isPreviewing
                                        ? AppTheme.primaryRed
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.checkroom,
                                      size: 50,
                                      color: isEquipped
                                          ? AppTheme.primaryRed
                                          : Colors.grey,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      skin.name.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isEquipped
                                            ? AppTheme.primaryRed
                                            : Colors.black,
                                      ),
                                    ),
                                    if (isEquipped)
                                      const Text(
                                        "EQUIPPED",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
