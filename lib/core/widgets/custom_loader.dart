import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomLoader extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const CustomLoader({
    super.key,
    this.size = 50.0,
    this.color = const Color(0xFF0A84FF),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating circle
          AnimatedBuilder(
            animation: _controller,
            builder: (_, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: child,
              );
            },
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    widget.color.withOpacity(0.0),
                    widget.color.withOpacity(0.5),
                    widget.color,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Inner static circle with blur
          Container(
            width: widget.size * 0.85,
            height: widget.size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Pulsing center dot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.2),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: widget.size * 0.15,
                  height: widget.size * 0.15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Overlay loader that can be used across the app
class AppLoader extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const AppLoader({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const CustomLoader(),
          ),
      ],
    );
  }
}
