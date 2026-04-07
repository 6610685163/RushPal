import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/character_model.dart'; // Import โมเดลข้อมูล

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final O3DController _controller = O3DController();

  // ตัวแปรเก็บสถานะการ "ลองชุด" ภายในหน้า Market
  Character? viewedCharacter;
  Skin? previewSkin;

  @override
  void initState() {
    super.initState();
    // เริ่มต้นให้ตัวละครและสกินที่ดูอยู่ เป็นตัวเดียวกับที่ใส่อยู่ปัจจุบัน
    viewedCharacter = PlayerState.currentCharacter.value;
    previewSkin = PlayerState.currentSkin.value;
  }

  // ฟังก์ชันสวมใส่สกิน (อัปเดตทั้งตัวละคร สกิน ลง Firebase และ Global State)
  Future<void> _equipSkin(Character character, Skin skin) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 1. อัปเดตข้อมูลใน Firestore ทั้ง characterId และ skinId
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'characterId': character.id,
        'skinId': skin.id,
      });

      // 2. อัปเดต Global State เพื่อให้หน้า Home เปลี่ยนตามทันที
      PlayerState.currentCharacter.value = character;
      PlayerState.currentSkin.value = skin;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'สวมใส่ชุด ${skin.name} ให้ ${character.name} เรียบร้อยแล้ว',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error equipping skin: $e");
    }
  }

  // --- ฟังก์ชันแสดงหน้าต่าง Popup เลือกตัวละคร ---
  void _showCharacterSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'เปลี่ยนตัวละคร',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: myCharacters.map((char) {
              final isCurrentView = viewedCharacter?.id == char.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    viewedCharacter = char;
                    // เมื่อสลับตัวละคร ให้ดึงสกินแรกสุดมาพรีวิวเสมอ
                    previewSkin = char.skins.first;
                  });

                  // สั่ง "สวมใส่" สกิน Default ของตัวละครนี้ และอัปเดตหน้า Home ทันที
                  _equipSkin(char, char.skins.first);

                  Navigator.pop(context); // ปิดหน้าต่าง Popup
                },
                child: Card(
                  elevation: isCurrentView ? 8 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isCurrentView
                          ? AppTheme.primaryRed
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 10,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          char.gender == 'Male' ? Icons.boy : Icons.girl,
                          size: 60,
                          color: char.gender == 'Male'
                              ? Colors.blue
                              : Colors.pink,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          char.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          char.gender,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (viewedCharacter == null || previewSkin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
      body: Column(
        children: [
          // 1. ส่วนแสดงโมเดล 3D (Preview)
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // --- จำลองเงาใต้โมเดล (อยู่ที่ฝ่าเท้า) ---
                Positioned(
                  bottom: 15,
                  child: Container(
                    width: 160,
                    height: 25,
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(160, 25),
                      ),
                    ),
                  ),
                ),

                // --- โมเดล 3D ---
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: O3D(
                    key: ValueKey(
                      previewSkin!.modelPath,
                    ), // รีโหลดเมื่อเปลี่ยนสกิน
                    src: previewSkin!.modelPath,
                    controller: _controller,
                    autoPlay: true,
                    autoRotate: true,
                    cameraControls: true,
                    animationName: 'Idle',
                    backgroundColor: Colors.transparent,
                    exposure: 0.6,
                  ),
                ),

                // --- ปุ่ม "Characters" (มุมซ้ายบน) ---
                Positioned(
                  top: 15,
                  left: 15,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCharacterSelectionDialog(context),
                    icon: const Icon(Icons.people, color: Colors.black87),
                    label: const Text(
                      "Characters",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),

                // --- ปุ่มกด "สวมใส่" จะปรากฏเมื่อไม่ได้ใช้ชุดนี้อยู่ ---
                ValueListenableBuilder<Skin?>(
                  valueListenable: PlayerState.currentSkin,
                  builder: (context, globalSkin, _) {
                    final globalChar = PlayerState.currentCharacter.value;

                    // เช็คว่าตัวละครหรือสกินที่พรีวิวอยู่ แตกต่างจากของจริงหรือไม่
                    final bool isDifferent =
                        (previewSkin!.id != globalSkin?.id) ||
                        (viewedCharacter!.id != globalChar?.id);

                    if (isDifferent) {
                      return Positioned(
                        bottom: 10, // 👉 ปุ่ม USE THIS SKIN ขยับลงมาล่างสุด
                        child: ElevatedButton(
                          onPressed: () =>
                              _equipSkin(viewedCharacter!, previewSkin!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            "USE THIS SKIN",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // 2. ส่วนเลือก Skin ด้านล่าง
          Container(
            height: 320, // ดันพื้นที่ให้สูงขึ้นเพื่อไม่ให้ Bottom Nav Bar บัง
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
                    "Available Skins for ${viewedCharacter!.name}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<Skin?>(
                    valueListenable: PlayerState.currentSkin,
                    builder: (context, globalSkin, _) {
                      final globalChar = PlayerState.currentCharacter.value;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        scrollDirection: Axis.horizontal,
                        itemCount: viewedCharacter!.skins.length,
                        itemBuilder: (context, index) {
                          final skin = viewedCharacter!.skins[index];

                          final bool isPreviewing = previewSkin?.id == skin.id;
                          final bool isEquipped =
                              (globalSkin?.id == skin.id) &&
                              (globalChar?.id == viewedCharacter!.id);

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
                      );
                    },
                  ),
                ),
                // ใส่พื้นที่ว่างดันปุ่มสกินให้พ้น Bottom Navigation Bar
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
