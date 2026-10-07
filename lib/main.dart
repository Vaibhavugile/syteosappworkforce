import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'auth/splash_screen.dart';
import 'firebase_options.dart';
import 'features/invitation_builder/screens/public_invitation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------
  // CLEAN WEB URLS
  // ------------------------------------------------------------
  //
  // This changes Flutter Web URLs from:
  //
  //   /#/invite/ananya-arjun
  //
  // to:
  //
  //   /invite/ananya-arjun
  //
  // This is required for the public wedding invitation URLs.
  //
  usePathUrlStrategy();

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

  // ------------------------------------------------------------
  // PUBLIC INVITATION ROUTE
  // ------------------------------------------------------------
  //
  // Expected URL:
  //
  //   /invite/ananya-arjun
  //
  // We intentionally use simple path detection instead of adding
  // another routing package. This keeps the public invitation
  // page lightweight and avoids unnecessary routing overhead.
  //
  static String? _getInvitationSlug() {
    final Uri uri = Uri.base;

    final List<String> segments = uri.pathSegments
        .where((String segment) => segment.trim().isNotEmpty)
        .toList();

    if (segments.length >= 2 &&
        segments.first.toLowerCase() == 'invite') {
      final String slug = segments[1].trim();

      if (slug.isNotEmpty) {
        return slug;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String? invitationSlug =
        _getInvitationSlug();

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
      //
      // Public invitation:
      //
      //   /invite/ananya-arjun
      //          ↓
      //   PublicInvitationScreen
      //
      // Normal Syteos Labs:
      //
      //   /
      //   ↓
      //   SplashScreen
      //
      home: invitationSlug != null
          ? PublicInvitationScreen(
              slug: invitationSlug,
            )
          : const SplashScreen(),
    );
  }
}
