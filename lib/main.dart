import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------
  // INITIALIZE FIREBASE
  // ------------------------------------------------------------
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ------------------------------------------------------------
  // START APPLICATION
  // ------------------------------------------------------------
  runApp(const SyteosLabsApp());
}

class SyteosLabsApp extends StatelessWidget {
  const SyteosLabsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syteos Labs',
      debugShowCheckedModeBanner: false,

      // ----------------------------------------------------------
      // BASIC APP THEME
      // ----------------------------------------------------------
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        scaffoldBackgroundColor:
            const Color(0xFFF7F8FC),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),

        fontFamily: 'Inter',

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),

      // ----------------------------------------------------------
      // FIRST SCREEN
      // ----------------------------------------------------------
      home: const SplashScreen(),
    );
  }
}