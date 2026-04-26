import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggingOut = false;

  // ── Logout พร้อม Dialog ยืนยัน ──────────────────────────────────────────
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  // ── Info Dialog (About / Privacy / Terms) ────────────────────────────────
  void _showInfoDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Account Settings ─────────────────────────────────────────
            _buildSectionHeader('Account Settings'),
            const SizedBox(height: 10),

            _buildMenuTile(
              title: 'Your Account',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),

            const SizedBox(height: 30),

            // ── More ─────────────────────────────────────────────────────
            _buildSectionHeader('More'),
            const SizedBox(height: 10),

            _buildMenuTile(
              title: 'About us',
              onTap: () => _showInfoDialog(
                'About us',
                'RushPal is a running companion app that helps you track your runs, '
                    'compete with friends, and stay motivated.\n\n'
                    'Version 1.0.0',
              ),
            ),
            _buildMenuTile(
              title: 'Privacy policy',
              onTap: () => _showInfoDialog(
                'Privacy policy',
                'We collect only the data necessary to provide our services, '
                    'including your email, profile information, and run data. '
                    'We do not sell your personal data to third parties. '
                    'Your data is stored securely on Firebase servers.\n\n'
                    'For questions, contact us at kengthbd@gmail.com',
              ),
            ),
            _buildMenuTile(
              title: 'Terms and conditions',
              onTap: () => _showInfoDialog(
                'Terms and conditions',
                'By using RushPal you agree to our terms of service. '
                    'You must be at least 13 years old to use this app. '
                    'You are responsible for keeping your account secure. '
                    'We reserve the right to suspend accounts that violate our policies.\n\n'
                    'Last updated: April 2026',
              ),
            ),

            const SizedBox(height: 40),

            // ── Log out ──────────────────────────────────────────────────
            _isLoggingOut
                ? const Center(child: CircularProgressIndicator())
                : InkWell(
                    onTap: _handleLogout,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
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
}
