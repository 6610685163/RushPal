import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/screens/register_screen.dart';
import 'package:rushpal/screens/main_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. เปลี่ยนพื้นหลังเป็นสีแดง
      backgroundColor: AppTheme.primaryRed,
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
                // 2. Header Text
                Text(
                  "RushPal",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 48,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Run with your pal, anywhere.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 50),

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
                      style: TextStyle(color: Colors.white),
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
                      backgroundColor: Colors.white, // พื้นปุ่มสีขาว
                      foregroundColor: AppTheme.primaryRed, // ตัวหนังสือสีแดง
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Or Login with
                const Center(
                  child: Text(
                    "Or Login with",
                    style: TextStyle(
                      color: Colors.white70,
                    ), // ปรับสีจางลง
                  ),
                ),
                const SizedBox(height: 20),

                // Social Buttons
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

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.white),
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration:
                              TextDecoration.underline,
                          decorationColor: Colors.white,
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

  Widget _buildTextField({required String hintText, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // ช่องกรอกข้อมูล
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
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
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
