import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // ฟังก์ชัน Register ด้วย Email
  Future<void> _register() async {
    if (passwordController.text != confirmController.text) {
      _showSnackBar("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // สร้าง User ใน Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // บันทึกข้อมูลลง Firestore (เพิ่มช่องเก็บเงินและของ)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'username': usernameController.text.trim(),
            'email': emailController.text.trim(),
            'created_at': Timestamp.now(),
            // --- เพิ่มข้อมูลตั้งต้นตรงนี้ ---
            'points': 1000,
            'inventory': [],
            'level': 1,
            'exp': 0,
            'characterId': '',
            'skinId': '',
          });

      if (mounted) {
        Navigator.pop(context); // กลับไปหน้า Login
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "เกิดข้อผิดพลาด กรุณาลองใหม่";
      if (e.code == 'weak-password') {
        errorMsg = "รหัสผ่านอ่อนเกินไป";
      } else if (e.code == 'email-already-in-use') {
        errorMsg = "อีเมลนี้มีผู้ใช้งานแล้ว";
      } else if (e.code == 'invalid-email') {
        errorMsg = "รูปแบบอีเมลไม่ถูกต้อง";
      }
      _showSnackBar(errorMsg);
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชัน Register ด้วย Google
  Future<void> _registerWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // ตรวจสอบว่ามีข้อมูลผู้ใช้นี้ใน Firestore หรือยัง ถ้ายังให้สร้างใหม่
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'username': userCredential.user!.displayName ?? 'Google User',
              'email': userCredential.user!.email,
              'created_at': Timestamp.now(),
              // --- เพิ่มข้อมูลตั้งต้นตรงนี้ด้วย (เผื่อคนล็อกอิน Google ครั้งแรก) ---
              'points': 1000,
              'inventory': [],
              'level': 1,
              'characterId': '',
              'skinId': '',
            });
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar("เกิดข้อผิดพลาดจากระบบ: ${e.message}");
    } catch (e) {
      print("GOOGLE ERROR: $e");
      _showSnackBar("เข้าสู่ระบบด้วย Google ล้มเหลว");
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red[800],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // เพิ่มรูปภาพ app_logo.jpg ไว้บนสุดของหน้าและจัดกึ่งกลาง
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    height:
                        100, // ปรับให้เล็กกว่าหน้า Login นิดหน่อยเพื่อความเหมาะสม
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Join\nRushPal",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPink,
                  height: 1.2,
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Create an account to get started!",
                style: TextStyle(color: AppTheme.textLight, fontSize: 16),
              ),
              const SizedBox(height: 30),

              // Inputs
              _buildTextField(
                hintText: "Username",
                controller: usernameController,
              ),
              const SizedBox(height: 16),
              _buildTextField(hintText: "Email", controller: emailController),
              const SizedBox(height: 16),
              _buildTextField(
                hintText: "Password",
                isPassword: true,
                controller: passwordController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                hintText: "Confirm password",
                isPassword: true,
                controller: confirmController,
              ),

              const SizedBox(height: 30),

              // Register Button - Game Style
              _GameButton(
                label: _isLoading ? "REGISTERING..." : "REGISTER",
                onPressed: _isLoading ? null : _register,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 30),

              const Center(
                child: Text(
                  "Or Register with",
                  style: TextStyle(color: AppTheme.textLight),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google Button
                  _buildSocialButton(
                    child: _isGoogleLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.blue,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Image.asset(
                            'assets/images/google.png',
                            height: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.g_mobiledata,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                          ),
                    color: Colors.white,
                    onTap: _isGoogleLoading ? null : _registerWithGoogle,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: AppTheme.textLight),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Login Now",
                      style: TextStyle(
                        color: AppTheme.primaryPink,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.primaryPink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget child,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.pureBlack, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.pureBlack.withOpacity(0.2),
              blurRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _GameButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GameButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  _GameButtonState createState() => _GameButtonState();
}

class _GameButtonState extends State<_GameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: widget.onPressed == null
          ? null
          : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(
          top: _isPressed && !widget.isLoading ? 6.0 : 0.0,
        ),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.primaryPink,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.pureBlack, width: 3),
          boxShadow: _isPressed || widget.isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.pureBlack,
                    blurRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.pureBlack,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color: AppTheme.pureBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}
