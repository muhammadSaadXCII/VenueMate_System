import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:venuemate_system/Screens/Customers/SplashScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      if (kIsWeb) {
        // ── Web Configuration ──────────────────────────────────────────────
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyCBhqiCr1HZCyEV6HqfKS1ijxAP-GDQbpM",
            authDomain: "venuemate-system.firebaseapp.com",
            projectId: "venuemate-system",
            storageBucket: "venuemate-system.firebasestorage.app",
            messagingSenderId: "1023649558072",
            appId: "1:1023649558072:web:15d3fe7330b9eb35a840cd",
            measurementId: "G-9Z5R49TE23",
          ),
        );
        print("✅ Firebase Initialized (Web)");
      } else {
        // ── Android / iOS Configuration ────────────────────────────────────
        // ⚠️  FIX: The apiKey was EMPTY before — this caused EVERY Firestore
        //          and Storage write to silently fail, returning null and
        //          showing "Failed to submit booking. Check your connection."
        //
        // HOW TO GET YOUR ANDROID API KEY:
        //   1. Go to Firebase Console → Project Settings → General
        //   2. Under "Your apps" find your Android app
        //   3. Download google-services.json
        //   4. Open the file and copy the value of "current_key" inside
        //      client[0].api_key[0].current_key
        //   5. Paste it below replacing "PASTE_YOUR_ANDROID_API_KEY_HERE"
        //
        // ALTERNATIVE (recommended): Delete the manual init below entirely
        // and use the google-services.json method instead:
        //   - Place google-services.json in android/app/
        //   - Run: flutterfire configure
        //   - Use: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyB1E9vnjm0DQhimZG1KHvbzQzlOkbUQkfQ", // ← REPLACE THIS
            appId: "1:1023649558072:android:15d3fe7330b9eb35a840cd",
            messagingSenderId: "1023649558072",
            projectId: "venuemate-system",
            storageBucket: "venuemate-system.firebasestorage.app",
          ),
        );
        print("✅ Firebase Initialized (Android)");
      }
    } else {
      print("ℹ️ Firebase already initialized.");
    }

    print("🚀 Connected to: ${Firebase.app().options.projectId}");
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print("⚠️ Duplicate app (ignored) — already connected.");
    } else {
      print("❌ Firebase Init Error: ${e.code} — ${e.message}");
      rethrow;
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VenueMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF47C20)),
        fontFamily: "Roboto",
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
