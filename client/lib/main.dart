import 'package:flutter/material.dart';
import 'pages/welcome_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Timing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2D1B4E),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      ),
      home: const WelcomePage(),
    );
  }
}


