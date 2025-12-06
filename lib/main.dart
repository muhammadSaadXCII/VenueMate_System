import 'package:flutter/material.dart';
import 'package:venuemate_system/Screens/Customers/SplashScreen.dart';
// import 'package:venuemate_system/Screens/HallAdmin/hall_admin_root.dart';
import 'package:venuemate_system/Screens/SystemAdmin/system_admin_home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VenueMate Application',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFF47C20)),
        fontFamily: "Roboto",
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
