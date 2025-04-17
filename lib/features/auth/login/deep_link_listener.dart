import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_links/uni_links.dart';
import 'package:student_management_app/app/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkListener extends StatefulWidget {
  final Widget child;
  const DeepLinkListener({required this.child, super.key});

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  StreamSubscription? _sub;
  final bool _handled = false;

  @override
  void initState() {
    super.initState();

    _handleInitialUri();
    _listenToIncomingLinks();

    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // Password recovery event handled
      }
    });
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      if (uri != null) _processUri(uri);
    } catch (e) {
      // Handle error silently
    }
  }

  void _listenToIncomingLinks() {
    _sub = uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) _processUri(uri);
      },
      onError: (err) {
        // Handle error silently
      },
    );
  }

  void _processUri(Uri uri) {
    if (_handled || !uri.toString().contains('reset-password')) return;

    final fragmentParams = Uri.splitQueryString(uri.fragment);
    final refreshToken = fragmentParams['refresh_token'];

    if (refreshToken != null && refreshToken.isNotEmpty) {
      _showResetPasswordDialog(refreshToken);
    }
  }

  void _showResetPasswordDialog(String refreshToken) {
    if (refreshToken.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Reset Password'),
            content: const Text('Do you want to reset your password now?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              CupertinoDialogAction(
                child: const Text('Reset'),
                onPressed: () {
                  Navigator.of(context).pop();
                  GoRouter.of(context).go('/reset-password?refresh_token=$refreshToken');
                },
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}