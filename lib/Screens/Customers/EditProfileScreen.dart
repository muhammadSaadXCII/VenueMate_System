import 'dart:io';
import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/user_service.dart';
import 'package:venuemate_system/Services/storage_service.dart';
import 'package:venuemate_system/Models/user_model.dart';

const Color kPrimaryColor = Color(0xFFF47C20);

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  UserModel? _userModel;
  File? _newProfileImage;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '';

    List<String> parts = name.trim().split(' ');

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ── Load current user data from Firestore ─────────────────────────────────
  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _userModel = user;
      _nameController.text = user?.name ?? '';
      _phoneController.text = user?.phone ?? '';
      _isLoading = false;
    });
  }

  // ── Pick a new profile image from gallery ─────────────────────────────────
  Future<void> _pickImage() async {
    final File? file = await StorageService.pickImageFromGallery();
    if (file != null && mounted) {
      setState(() => _newProfileImage = file);
    }
  }

  // ── Save changes to Firestore (and Storage if image changed) ──────────────
  Future<void> _saveChanges() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    // 1. Upload new profile image if selected
    if (_newProfileImage != null) {
      final String? imgError = await UserService.updateProfileImage(
        uid: uid,
        imageFile: _newProfileImage!,
      );
      if (imgError != null && mounted) {
        _showSnack(imgError, isError: true);
        setState(() => _isSaving = false);
        return;
      }
    }

    // 2. Update name and phone
    final String? profileError = await UserService.updateProfile(
      uid: uid,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (profileError != null) {
      _showSnack(profileError, isError: true);
    } else {
      _showSnack('Profile updated successfully!');
      Navigator.pop(context); // go back to ProfileScreen
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : kPrimaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              )
              : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // ── Profile Picture ───────────────────────────────
                            Center(
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 130,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child:
                                          _newProfileImage != null ||
                                                  (_userModel
                                                          ?.profileImageUrl
                                                          .isNotEmpty ==
                                                      true)
                                              ? ClipOval(
                                                child: Image(
                                                  fit: BoxFit.cover,
                                                  image:
                                                      _newProfileImage != null
                                                          ? FileImage(
                                                            _newProfileImage!,
                                                          )
                                                          : NetworkImage(
                                                                _userModel!
                                                                    .profileImageUrl,
                                                              )
                                                              as ImageProvider,
                                                ),
                                              )
                                              : Container(
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      Colors
                                                          .primaries[(_userModel
                                                                  ?.name
                                                                  .hashCode ??
                                                              0) %
                                                          Colors
                                                              .primaries
                                                              .length],
                                                ),
                                                child: Text(
                                                  _getInitials(
                                                    _userModel?.name ?? '',
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 40,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                    ),
                                    // Camera badge
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          color: kPrimaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _userModel?.email ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ── Form Fields ───────────────────────────────────
                            _buildSectionHeader('Personal Information'),
                            const SizedBox(height: 15),

                            _buildField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 20),

                            _buildField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              inputType: TextInputType.phone,
                            ),
                            const SizedBox(height: 20),

                            // Email is read-only (Firebase Auth email)
                            _buildField(
                              controller: TextEditingController(
                                text: _userModel?.email ?? '',
                              ),
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              readOnly: true,
                            ),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),

                    // ── Save Button ───────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child:
                              _isSaving
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    'Update Profile',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        readOnly: readOnly,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        cursorColor: kPrimaryColor,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: readOnly ? Colors.grey[400] : Colors.grey[400],
          ),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500]),
          floatingLabelStyle: TextStyle(
            color: readOnly ? Colors.grey : kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: readOnly ? Colors.grey[300]! : kPrimaryColor,
              width: 1.5,
            ),
          ),
          fillColor: readOnly ? Colors.grey[50] : null,
          filled: readOnly,
        ),
      ),
    );
  }
}
