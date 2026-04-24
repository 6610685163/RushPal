import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:o3d/o3d.dart';
import 'package:rushpal/theme/app_theme.dart';
import '../models/character_model.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final O3DController _controller = O3DController();
  Character? selectedCharacter;

  @override
  void initState() {
    super.initState();
    selectedCharacter = PlayerState.currentCharacter.value;
  }

  Future<void> _equipSkin(Character char, Skin skin) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // อัปเดตลง Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'characterId': char.id,
      'skinId': skin.id,
    });

    // อัปเดต Global State เพื่อให้หน้า Home เปลี่ยนตามทันที
    PlayerState.currentCharacter.value = char;
    PlayerState.currentSkin.value = skin;

    setState(() {}); // Refresh UI

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ใส่ชุด ${skin.name} สำเร็จ!'),
        backgroundColor: AppTheme.primaryPink,
      ),
    );
  }

  void _showSkinSelector() {
    final char = selectedCharacter;
    if (char == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'เลือกสกินตัวละคร',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                children: char.skins.map((skin) {
                  return GestureDetector(
                    onTap: () async {
                      await _equipSkin(char, skin);
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: AppTheme.primaryPink.withOpacity(0.15),
                          child: const Icon(
                            Icons.checkroom_rounded,
                            color: AppTheme.primaryPink,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          skin.name,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(title: const Text('CHARACTER SHOP'), centerTitle: true),
      body: Column(
        children: [
          // 1. ส่วนเลือกตัวละคร (Ray / Fern)
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: myCharacters.map((char) {
                bool isSelected = selectedCharacter?.id == char.id;
                return GestureDetector(
                  onTap: () => setState(() => selectedCharacter = char),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryPink.withOpacity(0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryPink
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          char.gender == 'Male' ? Icons.boy : Icons.girl,
                          size: 40,
                          color: isSelected
                              ? AppTheme.primaryPink
                              : AppTheme.textLight,
                        ),
                        Text(
                          char.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(),

          // 2. แสดงโมเดล 3D Preview (เมื่อเลือกตัวละคร)
          if (selectedCharacter != null)
            ValueListenableBuilder<Skin?>(
              valueListenable: PlayerState.currentSkin,
              builder: (context, currentSkin, child) {
                if (currentSkin == null) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryPink,
                      ),
                    ),
                  );
                }
                return Container(
                  height: 250,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundCream.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 100,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: const BorderRadius.all(
                              Radius.elliptical(80, 8),
                            ),
                          ),
                        ),
                      ),
                      O3D(
                        key: ValueKey(currentSkin.modelPath),
                        src: currentSkin.modelPath,
                        controller: _controller,
                        autoPlay: true,
                        autoRotate: false,
                        cameraControls: false,
                        backgroundColor: Colors.transparent,
                        exposure: 0.8,
                        animationName: 'Run',
                      ),
                    ],
                  ),
                );
              },
            ),

          // 4. ส่วนเลือกสกิน (แสดงผลแบบ Grid)
          if (selectedCharacter != null)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: selectedCharacter!.skins.length,
                itemBuilder: (context, index) {
                  final skin = selectedCharacter!.skins[index];
                  bool isEquipped =
                      PlayerState.currentSkin.value?.id == skin.id;

                  return GestureDetector(
                    onTap: () => _equipSkin(selectedCharacter!, skin),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isEquipped
                              ? AppTheme.primaryPink
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 5),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.checkroom,
                            size: 60,
                            color: AppTheme.primaryPink,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            skin.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (isEquipped)
                            const Text(
                              'ใช้งานอยู่',
                              style: TextStyle(
                                color: AppTheme.primaryPink,
                                fontSize: 10,
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
    );
  }
}
