import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:venuemate_system/Screens/Customers/SplashScreen.dart';

// ── FCM background message handler ───────────────────────────────────────
// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this fires on Android.
  // No UI work here — just acknowledge receipt.
  debugPrint('FCM background message: ${message.notification?.title}');
}

// ── Local notifications plugin (foreground heads-up banners) ─────────────
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
  if (kIsWeb) return; // local_notifications not needed on web

  const android = AndroidInitializationSettings('vm_notification');
  await _localNotifications.initialize(
    const InitializationSettings(android: android),
  );

  // Create the high-importance Android channel that matches the FCM payload
  const channel = AndroidNotificationChannel(
    'venuemate_channel',
    'VenueMate Notifications',
    description: 'Booking updates, payments and messages from VenueMate',
    importance: Importance.high,
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

void _listenForegroundMessages() {
  if (kIsWeb) return;
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'venuemate_channel',
          'VenueMate Notifications',
          channelDescription:
              'Booking updates, payments and messages from VenueMate',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'vm_notification',
        ),
      ),
    );
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Platform-specific FirebaseOptions
  FirebaseOptions? firebaseOptions;

  if (kIsWeb) {
    print("Web");
    firebaseOptions = const FirebaseOptions(
      apiKey: "AIzaSyCBhqiCr1HZCyEV6HqfKS1ijxAP-GDQbpM",
      authDomain: "venuemate-system.firebaseapp.com",
      projectId: "venuemate-system",
      storageBucket: "venuemate-system.firebasestorage.app",
      messagingSenderId: "1023649558072",
      appId: "1:1023649558072:web:15d3fe7330b9eb35a840cd",
      measurementId: "G-9Z5R49TE23",
    );
  } else {
    print("Mobile (Android)");
    firebaseOptions = const FirebaseOptions(
      apiKey: "AIzaSyB1E9vnjm0DQhimZG1KHvbzQzlOkbUQkfQ",
      appId: "1:1023649558072:android:15d3fe7330b9eb35a840cd",
      messagingSenderId: "1023649558072",
      projectId: "venuemate-system",
      storageBucket: "venuemate-system.firebasestorage.app",
    );
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: firebaseOptions);
      print("✅ SUCCESS: Firebase Manually Initialized");
    } else {
      print("ℹ️ INFO: Firebase was already initialized (Auto-init)");
    }
    print("🚀 Connected to Project ID: ${Firebase.app().options.projectId}");
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print("⚠️ Duplicate App Error (Ignored) - Connection is still OK.");
      print("🚀 Connected to Project ID: ${Firebase.app().options.projectId}");
    } else {
      print("❌ Firebase Init Error: $e");
      rethrow;
    }
  }

  // Register background FCM handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set up local notifications channel + foreground listener
  await _initLocalNotifications();
  _listenForegroundMessages();

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
