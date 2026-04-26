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
  String? previewAnimation;
  bool _isEquipping = false;
  int userPoints = 0;
  List<String> inventory = [];
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  List<DocumentSnapshot> shopAnimations = [];

  @override
  void initState() {
    super.initState();
    // ใช้ค่าจาก PlayerState ก่อน ถ้า null ให้ fallback เป็น character แรกทันที
    selectedCharacter =
        PlayerState.currentCharacter.value ?? myCharacters.first;
    if (PlayerState.currentSkin.value == null) {
      PlayerState.currentSkin.value = selectedCharacter!.skins.first;
    }
    _initFromFirestore();
    _listenToUserData();
    _fetchShopAnimations();
  }

  // โหลดข้อมูล user ครั้งแรกแบบ one-shot ก่อน listener จะพร้อม
  Future<void> _initFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists || doc.data() == null) return;
      final data = doc.data()!;
      final charId = data['characterId'];
      final skinId = data['skinId'];
      final idle = data['equipped_idle'] ?? 'idle';
      final ready = data['equipped_ready'] ?? 'ready';
      final points = data['points'] ?? 0;
      final inv = List<String>.from(data['inventory'] ?? []);

      Character? foundChar;
      Skin? foundSkin;
      if (charId != null && skinId != null) {
        try {
          foundChar = myCharacters.firstWhere((c) => c.id == charId);
          foundSkin = foundChar.skins.firstWhere((s) => s.id == skinId);
        } catch (_) {}
      }

      PlayerState.currentCharacter.value = foundChar ?? myCharacters.first;
      PlayerState.currentSkin.value =
          foundSkin ?? myCharacters.first.skins.first;
      PlayerState.currentIdle.value = idle;
      PlayerState.currentReady.value = ready;

      if (mounted) {
        setState(() {
          selectedCharacter = foundChar ?? myCharacters.first;
          userPoints = points;
          inventory = inv;
        });
      }
    } catch (e) {
      debugPrint('initFromFirestore error: $e');
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

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
              if (!_isEquipping) {
                if (PlayerState.currentIdle.value != newIdle)
                  PlayerState.currentIdle.value = newIdle;
                if (PlayerState.currentReady.value != newReady)
                  PlayerState.currentReady.value = newReady;
              }

              // ถ้า PlayerState.currentSkin ยังเป็น null ให้ sync จาก Firestore ทันที
              if (PlayerState.currentSkin.value == null) {
                final charId = data['characterId'];
                final skinId = data['skinId'];
                if (charId != null && skinId != null) {
                  try {
                    final foundChar = myCharacters.firstWhere(
                      (c) => c.id == charId,
                    );
                    final foundSkin = foundChar.skins.firstWhere(
                      (s) => s.id == skinId,
                    );
                    PlayerState.currentCharacter.value = foundChar;
                    PlayerState.currentSkin.value = foundSkin;
                    if (mounted) setState(() => selectedCharacter = foundChar);
                  } catch (_) {}
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

  Future<void> _fetchShopAnimations() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('shop_items')
          .get();
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final cat = data['category']?.toString().trim().toLowerCase() ?? '';
        return cat == 'idle' || cat == 'ready';
      }).toList();
      if (mounted) setState(() => shopAnimations = filteredDocs);
    } catch (e) {
      debugPrint('Error fetching animations: $e');
    }
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

  Future<void> _equipAnimation(String category, String animKey) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _isEquipping = true;
    String fieldToUpdate = category.toLowerCase() == 'idle'
        ? 'equipped_idle'
        : 'equipped_ready';
    if (category.toLowerCase() == 'idle') {
      PlayerState.currentIdle.value = animKey;
    } else {
      PlayerState.currentReady.value = animKey;
    }
    setState(() => previewAnimation = animKey);
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      fieldToUpdate: animKey,
    });
    await PartyService.syncAnimationToParty(
      uid: uid,
      idleKey: PlayerState.currentIdle.value,
      readyKey: PlayerState.currentReady.value,
    );
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
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) throw Exception("User data not found");
        int currentPoints = snapshot.data()?['points'] ?? 0;
        List<dynamic> currentInventory = snapshot.data()?['inventory'] ?? [];
        if (currentInventory.contains(itemId))
          throw Exception("You already own this item");
        if (currentPoints < price) throw Exception("Not enough G");
        transaction.update(userRef, {
          'points': currentPoints - price,
          'inventory': FieldValue.arrayUnion([itemId]),
        });
      });
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully purchased $itemName!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 90, left: 20, right: 20),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
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

  void _showBuyConfirmation(String itemId, String itemName, int price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.pureBlack, width: 2),
        ),
        title: const Text(
          "Unlock Item?",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.pureBlack,
            letterSpacing: 0.5,
          ),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.monetization_on_rounded,
              color: Colors.amber,
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "Unlock $itemName for $price G?",
                style: const TextStyle(color: AppTheme.textLight),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          _GameButton(
            label: "BUY",
            small: true,
            onPressed: () {
              Navigator.pop(context);
              _buyItem(itemId, itemName, price);
            },
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
            color: AppTheme.pureBlack,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // ── 1. Character selector + Coin ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 86,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: myCharacters.map((char) {
                        bool isSelected = selectedCharacter?.id == char.id;
                        return GestureDetector(
                          onTap: () => setState(() => selectedCharacter = char),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 76,
                            margin: const EdgeInsets.only(right: 12, bottom: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryPink
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppTheme.pureBlack,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppTheme.pureBlack,
                                  blurRadius: 0,
                                  offset: Offset(0, 4),
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
                                  size: 30,
                                  color: AppTheme.pureBlack,
                                ),
                                Text(
                                  char.name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.pureBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Coin — เล็ก ไม่มี glow สไตล์เดียวกัน
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.pureBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.pureBlack,
                        blurRadius: 0,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$userPoints G",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: AppTheme.pureBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 2. 3D Model ──
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 67,
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
                        // ใช้ skin ที่ equip อยู่ ถ้า null ให้ fallback เป็น skin แรกของ character ที่เลือก
                        final displaySkin =
                            currentSkin ?? selectedCharacter!.skins.first;
                        return O3D(
                          key: ValueKey(
                            displaySkin.modelPath +
                                selectedCharacter!.id +
                                (previewAnimation ?? ''),
                          ),
                          src: displaySkin.modelPath,
                          controller: _controller,
                          autoPlay: true,
                          cameraControls: true,
                          backgroundColor: Colors.transparent,
                          exposure: 1.0,
                          animationName:
                              previewAnimation ?? PlayerState.currentIdle.value,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── 3. Bottom panel ──
          DefaultTabController(
            length: 2,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 14, bottom: bottomPadding),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundCream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: AppTheme.pureBlack, width: 2.5),
                  left: BorderSide(color: AppTheme.pureBlack, width: 2.5),
                  right: BorderSide(color: AppTheme.pureBlack, width: 2.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.pureBlack,
                    blurRadius: 0,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tab bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.pureBlack, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.pureBlack,
                            blurRadius: 0,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TabBar(
                        labelColor: AppTheme.pureBlack,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        indicator: BoxDecoration(
                          color: AppTheme.primaryPink,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.pureBlack,
                            width: 1.5,
                          ),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: "SKINS"),
                          Tab(text: "ANIMATIONS"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 128,
                    child: TabBarView(
                      children: [
                        // Skins
                        ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: selectedCharacter?.skins.length ?? 0,
                          itemBuilder: (context, index) {
                            final skin = selectedCharacter!.skins[index];
                            bool isOwned =
                                inventory.contains(skin.id) || index == 0;
                            bool isEquipped =
                                PlayerState.currentSkin.value?.id == skin.id;
                            int skinPrice = 500 * index;
                            return _ShopCard(
                              label: skin.name,
                              isOwned: isOwned,
                              isEquipped: isEquipped,
                              price: skinPrice,
                              onTap: () => isOwned
                                  ? _equipSkin(selectedCharacter!, skin)
                                  : _showBuyConfirmation(
                                      skin.id,
                                      skin.name,
                                      skinPrice,
                                    ),
                            );
                          },
                        ),
                        // Animations
                        shopAnimations.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_run_rounded,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 6),
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
                                          bool isEquipped =
                                              (category.toLowerCase() ==
                                                      'idle' &&
                                                  currentIdle == animKey) ||
                                              (category.toLowerCase() ==
                                                      'ready' &&
                                                  currentReady == animKey);
                                          return _ShopCard(
                                            label: animName,
                                            isOwned: isOwned,
                                            isEquipped: isEquipped,
                                            price: price,
                                            isAnimation: true,
                                            onTap: () => isOwned
                                                ? _equipAnimation(
                                                    category,
                                                    animKey,
                                                  )
                                                : _showBuyConfirmation(
                                                    animId,
                                                    animName,
                                                    price,
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

// ── Shop Card — สไตล์ TAP TO RUN (border ดำ + shadow offset) ──
class _ShopCard extends StatefulWidget {
  final String label;
  final bool isOwned;
  final bool isEquipped;
  final int price;
  final bool isAnimation;
  final VoidCallback onTap;

  const _ShopCard({
    required this.label,
    required this.isOwned,
    required this.isEquipped,
    required this.price,
    required this.onTap,
    this.isAnimation = false,
  });

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.isEquipped ? AppTheme.primaryPink : Colors.white;
    final Color fg = AppTheme.pureBlack;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 88,
        margin: EdgeInsets.only(right: 12, bottom: 4, top: _pressed ? 4 : 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.pureBlack, width: 2),
          boxShadow: _pressed
              ? []
              : const [
                  BoxShadow(
                    color: AppTheme.pureBlack,
                    blurRadius: 0,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isOwned
                  ? (widget.isAnimation
                        ? Icons.directions_run_rounded
                        : Icons.checkroom_rounded)
                  : Icons.lock_rounded,
              size: 26,
              color: widget.isOwned ? fg : Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: widget.isEquipped
                      ? FontWeight.w900
                      : FontWeight.w600,
                  color: fg,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 3),
            if (widget.isEquipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.pureBlack,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "ACTIVE",
                  style: TextStyle(
                    color: AppTheme.primaryPink,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            else if (!widget.isOwned)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Colors.amber,
                    size: 11,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    "${widget.price} G",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

// ── Game Button (สำหรับ dialog BUY) ──
class _GameButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool small;

  const _GameButton({
    required this.label,
    required this.onPressed,
    this.small = false,
  });

  @override
  State<_GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<_GameButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: _pressed ? 4 : 0),
        padding: EdgeInsets.symmetric(
          horizontal: widget.small ? 20 : 32,
          vertical: widget.small ? 8 : 14,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryPink,
          borderRadius: BorderRadius.circular(widget.small ? 12 : 20),
          border: Border.all(color: AppTheme.pureBlack, width: 2),
          boxShadow: _pressed
              ? []
              : const [
                  BoxShadow(
                    color: AppTheme.pureBlack,
                    blurRadius: 0,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: AppTheme.pureBlack,
            fontWeight: FontWeight.w900,
            fontSize: widget.small ? 13 : 16,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
