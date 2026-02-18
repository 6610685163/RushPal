import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/screens/login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. เปลี่ยนพื้นหลังเป็นสีแดง
      backgroundColor: AppTheme.primaryRed,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // โปร่งใส
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ), // ไอคอนสีขาว
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // 2. Header Text: Join RushPal
              Text(
                "Join\nRushPal",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // สีขาว
                  height: 1.2,
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Create an account to get started!",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),

              // Inputs (กล่องสีขาวเหมือนเดิม แต่พื้นหลังแดง)
              _buildTextField(hintText: "Username"),
              const SizedBox(height: 16),
              _buildTextField(hintText: "Email"),
              const SizedBox(height: 16),
              _buildTextField(hintText: "Password", isPassword: true),
              const SizedBox(height: 16),
              _buildTextField(hintText: "Confirm password", isPassword: true),

              const SizedBox(height: 30),

              // Register Button (ปุ่มขาว ตัวหนังสือแดง)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // ทำงานเมื่อกด Register
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // สีขาว
                    foregroundColor: AppTheme.primaryRed, // สีแดง
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Or Register with
              const Center(
                child: Text(
                  "Or Register with",
                  style: TextStyle(color: Colors.white70),
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
                      errorBuilder: (context, error, stackTrace) => const Icon(
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

              const SizedBox(height: 40),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.white), // สีขาว
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
                        color: Colors.white, // สีขาวตัวหนา
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
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

  Widget _buildTextField({required String hintText, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // สีขาว
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
        width: 100,
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
