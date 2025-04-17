import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';
import 'package:student_management_app/core/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;
  bool _canResendEmail = false;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    // Email empty validation
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address');
      return;
    }

    // Email format validation
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CustomLoader(size: 60, color: Color(0xFF0A84FF)),
          ),
    );

    try {
      // Check if email exists in database
      final response =
          await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('email', email)
              .maybeSingle();

      if (response == null) {
        // Email not found in database
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loader
          showCupertinoDialog(
            context: context,
            builder:
                (context) => CupertinoAlertDialog(
                  title: const Text('Email Not Registered'),
                  content: const Text(
                    'This email is not registered. Would you like to create an account?',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: const Text('Sign Up'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/signup');
                      },
                    ),
                  ],
                ),
          );
        }
      } else {
        // Email exists, proceed with password reset
        await Supabase.instance.client.auth.resetPasswordForEmail(email);

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loader
          setState(() {
            _successMessage =
                'Password reset instructions have been sent to your email';
            _canResendEmail = false;
          });
          // Start cooldown timer
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) {
              setState(() => _canResendEmail = true);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() {
          _errorMessage = 'An error occurred. Please try again later.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      isLoading: _isLoading,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔙 Back button stays at the top
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.go('/login'),
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
              ),
              const SizedBox(height: 40),

              // 🖼️ Image at the bottom
              Center(
                child: Image.asset(
                  'assets/images/image2.png',
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 40),

              // Header
              const Text(
                'Forgot Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Enter your email and we\'ll send you instructions to reset your password',
                style: TextStyle(fontSize: 16, color: Color(0xFF8E8E93)),
              ),

              const SizedBox(height: 40),

              // Email field
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: CupertinoTextField(
                      controller: _emailController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      placeholder: 'Email Address',
                      placeholderStyle: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 16,
                      ),
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Icon(
                          CupertinoIcons.mail,
                          color: CupertinoColors.systemGrey,
                          size: 20,
                        ),
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Error message
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.systemRed.withOpacity(0.3),
                    ),
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
                          _errorMessage!,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Success message
              if (_successMessage != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: CupertinoColors.systemGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.checkmark_circle,
                            color: CupertinoColors.systemGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(
                                color: CupertinoColors.systemGreen,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_canResendEmail)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _resetPassword,
                        child: const Text(
                          "Didn't receive the email? Send again",
                          style: TextStyle(
                            color: CupertinoColors.systemBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 20),

              // Submit button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isLoading ? null : _resetPassword,
                child: Container(
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
                  child: Center(
                    child:
                        _isLoading
                            ? const CustomLoader(size: 28, color: Colors.white)
                            : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.envelope,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Send Reset Instructions",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
