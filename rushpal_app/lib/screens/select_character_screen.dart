import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

      // 1. บันทึกลง Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'characterId': character.id,
        'skinId': defaultSkin.id,
      }, SetOptions(merge: true));

      // 2. อัปเดต Global State
      PlayerState.currentCharacter.value = character;
      PlayerState.currentSkin.value = defaultSkin;

      // 3. ไปที่หน้า Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      print("Error selecting character: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกตัวละครของคุณ'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: myCharacters.map((char) {
            return GestureDetector(
              onTap: () => _selectCharacter(context, char),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        char.gender == 'Male' ? Icons.boy : Icons.girl,
                        size: 80,
                        color: char.gender == 'Male'
                            ? Colors.blue
                            : Colors.pink,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        char.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        char.gender,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
