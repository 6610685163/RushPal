import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/screens/register_screen.dart';
import 'package:rushpal/screens/main_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Header Text: Welcome back!
              Text(
                "Welcome back!\nGlad to see you, Again!",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 40),

              // Input: Email
              _buildTextField(hintText: "Enter your email"),
              const SizedBox(height: 16),

              // Input: Password
              _buildTextField(
                hintText: "Enter your password",
                isPassword: true,
              ),

              // Forgot Password?
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Or Login with
              const Center(
                child: Text(
                  "Or Login with",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              // Social Buttons (Google ขึ้นก่อน)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Google Button (ใช้รูปภาพจริง)
                  _buildSocialButton(
                    // ⚠️ อย่าลืมเอารูป google.png ไปใส่ใน assets/images/ นะครับ
                    child: Image.asset(
                      'assets/images/google.png',
                      height: 24, // ขนาดโลโก้
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.g_mobiledata,
                        size: 40,
                        color: Colors.blue,
                      ), // Fallback ถ้าหารูปไม่เจอ
                    ),
                    color: Colors.white,
                    onTap: () {},
                  ),

                  const SizedBox(width: 20),

                  // 2. Facebook Button
                  _buildSocialButton(
                    child: const Icon(
                      Icons.facebook,
                      color: Colors.white,
                      size: 30,
                    ),
                    color: const Color(0xFF1877F2), // Facebook Blue
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.black),
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
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String hintText, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: TextField(
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

  // ปรับแก้ให้รับ Widget child แทน IconData เพื่อใส่ Image ได้
  Widget _buildSocialButton({
    required Widget child, // รับ Widget ข้างใน (รูป หรือ ไอคอน)
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8ECF4)),
        ),
        child: Center(child: child), // จัดกึ่งกลาง
      ),
    );
  }
}
