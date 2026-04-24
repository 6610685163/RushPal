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

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'characterId': char.id,
      'skinId': skin.id,
    });

    PlayerState.currentCharacter.value = char;
    PlayerState.currentSkin.value = skin;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เปลี่ยนชุดเป็น ${skin.name} แล้ว!'),
        backgroundColor: AppTheme.primaryPink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 90,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // คำนวณระยะห่างด้านล่างสำหรับ Navbar
    double bottomPadding = MediaQuery.of(context).padding.bottom + 10;

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: const Text(
          'CHARACTER SHOP',
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // 1. โซนเลือกตัวละคร
          Container(
            height: 90,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: myCharacters.map((char) {
                bool isSelected = selectedCharacter?.id == char.id;
                return GestureDetector(
                  onTap: () => setState(() => selectedCharacter = char),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryPink : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppTheme.primaryPink.withOpacity(0.3)
                              : Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          char.gender == 'Male'
                              ? Icons.boy_rounded
                              : Icons.girl_rounded,
                          size: 32,
                          color: isSelected ? Colors.white : AppTheme.textLight,
                        ),
                        Text(
                          char.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 2. โซนโมเดล 3D (Middle)
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom:
                      55,
                  child: Container(
                    width: 120,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: const BorderRadius.all(
                        Radius.elliptical(80, 15),
                      ),
                    ),
                  ),
                ),

                // โมเดล 3D
                if (selectedCharacter != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 60,
                    ),
                    child: ValueListenableBuilder<Skin?>(
                      valueListenable: PlayerState.currentSkin,
                      builder: (context, currentSkin, child) {
                        if (currentSkin == null)
                          return const CircularProgressIndicator();
                        return O3D(
                          key: ValueKey(
                            currentSkin.modelPath + selectedCharacter!.id,
                          ),
                          src: currentSkin.modelPath,
                          controller: _controller,
                          autoPlay: true,
                          cameraControls: false,
                          backgroundColor: Colors.transparent,
                          exposure: 1.0,
                          animationName: 'Run',
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 3. โซนเลือกสกิน (Bottom)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 20, bottom: bottomPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    "OUTFITS",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textLight,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: selectedCharacter?.skins.length ?? 0,
                    itemBuilder: (context, index) {
                      final skin = selectedCharacter!.skins[index];
                      bool isEquipped =
                          PlayerState.currentSkin.value?.id == skin.id;

                      return GestureDetector(
                        onTap: () => _equipSkin(selectedCharacter!, skin),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 100,
                          margin: const EdgeInsets.only(right: 12, bottom: 5),
                          decoration: BoxDecoration(
                            color: isEquipped
                                ? AppTheme.primaryPink.withOpacity(0.05)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isEquipped
                                  ? AppTheme.primaryPink
                                  : Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.checkroom_rounded,
                                size: 28,
                                color: isEquipped
                                    ? AppTheme.primaryPink
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                skin.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isEquipped
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isEquipped
                                      ? AppTheme.primaryPink
                                      : AppTheme.textLight,
                                ),
                              ),
                              if (isEquipped)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryPink,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "ACTIVE",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
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
