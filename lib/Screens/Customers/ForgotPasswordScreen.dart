import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const double _kForgotWebBreak = 950;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isEmailSent = false;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEmailSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent! Check your email.'),
            backgroundColor: Color(0xFFF47C20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String msg = 'An error occurred';
        if (e.code == 'user-not-found') {
          msg = 'No user found with this email.';
        } else if (e.code == 'invalid-email') {
          msg = 'Please enter a valid email address.';
        } else {
          msg = e.message ?? 'Failed to send reset email.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kForgotWebBreak;
    return isWide ? _buildWebLayout() : _buildMobileLayout();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB LAYOUT — branding left, form card right
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Left branding panel
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 60,
                    right: 50,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    left: 40,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          // Big icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_reset,
                              size: 52,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Forgot\nPassword?',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Don't worry! It happens. We'll send a reset link to your email address.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.88),
                              height: 1.6,
                            ),
                          ),
                          const Spacer(),
                          // Logo row at bottom
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/venuemate.png',
                                height: 36,
                                width: 36,
                                errorBuilder:
                                    (_, __, ___) => const Icon(
                                      Icons.location_city,
                                      size: 36,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'VenueMate',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right form panel
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _buildFormContent(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT (unchanged)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFF47C20)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF47C20).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 60,
                        color: Color(0xFFF47C20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Don't worry! It happens. Please enter the email address associated with your account.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildFormContent(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared form content (form + success state + back to login) ─────────────
  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isEmailSent) ...[
          const Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your registered email address.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFFF47C20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFF47C20),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter your email';
                    }
                    final emailRegex = RegExp(
                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                    );
                    if (!emailRegex.hasMatch(v)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF47C20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Send Reset Link',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Success state
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF47C20).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF47C20).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF47C20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Email Sent!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a reset link to',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _emailController.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF47C20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Check your inbox and click the link to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _isEmailSent = false),
              icon: const Icon(Icons.refresh, color: Color(0xFFF47C20)),
              label: const Text(
                'Resend Email',
                style: TextStyle(
                  color: Color(0xFFF47C20),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 28),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remember your password? ',
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Color(0xFFF47C20),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
