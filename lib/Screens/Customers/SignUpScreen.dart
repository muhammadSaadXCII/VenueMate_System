import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'LoginScreen.dart';

const double _kSignUpWebBreak = 900;

class SignUpScreen extends StatefulWidget {
  final String selectedRole;
  const SignUpScreen({super.key, required this.selectedRole});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmailStructure(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+\-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,6}$",
    );
    return emailRegex.hasMatch(email);
  }

  String? _checkEmailTypos(String email) {
    if (!email.contains('@')) return null;
    final domain = email.split('@').last.toLowerCase();
    const typos = {
      'gmil.com': 'gmail.com',
      'gmal.com': 'gmail.com',
      'gmai.com': 'gmail.com',
      'gamil.com': 'gmail.com',
      'hotmal.com': 'hotmail.com',
      'hotmil.com': 'hotmail.com',
      'yaho.com': 'yahoo.com',
      'yahooo.com': 'yahoo.com',
      'outlok.com': 'outlook.com',
    };
    final suggestion = typos[domain];
    return suggestion != null ? 'Did you mean @$suggestion?' : null;
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    if (!_isValidEmailStructure(email)) {
      _showError('Invalid Email', 'Please enter a valid email address.');
      return;
    }
    final typo = _checkEmailTypos(email);
    if (typo != null) {
      _showError('Invalid Email', '$typo\nPlease check your spelling.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Password Mismatch', 'Passwords do not match.');
      return;
    }
    if (!_agreeToTerms) {
      _showError(
        'Terms Required',
        'Please agree to the Terms & Conditions to continue.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final String? error = await AuthService.signUpWithEmail(
      name: _nameController.text.trim(),
      email: email,
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      role: widget.selectedRole,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      _showError('Sign Up Failed', error);
    } else {
      _showVerificationDialog(email);
    }
  }

  void _showVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF47C20).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read,
                    color: Color(0xFFF47C20),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Verify Your Email',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'A verification link has been sent to $email.\n\nPlease verify your email before logging in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF47C20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Go to Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kSignUpWebBreak;
    return isWide ? _buildWebLayout() : _buildMobileLayout();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB LAYOUT — left branding, right full form (both steps shown at once)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    final roleLabel =
        widget.selectedRole == "venue_owner" ? "Venue Owner" : "Customer";
    return Scaffold(
      body: Row(
        children: [
          // Left branding panel
          Expanded(
            flex: 4,
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
                    top: 40,
                    right: 40,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    left: 30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
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
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.person_add,
                              size: 40,
                              color: Color(0xFFF47C20),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Signing up as $roleLabel',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.white.withOpacity(0.88),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Role badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.selectedRole == "venue_owner"
                                      ? Icons.business_outlined
                                      : Icons.person_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  roleLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right — all fields in one scrollable form
          Expanded(
            flex: 5,
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Two-column personal info
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    hint: 'Enter your full name',
                                    icon: Icons.person_outline,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Name must be at least 3 characters';
                                      }
                                      if (v.trim().length < 3) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildField(
                                    controller: _phoneController,
                                    label: 'Phone Number',
                                    hint: 'Enter 11-digit number',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    formatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(11),
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      if (v.length != 11) {
                                        return 'Phone must be exactly 11 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                            const Text(
                              'Account Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'Enter your email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'Create a password (min 8 chars)',
                                    icon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () =>
                                                _obscurePassword =
                                                    !_obscurePassword,
                                          ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Please enter a password';
                                      }
                                      if (v.length < 8) {
                                        return 'Create a password (min 8 chars)';
                                      }
                                      final digitCount =
                                          RegExp(r'\d').allMatches(v).length;
                                      if (digitCount < 2) {
                                        return 'Must contain at least 2 digits';
                                      }
                                      if (!RegExp(
                                        r'[!@#$%^&*(),.?":{}|<>]',
                                      ).hasMatch(v)) {
                                        return 'Must contain at least 1 special character';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm Password',
                                    hint: 'Re-enter your password',
                                    icon: Icons.lock_outline,
                                    obscureText: _obscureConfirmPassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () =>
                                                _obscureConfirmPassword =
                                                    !_obscureConfirmPassword,
                                          ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (v != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Checkbox(
                                  value: _agreeToTerms,
                                  onChanged:
                                      (v) => setState(() => _agreeToTerms = v!),
                                  activeColor: const Color(0xFFF47C20),
                                ),
                                const Expanded(
                                  child: Wrap(
                                    children: [
                                      Text('I agree to the '),
                                      Text(
                                        'Terms & Conditions',
                                        style: TextStyle(
                                          color: Color(0xFFF47C20),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignUp,
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
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const LoginScreen(),
                                          ),
                                        ),
                                    child: const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: Color(0xFFF47C20),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
  //  MOBILE LAYOUT (unchanged two-step flow)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF47C20),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 40,
                      color: Color(0xFFF47C20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up as ${widget.selectedRole == "venue_owner" ? "Venue Owner" : "Customer"}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _progressDot(0, 'Personal'),
                          _progressLine(0),
                          _progressDot(1, 'Account'),
                        ],
                      ),
                      const SizedBox(height: 30),
                      if (_currentStep == 0) ...[
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          icon: Icons.person_outline,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Name must be at least 3 characters';
                            }
                            if (v.trim().length < 3) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: 'Enter 11-digit number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (v.length != 11) {
                              return 'Phone must be exactly 11 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _currentStep = 1);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF47C20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Create a password (min 8 chars)',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (v.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            final digitCount =
                                RegExp(r'\d').allMatches(v).length;
                            if (digitCount < 2) {
                              return 'Must contain at least 2 digits';
                            }
                            if (!RegExp(
                              r'[!@#$%^&*(),.?":{}|<>]',
                            ).hasMatch(v)) {
                              return 'Must contain at least 1 special character';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
                          icon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed:
                                () => setState(
                                  () =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (v != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged:
                                  (v) => setState(() => _agreeToTerms = v!),
                              activeColor: const Color(0xFFF47C20),
                            ),
                            const Expanded(
                              child: Wrap(
                                children: [
                                  Text('I agree to the '),
                                  Text(
                                    'Terms & Conditions',
                                    style: TextStyle(
                                      color: Color(0xFFF47C20),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    () => setState(() => _currentStep = 0),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFF47C20),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text(
                                  'Back',
                                  style: TextStyle(
                                    color: Color(0xFFF47C20),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF47C20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child:
                                    _isLoading
                                        ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                        : const Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 30),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Color(0xFFF47C20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared field widget ─────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFFF47C20)),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF47C20), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _progressDot(int step, String label) {
    final bool isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF47C20) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child:
                isActive
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                      '${step + 1}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFFF47C20) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _progressLine(int step) => Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: _currentStep > step ? const Color(0xFFF47C20) : Colors.grey[300],
    ),
  );
}
