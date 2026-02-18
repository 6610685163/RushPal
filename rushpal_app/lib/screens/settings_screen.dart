import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ตัวแปรสำหรับเก็บค่า Switch (จำลองการทำงาน)
  bool _pushNotifications = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // ปุ่มย้อนกลับ <
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // หัวข้อ Settings
        title: Text(
          "Settings",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Account Settings
            _buildSectionHeader("Account Settings"),
            const SizedBox(height: 10),

            _buildMenuTile(
              title: "Edit profile",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            _buildMenuTile(title: "Change password", onTap: () {}),

            // Switch: Push notifications
            _buildSwitchTile(
              title: "Push notifications",
              value: _pushNotifications,
              onChanged: (val) {
                setState(() => _pushNotifications = val);
              },
            ),

            // Switch: Dark mode
            _buildSwitchTile(
              title: "Dark mode",
              value: _darkMode,
              onChanged: (val) {
                setState(() => _darkMode = val);
              },
            ),

            const SizedBox(height: 30),

            // Section: More
            _buildSectionHeader("More"),
            const SizedBox(height: 10),

            _buildMenuTile(title: "About us", onTap: () {}),
            _buildMenuTile(title: "Privacy policy", onTap: () {}),
            _buildMenuTile(title: "Terms and conditions", onTap: () {}),

            const SizedBox(height: 40),

            // Log out Button
            _buildLogoutButton(context),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black, // หรือ textDark
      ),
    );
  }

  Widget _buildMenuTile({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryRed,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // Log out -> กลับไปหน้า Login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          "Log out",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red, // สีแดงสำหรับปุ่ม Logout
          ),
        ),
      ),
    );
  }
}
