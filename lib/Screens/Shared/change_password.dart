import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Widgets/common_button.dart';

const double _kWebBreak = 700;

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final oldPass = _oldCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirmPass = _confirmCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _snack('Please fill in all fields.', isError: true);
      return;
    }
    if (newPass.length < 8) {
      _snack('New password must be at least 8 characters.', isError: true);
      return;
    }
    if (newPass != confirmPass) {
      _snack('New passwords do not match.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final String? error = await AuthService.changePassword(
      oldPassword: oldPass,
      newPassword: newPass,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      _snack(error, isError: true);
    } else {
      _snack('Password updated successfully!');
      Navigator.pop(context);
    }
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : const Color(0xFFF47C20),
          behavior: SnackBarBehavior.floating,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;

    return Scaffold(
      backgroundColor: isWide ? const Color(0xFFF5F7FA) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Mobile only — web puts the button inside the form card
      bottomNavigationBar:
          isWide
              ? null
              : Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child:
                    _isSaving
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF47C20),
                          ),
                        )
                        : CommonButton(
                          text: 'Update Password',
                          onTap: _updatePassword,
                        ),
              ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 24 : 20,
            vertical: isWide ? 40 : 20,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: isWide ? _webCard() : _formContent(showButton: false),
          ),
        ),
      ),
    );
  }

  // ── Web: white card container with inline button ───────────────────────
  Widget _webCard() => Container(
    padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: _formContent(showButton: true),
  );

  // ── Shared form content ────────────────────────────────────────────────
  Widget _formContent({required bool showButton}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Create new password',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      Text(
        'Your new password must be different from previously used passwords.',
        style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
      ),
      const SizedBox(height: 30),

      _PasswordField(
        label: 'Old Password',
        hint: 'Enter old password',
        controller: _oldCtrl,
      ),
      const SizedBox(height: 20),
      _PasswordField(
        label: 'New Password',
        hint: 'Enter new password (min 8 chars)',
        controller: _newCtrl,
      ),
      const SizedBox(height: 20),
      _PasswordField(
        label: 'Confirm Password',
        hint: 'Re-enter new password',
        controller: _confirmCtrl,
      ),

      const SizedBox(height: 32),

      if (showButton)
        SizedBox(
          width: double.infinity,
          child:
              _isSaving
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF47C20)),
                  )
                  : CommonButton(
                    text: 'Update Password',
                    onTap: _updatePassword,
                  ),
        ),
    ],
  );
}

// ── Password field widget — unchanged from original ───────────────────────
class _PasswordField extends StatefulWidget {
  final String label, hint;
  final TextEditingController controller;
  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
  });
  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF47C20), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    ],
  );
}
