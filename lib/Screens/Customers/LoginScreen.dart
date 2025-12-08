import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:venuemate_system/Screens/Customers/SelectRoleScreen.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_registration_intro.dart';
import 'package:venuemate_system/Screens/SystemAdmin/system_admin_home.dart';
import 'ForgotPasswordScreen.dart';
import 'HomePageVenueScreen.dart';
import 'SignUpScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAlreadyLoggedIn();
  }

  void _checkAlreadyLoggedIn() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _routeUserByRole(user.uid);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "OK",
                style: TextStyle(color: Color(0xFFF47C20)),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- LOGIC: Route User ---
  Future<void> _routeUserByRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        if (userData == null ||
            !userData.containsKey('role') ||
            userData['role'] == null) {
          if (mounted) {
            _handleMissingRole(
              uid,
              FirebaseAuth.instance.currentUser?.displayName ?? 'User',
              FirebaseAuth.instance.currentUser?.email ?? '',
            );
          }
          return;
        }

        String role = userData['role'];

        if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
          FirebaseFirestore.instance.collection('users').doc(uid).update({
            'isEmailVerified': true,
          });
        }

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (role == 'system_admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SystemAdminHome()),
          );
        } else if (role == 'venue_owner') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HallRegistrationIntroScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          _handleMissingRole(
            uid,
            FirebaseAuth.instance.currentUser?.displayName ?? 'User',
            FirebaseAuth.instance.currentUser?.email ?? '',
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Error", "Failed to fetch user role: $e");
    }
  }

  // --- LOGIC: Handle Missing Role ---
  Future<void> _handleMissingRole(String uid, String name, String email) async {
    String? role = await _showRoleDialog();

    if (role == null) {
      await FirebaseAuth.instance.signOut();
      setState(() => _isLoading = false);
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'phone': '',
      'role': role,
      'createdAt': DateTime.now(),
      'authProvider': 'google',
    }, SetOptions(merge: true));

    if (mounted) _routeUserByRole(uid);
  }

  Future<String?> _showRoleDialog() async {
    String selectedRole = 'customer';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Select Account Type",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Please select how you want to use VenueMate:"),
                  const SizedBox(height: 10),
                  RadioListTile<String>(
                    title: const Text("Customer (Book Venues)"),
                    value: 'customer',
                    groupValue: selectedRole,
                    activeColor: const Color(0xFFF47C20),
                    onChanged: (value) =>
                        setStateDialog(() => selectedRole = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text("Venue Owner (Manage Hall)"),
                    value: 'venue_owner',
                    groupValue: selectedRole,
                    activeColor: const Color(0xFFF47C20),
                    onChanged: (value) =>
                        setStateDialog(() => selectedRole = value!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedRole),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47C20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- LOGIC: Google Sign In ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        await _routeUserByRole(user.uid);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Google Sign-In Error", e.toString());
    }
  }

  // --- LOGIC: Email Login ---
  void _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        User? user = userCredential.user;

        if (user != null) {
          await user.reload();
          user = FirebaseAuth.instance.currentUser;

          if (user != null && !user.emailVerified) {
            await FirebaseAuth.instance.signOut();
            setState(() => _isLoading = false);
            _showErrorDialog(
              "Email Not Verified",
              "Please check your email and verify your account before logging in.",
            );
            return;
          }
          _routeUserByRole(user!.uid);
        }
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        String errorMessage = "An error occurred";
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          errorMessage = "Invalid email or password.";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Invalid password.";
        } else if (e.code == 'network-request-failed') {
          errorMessage = "Please check your internet connection.";
        }
        _showErrorDialog("Login Failed", errorMessage);
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog("Error", e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileLayout() {
    final screenHeight = MediaQuery.of(context).size.height;
    final topSectionHeight = (screenHeight * 0.35).clamp(180.0, 400.0);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: topSectionHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF47C20),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          const Color(0xFFF47C20).withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/venuematelogo3.png',
                              height: 65,
                              width: 65,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.location_city,
                                    size: 50,
                                    color: Color(0xFFF47C20),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'VenueMate',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Find Your Perfect Venue',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.95),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildFormContent(),
            ),
          ],
        ),
      ),
    );
  }

  // --- DESKTOP LAYOUT ---
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Side Branding
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFFF47C20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/venuematelogo3.png',
                    height: 120,
                    width: 120,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.location_city,
                      size: 100,
                      color: Color(0xFFF47C20),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'VenueMate',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Find Your Perfect Venue',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Side Form
        Expanded(
          flex: 6,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login to your dashboard',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),
                    _buildFormContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- SHARED FORM WIDGET ---
  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
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
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? 'Please enter your email'
                : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFFF47C20),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
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
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? 'Please enter your password'
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) => setState(() => _rememberMe = value!),
                    activeColor: const Color(0xFFF47C20),
                  ),
                  const Text('Remember me', style: TextStyle(fontSize: 14)),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForgotPasswordScreen(),
                  ),
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFFF47C20),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _loginUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                assetLogo: 'assets/images/7123025_logo_google_g_icon 1.png',
                label: 'Google',
                onTap: _signInWithGoogle,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoleSelectionScreen(),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFFF47C20),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    IconData? icon,
    String? assetLogo,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (assetLogo != null)
              Image.asset(assetLogo, height: 24, width: 24)
            else
              Icon(
                icon,
                size: 28,
                color: label == 'Facebook' ? Colors.blue[800] : Colors.red,
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
