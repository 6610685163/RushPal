import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Controllers สำหรับระบบรหัสผ่าน
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedGender;
  // เพิ่ม '-' เป็นค่าเริ่มต้น
  final List<String> _genders = ['-', 'Male', 'Female', 'Other'];
  bool _isLoading = false;

  // เพิ่มตัวแปรนี้เพื่อป้องกันการกดปุ่มเปิดรูปเบิ้ลรัวๆ
  bool _isPickerActive = false;

  // ตัวแปรสำหรับรูปโปรไฟล์
  File? _imageFile;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ดึงข้อมูลผู้ใช้ปัจจุบันมาแสดง
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _emailController.text = user.email ?? '';

        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _usernameController.text = data['username'] ?? '';
            _profileImageUrl = data['profileImageUrl']; // ดึง URL รูปโปรไฟล์

            _selectedGender = data['gender'];
            if (_selectedGender == null ||
                !_genders.contains(_selectedGender)) {
              _selectedGender = '-'; // ค่าเริ่มต้นเป็น -
            }
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
    setState(() => _isLoading = false);
  }

  // ฟังก์ชันเลือกรูปจากเครื่อง
  Future<void> _pickImage() async {
    if (_isPickerActive) return; // ถ้ากำลังเปิดแกลเลอรี่อยู่ ให้บล็อกการกดซ้ำ
    _isPickerActive = true;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    } finally {
      // คืนค่าให้กลับมากดใหม่ได้เมื่อปิดแกลเลอรี่แล้ว
      _isPickerActive = false;
    }
  }

  // ฟังก์ชันบันทึกข้อมูล
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. ตรวจสอบว่าต้อง Re-authenticate ไหม (ถ้าเปลี่ยน Email หรือ Password ต้องใช้รหัสผ่านเดิมยืนยัน)
        bool isEmailChanged = _emailController.text.trim() != user.email;
        bool isPasswordChanged = _newPasswordController.text.isNotEmpty;

        if (isEmailChanged || isPasswordChanged) {
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!, // ต้องใช้อีเมลเก่าเพื่อยืนยัน
            password: _currentPasswordController.text,
          );
          // ยืนยันตัวตนซ้ำเพื่อความปลอดภัย
          await user.reauthenticateWithCredential(credential);

          if (isEmailChanged) {
            await user.verifyBeforeUpdateEmail(_emailController.text.trim());
          }
          if (isPasswordChanged) {
            await user.updatePassword(_newPasswordController.text);
          }
        }

        // 2. อัปโหลดรูปโปรไฟล์ (ใช้ Supabase)
        String? finalImageUrl = _profileImageUrl;
        if (_imageFile != null) {
          try {
            final supabase = Supabase.instance.client;

            // ตั้งชื่อไฟล์ใหม่ ป้องกันการ Cache รูปเดิม
            final fileName =
                '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

            // อัปโหลดขึ้น Supabase Storage ใน Bucket ชื่อ 'user_profiles'
            await supabase.storage
                .from('user_profiles')
                .upload(
                  fileName,
                  _imageFile!,
                  fileOptions: const FileOptions(
                    cacheControl: '3600',
                    upsert: true,
                  ),
                );

            // ขอ URL รูปภาพแบบ Public เพื่อเอาไปเก็บใน Firestore
            finalImageUrl = supabase.storage
                .from('user_profiles')
                .getPublicUrl(fileName);
          } catch (storageError) {
            print("Supabase Upload Error: $storageError");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to upload image'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() => _isLoading = false); // หยุดโหลด
            return; // หยุดการเซฟถ้าอัปโหลดรูปไม่ผ่าน
          }
        }

        // 3. อัปเดตข้อมูลอื่นๆ ใน Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'username': _usernameController.text.trim(),
              'gender': _selectedGender,
              'profileImageUrl': finalImageUrl,
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context); // กลับไปหน้าก่อนหน้าเมื่อเซฟเสร็จ
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        // ดัก Error เช่น ใส่รหัสผ่านเดิมผิด
        String errorMessage = e.message ?? 'Update failed.';
        if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
          errorMessage = 'Current password is incorrect.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  // สร้าง Widget ช่องกรอกข้อมูล
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryPink),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: const Text(
          'ACCOUNT',
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryPink),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // รูปโปรไฟล์แบบกดแก้ไขได้
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: AppTheme.primaryPink.withOpacity(
                              0.2,
                            ),
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                            as ImageProvider
                                      : null),
                            child:
                                _imageFile == null && _profileImageUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 55,
                                    color: AppTheme.primaryPink,
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPink,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Username
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person_outline,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter username' : null,
                    ),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter email';
                        if (!value.contains('@'))
                          return 'Invalid email address';
                        return null;
                      },
                    ),

                    // Gender (Dropdown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: const Icon(
                            Icons.wc,
                            color: AppTheme.primaryPink,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        items: _genders.map((String gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (String? newValue) =>
                            setState(() => _selectedGender = newValue),
                      ),
                    ),

                    const Divider(),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Change Password / Email Security",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // รหัสผ่านเดิม (บังคับใส่ถ้าจะเปลี่ยนอีเมลหรือรหัสผ่านใหม่)
                    _buildTextField(
                      controller: _currentPasswordController,
                      label: 'Current Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (value) {
                        bool isEmailChanged =
                            _emailController.text.trim() !=
                            FirebaseAuth.instance.currentUser?.email;
                        bool isPasswordChanging =
                            _newPasswordController.text.isNotEmpty;

                        if ((isEmailChanged || isPasswordChanging) &&
                            (value == null || value.isEmpty)) {
                          return 'กรุณาใส่รหัสผ่านเดิมเพื่อยืนยันการเปลี่ยนแปลง';
                        }
                        return null;
                      },
                    ),

                    // รหัสผ่านใหม่
                    _buildTextField(
                      controller: _newPasswordController,
                      label: 'New Password',
                      icon: Icons.lock_reset,
                      isPassword: true,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 6) {
                          return 'รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร';
                        }
                        return null;
                      },
                    ),

                    // ยืนยันรหัสผ่านใหม่
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm New Password',
                      icon: Icons.check_circle_outline,
                      isPassword: true,
                      validator: (value) {
                        if (_newPasswordController.text.isNotEmpty &&
                            value != _newPasswordController.text) {
                          return 'รหัสผ่านใหม่ไม่ตรงกัน';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    // ปุ่ม Save Changes
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          shadowColor: AppTheme.primaryPink.withOpacity(0.5),
                        ),
                        child: const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
