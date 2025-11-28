import 'package:flutter/material.dart';
import 'package:venuemate_system/Customers/SplashScreen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: "Roboto",
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}