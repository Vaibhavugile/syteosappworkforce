import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CREATE ACCOUNT
  // ---------------------------------------------------------------------------

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    if (_loading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword =
        _confirmPasswordController.text;

    // Name validation
    if (name.isEmpty) {
      _showMessage(
        'Please enter your full name.',
        isError: true,
      );

      _nameFocusNode.requestFocus();
      return;
    }

    if (name.length < 2) {
      _showMessage(
        'Please enter a valid name.',
        isError: true,
      );

      _nameFocusNode.requestFocus();
      return;
    }

    // Email validation
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

    // Phone validation
    if (phone.isEmpty) {
      _showMessage(
        'Please enter your phone number.',
        isError: true,
      );

      _phoneFocusNode.requestFocus();
      return;
    }

    if (!_isValidPhone(phone)) {
      _showMessage(
        'Please enter a valid phone number.',
        isError: true,
      );

      _phoneFocusNode.requestFocus();
      return;
    }

    // Password validation
    if (password.isEmpty) {
      _showMessage(
        'Please create a password.',
        isError: true,
      );

      _passwordFocusNode.requestFocus();
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Password must contain at least 6 characters.',
        isError: true,
      );

      _passwordFocusNode.requestFocus();
      return;
    }

    // Confirm password
    if (confirmPassword.isEmpty) {
      _showMessage(
        'Please confirm your password.',
        isError: true,
      );

      _confirmPasswordFocusNode.requestFocus();
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'Passwords do not match.',
        isError: true,
      );

      _confirmPasswordFocusNode.requestFocus();
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await AuthService.instance.signUp(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      if (!mounted) return;

      _showMessage(
        'Account created successfully.',
        isError: false,
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      Navigator.of(context).pop();
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
            ? 'Unable to create your account.'
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

  // ---------------------------------------------------------------------------
  // VALIDATION
  // ---------------------------------------------------------------------------

  bool _isValidEmail(String value) {
    final regex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return regex.hasMatch(value);
  }

  bool _isValidPhone(String value) {
    final cleaned = value.replaceAll(
      RegExp(r'[\s\-\(\)\+]'),
      '',
    );

    return RegExp(r'^\d{10,15}$')
        .hasMatch(cleaned);
  }

  // ---------------------------------------------------------------------------
  // FIREBASE ERRORS
  // ---------------------------------------------------------------------------

  String _firebaseAuthError(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Please choose a stronger password.';

      case 'operation-not-allowed':
        return 'Email/password registration is not enabled in Firebase.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      default:
        return error.message ??
            'Unable to create your account.';
    }
  }

  // ---------------------------------------------------------------------------
  // MESSAGE
  // ---------------------------------------------------------------------------

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    final messenger =
        ScaffoldMessenger.of(context);

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
          borderRadius:
              BorderRadius.circular(15),
        ),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    Colors.white.withOpacity(.14),
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

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            24,
            22,
            24,
            bottomInset > 0 ? 30 : 35,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // Back button
              _buildBackButton(),

              const SizedBox(height: 35),

              const Text(
                'Create account',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -.7,
                ),
              ),

              const SizedBox(height: 9),

              const Text(
                'Create your Syteos Labs account\nto get started.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 35),

              // Name
              _label('Full Name'),

              const SizedBox(height: 9),

              _input(
                controller: _nameController,
                focusNode: _nameFocusNode,
                hint: 'Enter your full name',
                icon:
                    Icons.person_outline_rounded,
                textInputAction:
                    TextInputAction.next,
                onSubmitted: (_) {
                  _emailFocusNode.requestFocus();
                },
              ),

              const SizedBox(height: 19),

              // Email
              _label('Work Email'),

              const SizedBox(height: 9),

              _input(
                controller: _emailController,
                focusNode: _emailFocusNode,
                hint: 'Enter your work email',
                icon:
                    Icons.mail_outline_rounded,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                onSubmitted: (_) {
                  _phoneFocusNode.requestFocus();
                },
              ),

              const SizedBox(height: 19),

              // Phone
              _label('Phone Number'),

              const SizedBox(height: 9),

              _input(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                hint: 'Enter phone number',
                icon: Icons.phone_outlined,
                keyboardType:
                    TextInputType.phone,
                textInputAction:
                    TextInputAction.next,
                maxLength: 15,
                onSubmitted: (_) {
                  _passwordFocusNode.requestFocus();
                },
              ),

              const SizedBox(height: 19),

              // Password
              _label('Password'),

              const SizedBox(height: 9),

              _input(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                hint: 'Create a password',
                icon:
                    Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction:
                    TextInputAction.next,
                onSubmitted: (_) {
                  _confirmPasswordFocusNode
                      .requestFocus();
                },
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
                    color:
                        const Color(0xFF9CA3AF),
                  ),
                ),
              ),

              const SizedBox(height: 19),

              // Confirm password
              _label('Confirm Password'),

              const SizedBox(height: 9),

              _input(
                controller:
                    _confirmPasswordController,
                focusNode:
                    _confirmPasswordFocusNode,
                hint: 'Confirm your password',
                icon:
                    Icons.lock_outline_rounded,
                obscureText:
                    _obscureConfirmPassword,
                textInputAction:
                    TextInputAction.done,
                onSubmitted: (_) =>
                    _createAccount(),
                suffix: IconButton(
                  tooltip:
                      _obscureConfirmPassword
                          ? 'Show password'
                          : 'Hide password',
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color:
                        const Color(0xFF9CA3AF),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Create Account
              _buildCreateAccountButton(),

              const SizedBox(height: 27),

              // Login
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: _loading
                          ? null
                          : () =>
                              Navigator.pop(context),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              Center(
                child: Text(
                  'By continuing, you agree to the\nSyteos Labs terms and policies.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  '© ${DateTime.now().year} Syteos Labs LLP',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFB0B5BE),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BACK BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildBackButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: _loading
            ? null
            : () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(13),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF111827),
            size: 20,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CREATE ACCOUNT BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            _loading ? null : _createAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF111827),
          disabledBackgroundColor:
              const Color(0xFF374151),
          foregroundColor: Colors.white,
          disabledForegroundColor:
              Colors.white.withOpacity(.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration:
              const Duration(milliseconds: 180),
          child: _loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Create Account',
                  key: ValueKey('create'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LABEL
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // INPUT
  // ---------------------------------------------------------------------------

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
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      maxLength: maxLength,
      autocorrect: false,
      enableSuggestions: !obscureText,
      textCapitalization:
          TextCapitalization.words,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF111827),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: Color(0xFF9CA3AF),
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
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFF6366F1),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
          ),
        ),
      ),
    );
  }
}