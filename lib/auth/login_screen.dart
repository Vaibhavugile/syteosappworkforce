import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../sales/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? initialMessage;

  const LoginScreen({
    super.key,
    this.initialMessage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _loading = false;
  bool _resetLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialMessage != null &&
        widget.initialMessage!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _showMessage(
          widget.initialMessage!,
          isError: true,
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  // ===========================================================================
  // LOGIN
  // ===========================================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_loading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // -------------------------------------------------------------------------
    // VALIDATION
    // -------------------------------------------------------------------------

    if (email.isEmpty) {
      _showMessage(
        'Please enter your work email.',
        isError: true,
      );

      _emailFocusNode.requestFocus();
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage(
        'Please enter a valid email address.',
        isError: true,
      );

      _emailFocusNode.requestFocus();
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        'Please enter your password.',
        isError: true,
      );

      _passwordFocusNode.requestFocus();
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // -----------------------------------------------------------------------
      // FIREBASE LOGIN
      // -----------------------------------------------------------------------

      final user = await AuthService.instance.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // -----------------------------------------------------------------------
      // SUCCESS MESSAGE
      // -----------------------------------------------------------------------

      _showMessage(
        'Welcome back, ${user.name}.',
        isError: false,
      );

      await Future.delayed(
        const Duration(milliseconds: 350),
      );

      if (!mounted) return;

      // -----------------------------------------------------------------------
      // ROLE-BASED NAVIGATION
      // -----------------------------------------------------------------------

      await _navigateByRole(user.role);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showMessage(
        _firebaseAuthError(e),
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      final message = e
          .toString()
          .replaceFirst('Exception: ', '');

      _showMessage(
        message.isEmpty
            ? 'Unable to sign in. Please try again.'
            : message,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ===========================================================================
  // ROLE NAVIGATION
  // ===========================================================================

  Future<void> _navigateByRole(UserRole role) async {
    if (!mounted) return;

    Widget destination;

    switch (role) {
      // Keep the existing Sales CRM dashboard.
      case UserRole.salesExecutive:
        destination = const SalesDashboardScreen();
        break;

      // Unified internal business dashboard.
      case UserRole.ceo:
      case UserRole.cto:
      case UserRole.admin:
      case UserRole.callingExecutive:
      case UserRole.teamMember:
        destination = const DashboardScreen();
        break;
    }

    await Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(
          milliseconds: 450,
        ),
        reverseTransitionDuration: const Duration(
          milliseconds: 300,
        ),
        pageBuilder: (_, animation, __) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
      (route) => false,
    );
  }

  // ===========================================================================
  // FORGOT PASSWORD
  // ===========================================================================

  Future<void> _forgotPassword() async {
    if (_resetLoading) return;

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        'Enter your email first to reset your password.',
        isError: true,
      );

      _emailFocusNode.requestFocus();
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage(
        'Please enter a valid email address.',
        isError: true,
      );

      _emailFocusNode.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _resetLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      _showMessage(
        'Password reset link sent to $email.',
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-not-found':
          message =
              'If an account exists for this email, a reset link will be sent.';
          break;

        case 'too-many-requests':
          message =
              'Too many requests. Please try again later.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        default:
          message =
              e.message ?? 'Unable to send the reset email.';
      }

      _showMessage(
        message,
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to send the reset email. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _resetLoading = false;
        });
      }
    }
  }

  // ===========================================================================
  // SIGNUP
  // ===========================================================================

  Future<void> _openSignup() async {
    if (_loading) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(
          milliseconds: 350,
        ),
        reverseTransitionDuration: const Duration(
          milliseconds: 300,
        ),
        pageBuilder: (_, animation, __) {
          return const SignupScreen();
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // EMAIL VALIDATION
  // ===========================================================================

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(value);
  }

  // ===========================================================================
  // FIREBASE AUTH ERRORS
  // ===========================================================================

  String _firebaseAuthError(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';

      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Email/password login is not enabled in Firebase.';

      default:
        return error.message ??
            'Unable to sign in. Please try again.';
    }
  }

  // ===========================================================================
  // PREMIUM MESSAGE
  // ===========================================================================

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        elevation: 8,
        backgroundColor: isError
            ? const Color(0xFFB91C1C)
            : const Color(0xFF047857),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(
          seconds: isError ? 3 : 2,
        ),
      ),
    );
  }

  // ===========================================================================
  // UI
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            24,
            34,
            24,
            bottomInset > 0 ? 30 : 35,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),

              _buildBrand(),

              const SizedBox(height: 64),

              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -.7,
                ),
              ),

              const SizedBox(height: 9),

              const Text(
                'Sign in to manage your business,\nteam and sales activity.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 38),

              _label('Work Email'),

              const SizedBox(height: 9),

              _input(
                controller: _emailController,
                focusNode: _emailFocusNode,
                hint: 'Enter your work email',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  _passwordFocusNode.requestFocus();
                },
              ),

              const SizedBox(height: 21),

              _label('Password'),

              const SizedBox(height: 9),

              _input(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                suffix: IconButton(
                  tooltip: _obscurePassword
                      ? 'Show password'
                      : 'Hide password',
                  onPressed: () {
                    setState(() {
                      _obscurePassword =
                          !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetLoading
                      ? null
                      : _forgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: _resetLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6366F1),
                          ),
                        )
                      : const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              _buildSignInButton(),

              const SizedBox(height: 30),

              _buildDivider(),

              const SizedBox(height: 27),

              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: _openSignup,
                      child: const Text(
                        'Create account',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              Center(
                child: Text(
                  '© ${DateTime.now().year} Syteos Labs LLP',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BRAND
  // ===========================================================================

  Widget _buildBrand() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111827)
                    .withOpacity(.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        const SizedBox(width: 13),

        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SYTEOS LABS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Business Management',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // SIGN IN BUTTON
  // ===========================================================================

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111827),
          disabledBackgroundColor:
              const Color(0xFF374151),
          foregroundColor: Colors.white,
          disabledForegroundColor:
              Colors.white.withOpacity(.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 180,
          ),
          child: _loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Sign In',
                  key: ValueKey('signin'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DIVIDER
  // ===========================================================================

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
          ),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // LABEL
  // ===========================================================================

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
      ),
    );
  }

  // ===========================================================================
  // INPUT
  // ===========================================================================

  Widget _input({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autocorrect: false,
      enableSuggestions: !obscureText,
      textCapitalization: TextCapitalization.none,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF111827),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: const Color(0xFF9CA3AF),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFF6366F1),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
          ),
        ),
      ),
    );
  }
}