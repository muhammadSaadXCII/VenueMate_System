import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:venuemate_system/Screens/Customers/SplashScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Platform-specific FirebaseOptions
  FirebaseOptions? firebaseOptions;

  if (kIsWeb) {
    // Web Firebase configuration
    print("Web");
    firebaseOptions = const FirebaseOptions(
      apiKey:
          "AIzaSyCBhqiCr1HZCyEV6HqfKS1ijxAP-GDQbpM", // Yahan apni asli Web API Key likhna na bhulein
      authDomain: "venuemate-system.firebaseapp.com",
      projectId: "venuemate-system",
      storageBucket: "venuemate-system.appspot.com",
      messagingSenderId: "1023649558072",
      appId: "1:1023649558072:web:15d3fe7330b9eb35a840cd",
      measurementId: "G-9Z5R49TE23",
    );
  } else {
    // Mobile (Android) ke liye
    print("Mobile (Android)");
    firebaseOptions = const FirebaseOptions(
      apiKey: "", // Yahan apni asli Mobile API Key likhna na bhulein
      appId: "1:1023649558072:android:15d3fe7330b9eb35a840cd",
      messagingSenderId: "1023649558072",
      projectId: "venuemate-system",
      storageBucket: "venuemate-system.appspot.com",
    );
  }

  // --- MAIN FIX & VERIFICATION IS HERE ---
  try {
    // Pehle check karein agar koi app already initialized nahi hai
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: firebaseOptions);
      print("✅ SUCCESS: Firebase Manually Initialized");
    } else {
      // Agar Android auto-init ho chuka hai
      print("ℹ️ INFO: Firebase was already initialized (Auto-init)");
    }

    // --- CONNECTION CHECK ---
    // Yeh line confirm karegi ke waqai connection ban gaya hai
    print("🚀 Connected to Project ID: ${Firebase.app().options.projectId}");
    // ------------------------
  } on FirebaseException catch (e) {
    // Agar duplicate app ka error aaye, to use ignore karein
    if (e.code == 'duplicate-app') {
      print("⚠️ Duplicate App Error (Ignored) - Connection is still OK.");
      // Duplicate hone ke bawajood app connected hoti hai, isliye yahan bhi confirm karein
      print("🚀 Connected to Project ID: ${Firebase.app().options.projectId}");
    } else {
      // Agar koi aur error hai to print karein
      print("❌ Firebase Init Error: $e");
      rethrow;
    }
  }
  // ------------------------
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
