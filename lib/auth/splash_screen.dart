import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../sales/dashboard_screen.dart';
import 'login_screen.dart';
import 'services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _navigationTimer;

  bool _isNavigating = false;

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    _startNavigation();
  }

  // ---------------------------------------------------------------------------
  // START NAVIGATION
  // ---------------------------------------------------------------------------

  void _startNavigation() {
    _navigationTimer = Timer(
      const Duration(milliseconds: 2600),
      () async {
        await _handleNavigation();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // AUTH + ROLE NAVIGATION
  // ---------------------------------------------------------------------------

  Future<void> _handleNavigation() async {
    if (!mounted || _isNavigating) {
      return;
    }

    _isNavigating = true;

    try {
      // -----------------------------------------------------------------------
      // CHECK FIREBASE AUTH
      // -----------------------------------------------------------------------

      final firebaseUser =
          FirebaseAuth.instance.currentUser;

      // -----------------------------------------------------------------------
      // USER IS NOT LOGGED IN
      // -----------------------------------------------------------------------

      if (firebaseUser == null) {
        _goToLogin();
        return;
      }

      // -----------------------------------------------------------------------
      // USER IS LOGGED IN
      // LOAD FIRESTORE PROFILE
      // -----------------------------------------------------------------------

      final appUser =
          await AuthService.instance.getCurrentUserProfile();

      if (!mounted) {
        return;
      }

      // -----------------------------------------------------------------------
      // PROFILE DOES NOT EXIST
      // -----------------------------------------------------------------------

      if (appUser == null) {
        await AuthService.instance.signOut();

        if (!mounted) {
          return;
        }

        _goToLogin();
        return;
      }

      // -----------------------------------------------------------------------
      // ACCOUNT IS DEACTIVATED
      // -----------------------------------------------------------------------

      if (!appUser.isActive) {
        await AuthService.instance.signOut();

        if (!mounted) {
          return;
        }

        _goToLogin(
          message: 'Your account has been deactivated.',
        );

        return;
      }

      // -----------------------------------------------------------------------
      // ROLE BASED NAVIGATION
      // -----------------------------------------------------------------------

      switch (appUser.role) {
        // ---------------------------------------------------------------------
        // SALES EXECUTIVE
        // ---------------------------------------------------------------------

        case UserRole.salesExecutive:
          _goToSalesDashboard();
          break;

        // ---------------------------------------------------------------------
        // ADMIN
        // ---------------------------------------------------------------------

        case UserRole.admin:
          _goToAdminDashboard();
          break;

        // ---------------------------------------------------------------------
        // CALLING EXECUTIVE
        // ---------------------------------------------------------------------

        case UserRole.callingExecutive:
          _goToCallingDashboard();
          break;
      }
    } catch (e) {
      debugPrint(
        'Splash navigation error: $e',
      );

      if (!mounted) {
        return;
      }

      // If something goes wrong while loading
      // the user profile, safely return to Login.
      await AuthService.instance.signOut();

      if (!mounted) {
        return;
      }

      _goToLogin(
        message: 'Unable to load your account. Please sign in again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------

  void _goToLogin({
    String? message,
  }) {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration:
            const Duration(milliseconds: 500),
        reverseTransitionDuration:
            const Duration(milliseconds: 350),
        pageBuilder: (_, animation, __) {
          return LoginScreen(
            initialMessage: message,
          );
        },
        transitionsBuilder:
            (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SALES DASHBOARD
  // ---------------------------------------------------------------------------

  void _goToSalesDashboard() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration:
            const Duration(milliseconds: 500),
        reverseTransitionDuration:
            const Duration(milliseconds: 350),
        pageBuilder: (_, animation, __) {
          return const SalesDashboardScreen();
        },
        transitionsBuilder:
            (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ADMIN DASHBOARD
  // ---------------------------------------------------------------------------
  //
  // Temporary screen until the actual Admin Dashboard is created.
  //

  void _goToAdminDashboard() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration:
            const Duration(milliseconds: 500),
        reverseTransitionDuration:
            const Duration(milliseconds: 350),
        pageBuilder: (_, animation, __) {
          return const RoleComingSoonScreen(
            roleTitle: 'Admin Dashboard',
            roleSubtitle:
                'Your administrator workspace is being prepared.',
            icon: Icons.admin_panel_settings_rounded,
          );
        },
        transitionsBuilder:
            (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CALLING EXECUTIVE DASHBOARD
  // ---------------------------------------------------------------------------
  //
  // Temporary screen until the actual Calling Executive Dashboard is created.
  //

  void _goToCallingDashboard() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration:
            const Duration(milliseconds: 500),
        reverseTransitionDuration:
            const Duration(milliseconds: 350),
        pageBuilder: (_, animation, __) {
          return const RoleComingSoonScreen(
            roleTitle: 'Calling Dashboard',
            roleSubtitle:
                'Your calling workspace is being prepared.',
            icon: Icons.call_rounded,
          );
        },
        transitionsBuilder:
            (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0B0F19),
      body: Stack(
        children: [
          // -------------------------------------------------------------------
          // TOP GLOW
          // -------------------------------------------------------------------

          Positioned(
            top: -120,
            right: -80,
            child: _glow(
              size: 280,
              color:
                  const Color(0xFF6366F1),
            ),
          ),

          // -------------------------------------------------------------------
          // BOTTOM GLOW
          // -------------------------------------------------------------------

          Positioned(
            bottom: -150,
            left: -100,
            child: _glow(
              size: 320,
              color:
                  const Color(0xFF8B5CF6),
            ),
          ),

          // -------------------------------------------------------------------
          // MAIN CONTENT
          // -------------------------------------------------------------------

          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      // -------------------------------------------------------
                      // LOGO
                      // -------------------------------------------------------

                      Container(
                        width: 82,
                        height: 82,
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            24,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black
                                      .withOpacity(.25),
                              blurRadius: 35,
                              offset:
                                  const Offset(
                                0,
                                18,
                              ),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'S',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight:
                                  FontWeight.w900,
                              color:
                                  Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // -------------------------------------------------------
                      // BRAND
                      // -------------------------------------------------------

                      const Text(
                        'SYTEOS LABS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),

                      const SizedBox(height: 9),

                      // -------------------------------------------------------
                      // SUBTITLE
                      // -------------------------------------------------------

                      Text(
                        'Business Management',
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(.55),
                          fontSize: 14,
                          letterSpacing: .4,
                        ),
                      ),

                      const SizedBox(height: 42),

                      // -------------------------------------------------------
                      // LOADER
                      // -------------------------------------------------------

                      SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white
                              .withOpacity(.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // FOOTER
          // -------------------------------------------------------------------

          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Text(
              'SYTEOS LABS LLP',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.white
                    .withOpacity(.3),
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GLOW
  // ---------------------------------------------------------------------------

  Widget _glow({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(.12),
      ),
    );
  }
}