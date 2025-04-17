import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class ResetPasswordPage extends StatefulWidget {
  final String refreshToken;

  const ResetPasswordPage({Key? key, required this.refreshToken})
    : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String? error;
  bool _loading = false;

  Future<void> _resetPassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => error = "Passwords do not match");
      return;
    }

    setState(() {
      _loading = true;
      error = null;
    });

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CustomLoader(),
    );
    try {
      // Use only the refreshToken in Supabase 2.x
      await Supabase.instance.client.auth.setSession(widget.refreshToken);

      // Now update the password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Password reset successfully!')),
        );
        context.go('/login'); // Go to login page using go_router
      }
    } on AuthException catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        setState(() => error = e.message);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
                  _lockIcon(),
                  const SizedBox(height: 32),
                  const Text(
                    "Reset Password",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Create a new secure password",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8E8E93),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _inputField(
                    controller: _passwordController,
                    placeholder: "New Password",
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
                  const SizedBox(height: 16),
                  _inputField(
                    controller: _confirmPasswordController,
                    placeholder: "Confirm Password",
                    prefixIcon: CupertinoIcons.lock_shield,
                    obscureText: obscureConfirmPassword,
                    suffixIcon: GestureDetector(
                      onTap:
                          () => setState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          }),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          obscureConfirmPassword
                              ? CupertinoIcons.eye
                              : CupertinoIcons.eye_slash,
                          color: CupertinoColors.systemGrey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (error != null) _errorBox(error!),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _loading ? null : _resetPassword,
                    child: _resetButton(),
                  ),
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
    Future<bool> showExitConfirmationDialog() async {
      return await showCupertinoDialog<bool>(
            context: context,
            builder:
                (context) => CupertinoAlertDialog(
                  title: const Text('Are you sure?'),
                  content: const Text(
                    'Your password reset progress will be lost.',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text('Leave'),
                      onPressed: () {
                        Navigator.pop(context, true);
                        context.go('/login'); // Navigate to login page
                      },
                    ),
                  ],
                ),
          ) ??
          false;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: showExitConfirmationDialog,
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

  Widget _lockIcon() {
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
                  CupertinoIcons.lock_shield_fill,
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

  Widget _resetButton() {
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
          Icon(CupertinoIcons.checkmark_shield, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            "Reset Password",
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
}
