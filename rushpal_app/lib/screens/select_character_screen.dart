import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rushpal/theme/app_theme.dart';
import '../models/character_model.dart';
import 'home_screen.dart';

class SelectCharacterScreen extends StatelessWidget {
  const SelectCharacterScreen({super.key});

  Future<void> _selectCharacter(
    BuildContext context,
    Character character,
  ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final defaultSkin = character.skins.first;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'characterId': character.id,
        'skinId': defaultSkin.id,
      }, SetOptions(merge: true));

      PlayerState.currentCharacter.value = character;
      PlayerState.currentSkin.value = defaultSkin;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      debugPrint("Error selecting character: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกตัวละครของคุณ')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: myCharacters.map((char) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => _selectCharacter(context, char),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            char.gender == ''
                                ? Icons.boy_rounded
                                : Icons.girl_rounded,
                            size: 100,
                            color: AppTheme.primaryPink,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            char.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            char.gender,
                            style: TextStyle(
                              color: AppTheme.textLight.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
