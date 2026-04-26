import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rushpal/theme/app_theme.dart';
import '../models/character_model.dart';
import 'main_screen.dart'; // Fix: navigate to MainScreen so navbar works

class SelectCharacterScreen extends StatefulWidget {
  const SelectCharacterScreen({super.key});

  @override
  State<SelectCharacterScreen> createState() => _SelectCharacterScreenState();
}

class _SelectCharacterScreenState extends State<SelectCharacterScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  Future<void> _selectCharacter(Character character) async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final defaultSkin = character.skins.first;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'characterId': character.id,
        'skinId': defaultSkin.id,
      }, SetOptions(merge: true));

      PlayerState.currentCharacter.value = character;
      PlayerState.currentSkin.value = defaultSkin;

      if (mounted) {
        // Fix: push MainScreen so the navbar (bottom nav) is present
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      debugPrint("Error selecting character: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: SafeArea(
        child: Stack(
          children: [
            // Background texture dots
            Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.pureBlack,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.pureBlack,
                              blurRadius: 0,
                              offset: Offset(2, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'NEW RUNNER',
                          style: TextStyle(
                            color: AppTheme.pureBlack,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Choose Your\nCharacter',
                        style: TextStyle(
                          color: AppTheme.pureBlack,
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pick your running buddy — you can change\nskins later in the Shop!',
                        style: TextStyle(
                          color: AppTheme.textLight.withOpacity(0.7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Character cards row
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: List.generate(myCharacters.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index < myCharacters.length - 1 ? 12 : 0,
                            ),
                            child: _CharacterCard(
                              character: myCharacters[index],
                              isSelected: _selectedIndex == index,
                              onTap: () =>
                                  setState(() => _selectedIndex = index),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Confirm button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryPink,
                          ),
                        )
                      : GestureDetector(
                          onTap: () =>
                              _selectCharacter(myCharacters[_selectedIndex]),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPink,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.pureBlack,
                                width: 2.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppTheme.pureBlack,
                                  blurRadius: 0,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "LET'S GO WITH ${myCharacters[_selectedIndex].name.toUpperCase()}",
                                  style: const TextStyle(
                                    color: AppTheme.pureBlack,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppTheme.pureBlack,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character character;
  final bool isSelected;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPink : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.pureBlack,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.pureBlack,
              blurRadius: 0,
              offset: isSelected ? const Offset(0, 6) : const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.pureBlack.withOpacity(0.12)
                      : AppTheme.backgroundCream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.pureBlack, width: 2.5),
                ),
                child: Icon(
                  character.gender == 'Male'
                      ? Icons.boy_rounded
                      : Icons.girl_rounded,
                  size: 56,
                  color: isSelected ? AppTheme.pureBlack : AppTheme.primaryPink,
                ),
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                character.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.pureBlack,
                ),
              ),

              const SizedBox(height: 4),

              // Gender badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.pureBlack.withOpacity(0.15)
                      : AppTheme.primaryPink.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  character.gender.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppTheme.pureBlack : AppTheme.textLight,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Skins count
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.style_rounded,
                    size: 14,
                    color: isSelected
                        ? AppTheme.pureBlack.withOpacity(0.6)
                        : AppTheme.textLight.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${character.skins.length} skins',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppTheme.pureBlack.withOpacity(0.6)
                          : AppTheme.textLight.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              if (isSelected) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.pureBlack,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    '✓ SELECTED',
                    style: TextStyle(
                      color: AppTheme.primaryPink,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Subtle dot pattern background painter
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.pureBlack.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
