import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/notification_service.dart';
import 'package:venuemate_system/Screens/Customers/LoginScreen.dart';

/// Wraps any role home screen and listens to the logged-in user's Firestore
/// document in real-time. The moment [isDisabled] flips to `true`, it:
///   1. Signs the user out (removes FCM token + Firebase Auth session)
///   2. Shows an "Account Deactivated" dialog
///   3. Navigates to [LoginScreen], clearing the entire back-stack
///
/// Usage — wrap each role root:
/// ```dart
/// UserGuard(child: MainNavigation())
/// UserGuard(child: HallAdminRootLayout())
/// UserGuard(child: SystemAdminHome())
/// ```
class UserGuard extends StatefulWidget {
  final Widget child;
  const UserGuard({super.key, required this.child});

  @override
  State<UserGuard> createState() => _UserGuardState();
}

class _UserGuardState extends State<UserGuard> {
  Stream<DocumentSnapshot>? _userStream;
  bool _handlingDisable = false;

  @override
  void initState() {
    super.initState();
    final uid = AuthService.currentUid;
    if (uid != null) {
      _userStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    }
  }

  Future<void> _handleDisabled() async {
    if (_handlingDisable) return; // prevent double-trigger
    _handlingDisable = true;

    final uid = AuthService.currentUid;
    if (uid != null) {
      await NotificationService.removeToken(uid: uid);
    }
    await AuthService.signOut();

    if (!mounted) return;

    // Pop everything and go to LoginScreen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );

    // Show the dialog on top of LoginScreen
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(Icons.block_rounded, color: Color(0xFFD92D20), size: 56),
                SizedBox(height: 12),
                Text(
                  'Account Deactivated',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFFD92D20),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your account has been deactivated by the system administrator. '
                  'You have been signed out automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD92D20).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFFD92D20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'If you believe this is a mistake, please contact VenueMate support.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD92D20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userStream == null) return widget.child;

    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snap) {
        // React only when we have fresh data
        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>?;
          final isDisabled = data?['isDisabled'] as bool? ?? false;
          if (isDisabled && !_handlingDisable) {
            // Schedule after the current frame so we're not calling
            // Navigator during a build phase.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleDisabled();
            });
          }
        }
        // Always render the child — the logout/dialog is handled separately
        return widget.child;
      },
    );
  }
}
