import 'package:flutter/foundation.dart';

class Skin {
  final String id;
  final String name;
  final String modelPath;

  Skin({required this.id, required this.name, required this.modelPath});
}

class Character {
  final String id;
  final String name;
  final String gender;
  final List<Skin> skins;

  Character({
    required this.id,
    required this.name,
    required this.gender,
    required this.skins,
  });
}

// สร้าง Mock Data จำลองฐานข้อมูลตัวละครในเกม
final List<Character> myCharacters = [
  Character(
    id: 'char_male_01',
    name: 'Ray',
    gender: 'Male',
    skins: [
      Skin(
        id: 'skin_m_1',
        name: 'default',
        modelPath: 'assets/models/ray_default_run.glb',
      ),
      Skin(
        id: 'skin_m_2',
        name: 'black',
        modelPath: 'assets/models/ray_black_run.glb',
      ),
    ],
  ),
  Character(
    id: 'char_female_01',
    name: 'Fern',
    gender: 'Female',
    skins: [
      Skin(
        id: 'skin_f_1',
        name: 'default',
        modelPath: 'assets/models/fern_default.glb',
      ),
      Skin(
        id: 'skin_f_2',
        name: 'black',
        modelPath: 'assets/models/fern_black_run.glb',
      ),
      Skin(
        id: 'skin_f_3',
        name: 'pink',
        modelPath: 'assets/models/fern_pink_run.glb',
      ),
    ],
  ),
];

class PlayerState {
  // สร้างตัวแปร Global ไว้เก็บค่าตัวละครและสกินที่กำลังใช้งาน
  static ValueNotifier<Character?> currentCharacter = ValueNotifier(null);
  static ValueNotifier<Skin?> currentSkin = ValueNotifier(null);
}
