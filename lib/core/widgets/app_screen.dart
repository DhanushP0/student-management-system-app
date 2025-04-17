import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class AppScreen extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBackButton;

  const AppScreen({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: Stack(
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (showBackButton)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.back, size: 28),
                          onPressed: () => context.pop(),
                        ),
                      if (showBackButton) const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
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
} 