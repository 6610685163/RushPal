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

// ข้อมูลจำลองตัวละครในเกม
final List<Character> myCharacters = [
  Character(
    id: 'char_male_01',
    name: 'Ray',
    gender: 'Male',
    skins: [
      Skin(
        id: 'skin_m_1',
        name: 'Default',
        modelPath: 'assets/models/ray_default_run.glb',
      ),
      Skin(
        id: 'skin_m_2',
        name: 'Black',
        modelPath: 'assets/models/ray_black_run.glb',
      ),
      Skin(
        id: 'skin_m_3',
        name: 'Cream',
        modelPath: 'assets/models/ray_cream_run.glb',
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
        name: 'Default',
        modelPath: 'assets/models/fern_default_run.glb',
      ),
      Skin(
        id: 'skin_f_2',
        name: 'Black',
        modelPath: 'assets/models/fern_black_run.glb',
      ),
      Skin(
        id: 'skin_f_3',
        name: 'Pink',
        modelPath: 'assets/models/fern_pp_run.glb',
      ),
    ],
  ),
];

class PlayerState {
  // ตัวแปร Global สำหรับเก็บค่าตัวละครและสกินที่กำลังใช้งาน
  static ValueNotifier<Character?> currentCharacter = ValueNotifier(null);
  static ValueNotifier<Skin?> currentSkin = ValueNotifier(null);
  // สำหรับเก็บท่า Animation ที่ผู้ใช้กำลังใส่
  static ValueNotifier<String> currentIdle = ValueNotifier('idle');
  static ValueNotifier<String> currentReady = ValueNotifier('ready');
}

// ข้อมูลสมาชิก party รวม skin + animation
class PartyMember {
  final Skin skin;
  final String idleId;
  final String readyId;
  PartyMember({
    required this.skin,
    this.idleId = 'idle',
    this.readyId = 'ready',
  });
}
