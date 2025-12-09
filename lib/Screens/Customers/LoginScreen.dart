import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:myapp/customer/ForgotPasswordScreen.dart';
// import 'package:myapp/customer/SelectRoleScreen.dart';
// import 'package:myapp/hall_admin/hall_registration_intro.dart';
// import 'package:myapp/system_admin/system_admin_home.dart';
import 'package:venuemate_system/Screens/Customers/ForgotPasswordScreen.dart';
import 'package:venuemate_system/Screens/Customers/SelectRoleScreen.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_registration_intro.dart';
import 'package:venuemate_system/Screens/SystemAdmin/system_admin_home.dart';
// import 'package:venuemate_system/Screens/Customers/SelectRoleScreen.dart';
// import 'package:venuemate_system/Screens/HallAdmin/hall_registration_intro.dart';
// Note: Ensure this import points to your actual Hall Admin Root if it exists, otherwise use Home
// import 'package:venuemate_system/Screens/HallAdmin/hall_admin_root.dart';
// import 'package:venuemate_system/Screens/SystemAdmin/system_admin_home.dart';
// import 'ForgotPasswordScreen.dart';
// import 'HomePageVenueScreen.dart';
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
    // Check if user exists and is verified (optional check for auto-login)
    if (user != null) {
      // Optional: You can force check email verification here too if needed
      // await user.reload();
      // if(user.emailVerified) { ... }
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

  // --- HELPER FUNCTION TO ROUTE USER BASED ON ROLE ---
  Future<void> _routeUserByRole(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        // Check if role exists in database
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

        // Optional: Update isEmailVerified status in Firestore upon successful login
        if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
          FirebaseFirestore.instance.collection('users').doc(uid).update({
            'isEmailVerified': true,
          });
        }

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (role == 'system_admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SystemAdminHome()),
          );
        } else if (role == 'venue_owner') {
          Navigator.pushReplacement(
            context,
            // Replace with HallAdminRootLayout if using the bottom nav setup
            MaterialPageRoute(
              builder: (context) => const HallRegistrationIntroScreen(),
            ),
          );
        } else {
          // Default to Customer Home
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (context) => const HomeScreen()),
          // );
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
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog("Error", "Failed to fetch user role: $e");
    }
  }

  // --- Handle Missing Role Logic ---
  Future<void> _handleMissingRole(String uid, String name, String email) async {
    String? role = await _showRoleDialog();

    if (role == null) {
      await FirebaseAuth.instance.signOut();
      setState(() {
        _isLoading = false;
      });
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

    if (mounted) {
      _routeUserByRole(uid);
    }
  }

  // --- POPUP DIALOG FOR ROLE SELECTION ---
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
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text("Venue Owner (Manage Hall)"),
                    value: 'venue_owner',
                    groupValue: selectedRole,
                    activeColor: const Color(0xFFF47C20),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, null);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, selectedRole);
                  },
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

  // --- GOOGLE SIGN IN LOGIC (UNCHANGED) ---
  // Google accounts are usually auto-verified, so we proceed directly
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
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
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog("Google Sign-In Error", e.toString());
    }
  }

  // --- MODIFIED EMAIL LOGIN LOGIC WITH VERIFICATION CHECK ---
  void _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        User? user = userCredential.user;

        if (user != null) {
          // 1. Reload the user to get the latest emailVerification status
          await user.reload();
          // After reload, we should get the current user instance again
          user = FirebaseAuth.instance.currentUser;

          // 2. Check if Email is Verified
          if (user != null && !user.emailVerified) {
            // IF NOT VERIFIED: Sign out and show error
            await FirebaseAuth.instance.signOut();

            setState(() {
              _isLoading = false;
            });

            _showErrorDialog(
              "Email Not Verified",
              "Please check your email and verify your account before logging in.",
            );
            return;
          }

          // 3. IF VERIFIED: Proceed to Routing
          _routeUserByRole(user!.uid);
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });

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
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog("Error", e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Half - Image Section
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                              'assets/images/venuematelogo3.png', // Ensure this asset exists
                              height: 100,
                              width: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.location_city,
                                  size: 80,
                                  color: Color(0xFFF47C20),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'VenueMate',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Find Your Perfect Venue',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.95),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom Half - Login Form
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Login to continue',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 30),
                      // Email Field
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Password Field
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
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Remember Me and Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value!;
                                  });
                                },
                                activeColor: const Color(0xFFF47C20),
                              ),
                              const Text(
                                'Remember me',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen(),
                                ),
                              );
                            },
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
                      // Login Button
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
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
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
                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
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
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Social Login Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            assetLogo:
                                'assets/images/7123025_logo_google_g_icon 1.png',
                            label: 'Google',
                            onTap: _signInWithGoogle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Sign Up Link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RoleSelectionScreen(),
                                  ),
                                );
                              },
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UPDATED HELPER WIDGET ---
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