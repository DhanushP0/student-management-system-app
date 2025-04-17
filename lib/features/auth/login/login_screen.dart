import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool obscurePassword = true;
  String? error;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => error = 'Please enter email and password');
      return;
    }

    // Clear any previous error
    setState(() => error = null);

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CustomLoader(),
    );

    try {
      // Try to find user role by email in each table
      String? role;

      final student =
          await Supabase.instance.client
              .from('students')
              .select()
              .eq('email', email)
              .maybeSingle();

      if (student != null) {
        role = 'student';
      } else {
        final teacher =
            await Supabase.instance.client
                .from('teachers')
                .select()
                .eq('email', email)
                .maybeSingle();

        if (teacher != null) {
          role = 'teacher';
        } else {
          final admin =
              await Supabase.instance.client
                  .from('admins')
                  .select()
                  .eq('email', email)
                  .maybeSingle();

          if (admin != null) {
            role = 'admin';
          }
        }
      }

      if (role == null) {
        if (mounted) {
          Navigator.of(context).pop();
          setState(() => error = 'No account found with this email address');
        }
        return;
      }

      // If email found, proceed with login
      final authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authRes.user;
      if (user != null) {
        if (mounted) {
          Navigator.of(context).pop();
          _navigateBasedOnRole(role, context);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => error = _getFriendlyErrorMessage(e.toString()));
      }
    }
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Incorrect password. Please try again.';
    } else if (error.contains('network error')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  void _navigateBasedOnRole(String role, BuildContext context) {
    switch (role) {
      case 'student':
        context.go('/student');
        break;
      case 'teacher':
        context.go('/teacher');
        break;
      case 'admin':
        context.go('/admin');
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ Unknown role')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemBackground,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF2F6FF), Color(0xFFF9F9F9)],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _circle(CupertinoColors.systemBlue.withOpacity(0.1), 250),
          ),
          Positioned(
            bottom: -80,
            left: -50,
            child: _circle(CupertinoColors.systemIndigo.withOpacity(0.08), 200),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  backButton(context),
                  const SizedBox(height: 12),
                  _avatar(),
                  const SizedBox(height: 32),
                  const Text(
                    "Sign In",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Welcome back to your account",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8E8E93),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _inputField(
                    controller: _emailController,
                    placeholder: "Email",
                    prefixIcon: CupertinoIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _inputField(
                    controller: _passwordController,
                    placeholder: "Password",
                    prefixIcon: CupertinoIcons.lock,
                    obscureText: obscurePassword,
                    suffixIcon: GestureDetector(
                      onTap:
                          () => setState(() {
                            obscurePassword = !obscurePassword;
                          }),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          obscurePassword
                              ? CupertinoIcons.eye
                              : CupertinoIcons.eye_slash,
                          color: CupertinoColors.systemGrey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => context.go('/forgot-password'),
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: CupertinoColors.systemBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (error != null) _errorBox(error!),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _login,
                    child: _signInButton(),
                  ),
                  const SizedBox(height: 16),
                  _signUpLink(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget backButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => context.go('/'),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.chevron_left,
            color: CupertinoColors.systemBlue,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _circle(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _avatar() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.person_fill,
                  size: 44,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String placeholder,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
          ),
          child: CupertinoTextField(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            placeholder: placeholder,
            placeholderStyle: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 16,
            ),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                prefixIcon,
                color: CupertinoColors.systemGrey,
                size: 20,
              ),
            ),
            suffix: suffixIcon,
            decoration: const BoxDecoration(color: Colors.transparent),
            obscureText: obscureText,
            keyboardType: keyboardType,
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemRed.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              color: CupertinoColors.systemRed,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signInButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A84FF), Color(0xFF0077E6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A84FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            "Sign In",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signUpLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/signup'),
          child: const Text(
            "Create Account",
            style: TextStyle(
              color: CupertinoColors.systemBlue,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
