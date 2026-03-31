import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/user_model.dart';

/// Handles ALL Firebase Authentication operations for VenueMate.
/// Call methods from your screens — never use FirebaseAuth directly.
class AuthService {
  // ── Singletons ─────────────────────────────────────────────────────────────
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn();

  // ── Current User (quick access) ────────────────────────────────────────────
  static User? get currentFirebaseUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
  static String? get currentUid => _auth.currentUser?.uid;

  // ── Stream: listen to auth state changes app-wide ─────────────────────────
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ════════════════════════════════════════════════════════════════════════════
  //  SIGN UP WITH EMAIL
  // ════════════════════════════════════════════════════════════════════════════
  /// Creates a Firebase Auth account, saves user to Firestore, sends
  /// a verification email, then signs the user out so they must verify first.
  ///
  /// Returns null on success. Returns an error [String] on failure.
  static Future<String?> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role, // 'customer' | 'venue_owner'
  }) async {
    try {
      // 1. Create the Auth account
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User user = cred.user!;

      // 2. Send verification email
      await user.sendEmailVerification();

      // 3. Build the UserModel
      final UserModel newUser = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        isEmailVerified: false,
        authProvider: 'email',
        createdAt: DateTime.now(),
      );

      // 4. Save to Firestore users/{uid}
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      // 5. Sign out immediately — user must verify email before logging in
      await _auth.signOut();

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  LOGIN WITH EMAIL
  // ════════════════════════════════════════════════════════════════════════════
  /// Signs the user in and returns a [UserModel] on success.
  /// Returns null for the model and a non-null error string on failure.
  static Future<({UserModel? user, String? error})> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User firebaseUser = cred.user!;

      // 2. Reload to get latest verification status
      await firebaseUser.reload();
      final User refreshed = _auth.currentUser!;

      // 3. Block unverified accounts
      if (!refreshed.emailVerified) {
        await _auth.signOut();
        return (
          user: null,
          error:
              'Email not verified. Please check your inbox and verify before logging in.',
        );
      }

      // 4. Update isEmailVerified in Firestore if needed
      await _firestore.collection('users').doc(refreshed.uid).update({
        'isEmailVerified': true,
      });

      // 5. Fetch UserModel from Firestore
      final UserModel? userModel = await getUserById(refreshed.uid);

      if (userModel == null) {
        await _auth.signOut();
        return (
          user: null,
          error: 'User record not found. Please contact support.',
        );
      }

      return (user: userModel, error: null); // success
    } on FirebaseAuthException catch (e) {
      return (user: null, error: _authErrorMessage(e.code));
    } catch (e) {
      return (user: null, error: 'Something went wrong. Please try again.');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  GOOGLE SIGN IN
  // ════════════════════════════════════════════════════════════════════════════
  /// Signs in (or registers) with Google.
  /// If the user is new, saves them to Firestore with the given [defaultRole].
  /// If they already exist, fetches their existing record.
  ///
  /// Returns null for the model and a non-null error string on failure.
  static Future<({UserModel? user, String? error})> signInWithGoogle({
    required Future<String?> Function() roleDialog,
  }) async {
    try {
      // Force account picker to appear every time
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        // User cancelled the picker
        return (user: null, error: null);
      }

      final GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential cred = await _auth.signInWithCredential(credential);

      final User firebaseUser = cred.user!;

      // Check if this user already has a Firestore record
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      UserModel userModel;

      if (doc.exists) {
        // Existing user — just read from Firestore
        userModel = UserModel.fromDoc(doc);
      } else {
        final role = (await roleDialog()) ?? 'customer';
        // Brand new Google user — create their record
        userModel = UserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          phone: '',
          role: role,
          profileImageUrl: firebaseUser.photoURL ?? '',
          isEmailVerified: true, // Google accounts are pre-verified
          authProvider: 'google',
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userModel.toMap());
      }

      return (user: userModel, error: null); // success
    } on FirebaseAuthException catch (e) {
      return (user: null, error: _authErrorMessage(e.code));
    } catch (e) {
      return (user: null, error: 'Google Sign-In failed. Please try again.');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  LOGOUT
  // ════════════════════════════════════════════════════════════════════════════
  static Future<void> signOut() async {
    await _googleSignIn.signOut(); // clear Google session too
    await _auth.signOut();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  FORGOT PASSWORD
  // ════════════════════════════════════════════════════════════════════════════
  /// Sends a Firebase password-reset email.
  /// Returns null on success, or an error message string on failure.
  static Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return 'Failed to send reset email. Please try again.';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  CHANGE PASSWORD (while logged in)
  // ════════════════════════════════════════════════════════════════════════════
  /// Re-authenticates the user with their old password, then updates it.
  /// Returns null on success, or an error message string on failure.
  static Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        return 'You must be logged in to change your password.';
      }

      // Re-authenticate first (required by Firebase for sensitive ops)
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return 'Failed to change password. Please try again.';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  RESEND VERIFICATION EMAIL
  // ════════════════════════════════════════════════════════════════════════════
  static Future<String?> resendVerificationEmail() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return 'No user is currently signed in.';
      if (user.emailVerified) return 'Email is already verified.';
      await user.sendEmailVerification();
      return null; // success
    } catch (e) {
      return 'Failed to send verification email.';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  FETCH USER FROM FIRESTORE
  // ════════════════════════════════════════════════════════════════════════════
  /// Returns the [UserModel] for the given [uid], or null if not found.
  static Future<UserModel?> getUserById(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    } catch (e) {
      return null;
    }
  }

  /// Fetch the currently logged-in user's [UserModel] from Firestore.
  static Future<UserModel?> getCurrentUser() async {
    final String? uid = currentUid;
    if (uid == null) return null;
    return getUserById(uid);
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  PRIVATE: Map Firebase error codes → human-readable messages
  // ════════════════════════════════════════════════════════════════════════════
  static String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please log in instead.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'requires-recent-login':
        return 'Please log out and log back in before changing your password.';
      default:
        return 'An error occurred ($code). Please try again.';
    }
  }
}
