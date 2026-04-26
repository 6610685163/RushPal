import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:o3d/o3d.dart';
import 'package:rushpal/theme/app_theme.dart';
import '../models/character_model.dart';
import 'package:rushpal/services/party_service.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final O3DController _controller = O3DController();
  Character? selectedCharacter;

  // เพิ่มตัวแปรนี้สำหรับเก็บท่าทางที่ผู้ใช้กดดู (พรีวิว)
  String? previewAnimation;

  // ป้องกัน Firestore snapshot ยิงทับค่าที่เพิ่ง equip ไป
  bool _isEquipping = false;

  // ตัวแปรสำหรับระบบเงินและไอเทม
  int userPoints = 0;
  List<String> inventory = [];
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  // รายการท่าทางที่ดึงมาจาก Database
  List<DocumentSnapshot> shopAnimations = [];

  @override
  void initState() {
    super.initState();
    selectedCharacter = PlayerState.currentCharacter.value;
    _listenToUserData(); // เรียกฟังก์ชันดึงข้อมูลเงินและของ
    _fetchShopAnimations(); // เรียกฟังก์ชันดึงท่าทางจากร้านค้า
  }

  @override
  void dispose() {
    _userSubscription?.cancel(); // ยกเลิกการดึงข้อมูลเมื่อปิดหน้า
    super.dispose();
  }

  // ฟังก์ชันดึงข้อมูลเงินและคลังไอเทมแบบ Real-time
  void _listenToUserData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data()!;
              final newIdle = data['equipped_idle'] ?? 'idle';
              final newReady = data['equipped_ready'] ?? 'ready';

              // อัปเดต ValueNotifier เฉพาะตอนที่ไม่ได้กำลัง equip อยู่
              // เพื่อป้องกัน snapshot เก่า overwrite ค่าใหม่ที่เพิ่ง equip
              if (!_isEquipping) {
                if (PlayerState.currentIdle.value != newIdle) {
                  PlayerState.currentIdle.value = newIdle;
                }
                if (PlayerState.currentReady.value != newReady) {
                  PlayerState.currentReady.value = newReady;
                }
              }

              if (mounted) {
                setState(() {
                  userPoints = data['points'] ?? 0;
                  inventory = List<String>.from(data['inventory'] ?? []);
                });
              }
            }
          });
    }
  }

  // ฟังก์ชันโหลดข้อมูลท่าทางจากคอลเลกชัน shop_items ในหมวดหมู่ Idle และ Ready
  Future<void> _fetchShopAnimations() async {
    try {
      debugPrint(" กำลังดึงข้อมูลจากคอลเลกชัน shop_items...");

      // ดึงข้อมูลทั้งหมดมาก่อน เพื่อแก้ปัญหาพิมพ์เล็ก/ใหญ่ หรือมีช่องว่างซ่อนอยู่
      final snapshot = await FirebaseFirestore.instance
          .collection('shop_items')
          .get();
      debugPrint(" เจอสินค้าในร้านทั้งหมด: ${snapshot.docs.length} ชิ้น");

      // คัดกรองเฉพาะหมวดหมู่ idle และ ready ในฝั่งแอป
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // ดึง category มาแปลงเป็นพิมพ์เล็กทั้งหมด และตัดช่องว่าง (space) ทิ้ง
        final cat = data['category']?.toString().trim().toLowerCase() ?? '';

        debugPrint(" ตรวจสอบไอเทม: ${data['name']} | หมวดหมู่ในระบบ: '$cat'");

        return cat == 'idle' ||
            cat == 'ready' ||
            cat == 'Idle' ||
            cat == 'Ready';
      }).toList();

      if (mounted) {
        setState(() {
          shopAnimations = filteredDocs;
        });
        debugPrint(
          " โหลดท่าทางสำเร็จ พร้อมแสดงผล: ${shopAnimations.length} ท่า",
        );
      }
    } catch (e) {
      debugPrint(" เกิดข้อผิดพลาดในการโหลดท่าทาง: $e");
    }
  }

  // ฟังก์ชันสวมใส่ชุด (เมื่อมีชุดนั้นแล้ว)
  Future<void> _equipSkin(Character char, Skin skin) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'characterId': char.id,
      'skinId': skin.id,
    });

    PlayerState.currentCharacter.value = char;
    PlayerState.currentSkin.value = skin;

    await PartyService.syncSkinToParty(skin.id, uid);

    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Equipped ${skin.name}!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 90, left: 20, right: 20),
        ),
      );
    }
  }

  // ฟังก์ชันสวมใส่ท่าทาง
  Future<void> _equipAnimation(String category, String animKey) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ล็อกไม่ให้ snapshot listener ทับค่า
    _isEquipping = true;

    String fieldToUpdate = category.toLowerCase() == 'idle'
        ? 'equipped_idle'
        : 'equipped_ready';

    // อัปเดต PlayerState ทันทีก่อน (ให้ UI response ไว)
    if (category.toLowerCase() == 'idle') {
      PlayerState.currentIdle.value = animKey;
    } else {
      PlayerState.currentReady.value = animKey;
    }

    // อัปเดต previewAnimation เพื่อให้โมเดล 3D เปลี่ยนท่าใน market หน้านี้ด้วย
    setState(() {
      previewAnimation = animKey;
    });

    // บันทึกลง Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      fieldToUpdate: animKey,
    });

    // ซิงค์ animation ให้เพื่อนในปาร์ตี้เห็นด้วย
    await PartyService.syncAnimationToParty(
      uid: uid,
      idleKey: PlayerState.currentIdle.value,
      readyKey: PlayerState.currentReady.value,
    );

    // ปล่อย lock หลังจาก snapshot มีเวลา settle (500ms)
    await Future.delayed(const Duration(milliseconds: 500));
    _isEquipping = false;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipped animation!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 90, left: 20, right: 20),
        ),
      );
    }
  }

  // เล่น animation ผ่านการ rebuild widget ด้วย ValueKey ใหม่
  void _playAnimation(String animKey) {
    setState(() {
      previewAnimation = animKey;
    });
  }

  // ฟังก์ชันซื้อไอเทม (ปรับให้รองรับทั้ง Skin และ Animation)
  Future<void> _buyItem(String itemId, String itemName, int price) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryPink),
      ),
    );

    try {
      // ใช้ Transaction เพื่อความปลอดภัยในการหักเงิน
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) throw Exception("User data not found");

        int currentPoints = snapshot.data()?['points'] ?? 0;
        List<dynamic> currentInventory = snapshot.data()?['inventory'] ?? [];

        if (currentInventory.contains(itemId)) {
          throw Exception("You already own this item");
        }

        if (currentPoints < price) {
          throw Exception("Not enough G");
        }

        // หักเงินและเพิ่มไอเทมเข้ากระเป๋า
        transaction.update(userRef, {
          'points': currentPoints - price,
          'inventory': FieldValue.arrayUnion([itemId]),
        });
      });

      if (mounted) Navigator.pop(context); // ปิด Loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully purchased $itemName!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 90, left: 20, right: 20),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // ปิด Loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 90, left: 20, right: 20),
        ),
      );
    }
  }

  // แจ้งเตือนยืนยันการซื้อ (รองรับทั้งชุดและท่าทาง)
  void _showBuyConfirmation(String itemId, String itemName, int price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Unlock Item?",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        content: Text("Do you want to unlock $itemName for $price G?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _buyItem(itemId, itemName, price);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Buy",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double bottomPadding = MediaQuery.of(context).padding.bottom + 10;

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: const Text(
          'CHARACTER SHOP',
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // แสดงจำนวนเงินมุมขวาบน
          Container(
            margin: const EdgeInsets.only(right: 15, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  "$userPoints G",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  bottom: 55,
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
                if (selectedCharacter != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: ValueListenableBuilder<Skin?>(
                      valueListenable: PlayerState.currentSkin,
                      builder: (context, currentSkin, child) {
                        if (currentSkin == null)
                          return const CircularProgressIndicator();
                        return O3D(
                          key: ValueKey(
                            currentSkin.modelPath +
                                selectedCharacter!.id +
                                (previewAnimation ?? ''),
                          ),
                          src: currentSkin.modelPath,
                          controller: _controller,
                          autoPlay: true,
                          cameraControls: false,
                          backgroundColor: Colors.transparent,
                          exposure: 1.0,
                          // ให้ดึงจาก previewAnimation ก่อน ถ้าไม่มีค่อยใช้ค่าเริ่มต้น
                          animationName:
                              previewAnimation ?? PlayerState.currentIdle.value,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 3. โซนเลือกสกินและท่าทาง (Bottom) ปรับปรุงให้มี Tab
          DefaultTabController(
            length: 2,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 10, bottom: bottomPadding),
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
                  const TabBar(
                    labelColor: AppTheme.primaryPink,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryPink,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(text: "SKINS"),
                      Tab(text: "ANIMATIONS"),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 140,
                    child: TabBarView(
                      children: [
                        // Tab 1: รายการสกิน (เหมือนของเดิม)
                        ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: selectedCharacter?.skins.length ?? 0,
                          itemBuilder: (context, index) {
                            final skin = selectedCharacter!.skins[index];

                            // เช็คว่ามีสกินนี้ในกระเป๋าไหม (อนุโลมให้สกินแรก index == 0 เป็นของฟรีเสมอ)
                            bool isOwned =
                                inventory.contains(skin.id) || index == 0;
                            bool isEquipped =
                                PlayerState.currentSkin.value?.id == skin.id;

                            // ราคาจำลอง (คุณสามารถเปลี่ยนไปดึงจาก skin.price ได้ถ้าในโมเดลมี)
                            int skinPrice = 500 * index;

                            return GestureDetector(
                              onTap: () {
                                if (isOwned) {
                                  _equipSkin(selectedCharacter!, skin);
                                } else {
                                  _showBuyConfirmation(
                                    skin.id,
                                    skin.name,
                                    skinPrice,
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 100,
                                margin: const EdgeInsets.only(
                                  right: 12,
                                  bottom: 5,
                                ),
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
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isOwned
                                              ? Icons.checkroom_rounded
                                              : Icons.lock_rounded,
                                          size: 28,
                                          color: isEquipped
                                              ? AppTheme.primaryPink
                                              : (isOwned
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade300),
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

                                        // แสดงสถานะ Active หรือ ราคา
                                        if (isEquipped)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryPink,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Text(
                                              "ACTIVE",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        else if (!isOwned)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              "$skinPrice G",
                                              style: const TextStyle(
                                                color: Colors.amber,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Tab 2: รายการท่าทาง (Idle และ Ready)
                        // ใช้ ValueListenableBuilder เพื่อให้ isEquipped อัปเดตทันทีหลัง equip
                        shopAnimations.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_run_rounded,
                                      size: 36,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No animations available',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ValueListenableBuilder<String>(
                                valueListenable: PlayerState.currentIdle,
                                builder: (context, currentIdle, _) {
                                  return ValueListenableBuilder<String>(
                                    valueListenable: PlayerState.currentReady,
                                    builder: (context, currentReady, _) {
                                      return ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        physics: const ClampingScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        itemCount: shopAnimations.length,
                                        itemBuilder: (context, index) {
                                          final animDoc = shopAnimations[index];
                                          final data =
                                              animDoc.data()
                                                  as Map<String, dynamic>;

                                          final animId = animDoc.id;
                                          final animName =
                                              data['name'] ?? 'Unknown';
                                          final price = data['price'] ?? 0;
                                          final category =
                                              data['category'] ?? 'idle';
                                          final animKey =
                                              data['animation_key'] ?? 'idle';

                                          bool isOwned =
                                              inventory.contains(animId) ||
                                              price == 0;
                                          // อ่านจาก ValueListenableBuilder แทน .value โดยตรง
                                          bool isEquipped =
                                              (category.toLowerCase() ==
                                                      'idle' &&
                                                  currentIdle == animKey) ||
                                              (category.toLowerCase() ==
                                                      'ready' &&
                                                  currentReady == animKey);

                                          return GestureDetector(
                                            onTap: () {
                                              if (isOwned) {
                                                _equipAnimation(
                                                  category,
                                                  animKey,
                                                );
                                              } else {
                                                _showBuyConfirmation(
                                                  animId,
                                                  animName,
                                                  price,
                                                );
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              width: 100,
                                              margin: const EdgeInsets.only(
                                                right: 12,
                                                bottom: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isEquipped
                                                    ? AppTheme.primaryPink
                                                          .withOpacity(0.05)
                                                    : Colors.grey.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                                border: Border.all(
                                                  color: isEquipped
                                                      ? AppTheme.primaryPink
                                                      : Colors.grey.shade200,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        isOwned
                                                            ? Icons
                                                                  .checkroom_rounded
                                                            : Icons
                                                                  .lock_rounded,
                                                        size: 28,
                                                        color: isEquipped
                                                            ? AppTheme
                                                                  .primaryPink
                                                            : isOwned
                                                            ? Colors
                                                                  .grey
                                                                  .shade400
                                                            : Colors
                                                                  .grey
                                                                  .shade300,
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        animName,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: isEquipped
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                    .normal,
                                                          color: isEquipped
                                                              ? AppTheme
                                                                    .primaryPink
                                                              : AppTheme
                                                                    .textLight,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      if (isEquipped)
                                                        Container(
                                                          margin:
                                                              const EdgeInsets.only(
                                                                top: 4,
                                                              ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme
                                                                .primaryPink,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                          child: const Text(
                                                            'ACTIVE',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 8,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        )
                                                      else if (!isOwned)
                                                        Container(
                                                          margin:
                                                              const EdgeInsets.only(
                                                                top: 4,
                                                              ),
                                                          child: Text(
                                                            '$price G',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .amber,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
