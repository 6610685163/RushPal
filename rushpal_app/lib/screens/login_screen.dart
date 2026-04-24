import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/screens/register_screen.dart';
import 'package:rushpal/screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // เพิ่ม Controller
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  // ฟังก์ชัน Login
  Future<void> _login() async {
    setState(() {
      _isLoading = true; // เริ่มหมุน Loading
    });

    try {
      print("🔥 1. กำลังส่งข้อมูลอีเมล/รหัสผ่านไปที่ Firebase...");
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("✅ 2. Firebase ยืนยันตัวตนสำเร็จ!");

      if (mounted) {
        print("🚀 3. กำลังนำทางไปหน้า MainScreen...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      print("🚨 FIREBASE AUTH ERROR: ${e.code} - ${e.message}");

      String errorMessage = "เกิดข้อผิดพลาด กรุณาลองใหม่";
      if (e.code == 'user-not-found') {
        errorMessage = "ไม่พบอีเมลนี้ในระบบ";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage =
            "รหัสผ่านไม่ถูกต้อง!"; 
      } else if (e.code == 'invalid-email') {
        errorMessage = "รูปแบบอีเมลไม่ถูกต้อง";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red[800],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("🚨 UNKNOWN ERROR: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // หยุดหมุน Loading ไม่ว่าจะสำเร็จหรือพัง
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "RushPal",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPink,
                    fontSize: 48,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Run with your pal, anywhere.",
                  style: TextStyle(color: AppTheme.textLight, fontSize: 16),
                ),
                const SizedBox(height: 50),

                // Input: Email (ใส่ Controller)
                _buildTextField(
                  hintText: "Enter your email",
                  controller: emailController,
                ),
                const SizedBox(height: 16),

                // Input: Password (ใส่ Controller)
                _buildTextField(
                  hintText: "Enter your password",
                  isPassword: true,
                  controller: passwordController,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: AppTheme.primaryPink),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Button - Game Style
                _GameButton(
                  label: _isLoading ? "LOGGING IN..." : "LOGIN",
                  onPressed: _isLoading ? null : _login,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 40),

                const Center(
                  child: Text(
                    "Or Login with",
                    style: TextStyle(color: AppTheme.textLight),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      child: Image.asset(
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
                      onTap: () {},
                    ),
                    const SizedBox(width: 20),
                    _buildSocialButton(
                      child: const Icon(
                        Icons.facebook,
                        color: Colors.white,
                        size: 30,
                      ),
                      color: const Color(0xFF1877F2),
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppTheme.textLight),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Register Now",
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ปรับแก้รับ Controller
  Widget _buildTextField({
    required String hintText,
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.primaryPink.withOpacity(0.3), width: 2),
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
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
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onPressed == null ? null : (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: widget.onPressed == null ? null : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: _isPressed && !widget.isLoading ? 6.0 : 0.0),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.primaryPink,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppTheme.pureBlack,
            width: 3,
          ),
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
