import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'pages/welcome_page.dart';
import 'services/notification_service.dart';

// Lets ApiService trigger navigation (e.g. force-logout to WelcomePage on a
// SESSION_INVALIDATED response) from a plain static method with no
// BuildContext of its own.
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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


