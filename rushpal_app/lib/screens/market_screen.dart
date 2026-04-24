import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/character_model.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final O3DController _controller = O3DController();
  Character? viewedCharacter;
  Skin? previewSkin;

  @override
  void initState() {
    super.initState();
    viewedCharacter = PlayerState.currentCharacter.value;
    previewSkin = PlayerState.currentSkin.value;
  }

  Future<void> _equipSkin(Character character, Skin skin) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'characterId': character.id,
        'skinId': skin.id,
      });

      PlayerState.currentCharacter.value = character;
      PlayerState.currentSkin.value = skin;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สวมใส่ชุด ${skin.name} ให้ ${character.name} แล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {}
  }

  void _showCharacterSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkBlue, // Popup สีมืด
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.primaryPink),
          ),
          title: const Text(
            'เปลี่ยนตัวละคร',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: myCharacters.map((char) {
              final isCurrentView = viewedCharacter?.id == char.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    viewedCharacter = char;
                    previewSkin = char.skins.first;
                  });
                  _equipSkin(char, char.skins.first);
                  Navigator.pop(context);
                },
                child: Card(
                  color: AppTheme.pureBlack,
                  elevation: isCurrentView ? 8 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isCurrentView
                          ? AppTheme.primaryPink
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
                              : AppTheme.primaryPink,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          char.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
    if (viewedCharacter == null || previewSkin == null)
      return const Scaffold(
        backgroundColor: AppTheme.pureBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryPink),
        ),
      );

    return Scaffold(
      backgroundColor: AppTheme.pureBlack,
      appBar: AppBar(
        title: const Text(
          "Skin Shop",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 10,
                  child: Container(
                    width: 160,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: const BorderRadius.all(
                        Radius.elliptical(160, 25),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: O3D(
                    key: ValueKey(previewSkin!.modelPath),
                    src: previewSkin!.modelPath,
                    controller: _controller,
                    autoPlay: true,
                    autoRotate: false,
                    cameraControls: true,
                    animationName: 'Idle',
                    backgroundColor: Colors.transparent,
                    exposure: 0.8,
                  ),
                ),
                // --- ปุ่ม "Characters" (มุมซ้ายบน) ---
                Positioned(
                  top: 15,
                  left: 15,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCharacterSelectionDialog(context),
                    icon: const Icon(Icons.people, color: Colors.white),
                    label: const Text(
                      "Characters",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkBlue.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                // --- ปุ่ม "Coin" (มุมขวาบน) ---
                Positioned(
                  top: 20,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBlue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "1,000",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ValueListenableBuilder<Skin?>(
                  valueListenable: PlayerState.currentSkin,
                  builder: (context, globalSkin, _) {
                    final globalChar = PlayerState.currentCharacter.value;
                    final bool isDifferent =
                        (previewSkin!.id != globalSkin?.id) ||
                        (viewedCharacter!.id != globalChar?.id);
                    if (isDifferent) {
                      return Positioned(
                        bottom: 10,
                        child: ElevatedButton(
                          onPressed: () =>
                              _equipSkin(viewedCharacter!, previewSkin!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPink,
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
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: AppTheme.darkBlue,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border.all(color: Colors.white12),
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
                      color: Colors.white,
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
                                color: AppTheme.pureBlack,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isPreviewing
                                      ? AppTheme.primaryPink
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.checkroom,
                                    size: 50,
                                    color: isEquipped
                                        ? AppTheme.primaryPink
                                        : Colors.white54,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    skin.name.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isEquipped
                                          ? AppTheme.primaryPink
                                          : Colors.white,
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
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
