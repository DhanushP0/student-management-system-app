import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    
    // Responsive padding and spacing calculations
    final double horizontalPadding = screenWidth * 0.06; // 6% of screen width
    final double verticalSpacing = screenHeight * 0.02; // 2% of screen height
    
    return Scaffold(
      backgroundColor: CupertinoColors.systemBackground,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF2F6FF), Color(0xFFF9F9F9)],
              ),
            ),
          ),

          // Decorative circles - sized relative to screen
          Positioned(
            top: -screenHeight * 0.1,
            right: -screenWidth * 0.2,
            child: _decorativeCircle(CupertinoColors.systemBlue, screenSize),
          ),
          Positioned(
            bottom: -screenHeight * 0.08,
            left: -screenWidth * 0.1,
            child: _decorativeCircle(CupertinoColors.systemIndigo, screenSize),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(height: verticalSpacing),

                  // App icon - sized based on screen width
                  _frostedIcon(iconSize: screenWidth * 0.15),

                  SizedBox(height: verticalSpacing),

                  // Main content
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/image1.png',
                            height: screenHeight * 0.28, // Slightly reduced for better fit
                            width: screenWidth * 0.8,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: verticalSpacing * 1.5),

                          Text(
                            'SMS',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045, // 4.5% of screen width
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.black,
                            ),
                          ),
                          SizedBox(height: verticalSpacing * 0.8),

                          Text(
                            "Everything you need is in one place",
                            style: TextStyle(
                              fontSize: screenWidth * 0.055, // 5.5% of screen width
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E1E1E),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: verticalSpacing * 0.6),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.5),
                            child: Text(
                              "Track attendance, monitor performance, and connect everyone through an intuitive interface designed for the modern classroom.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenWidth * 0.035, // 3.5% of screen width
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ),

                          SizedBox(height: verticalSpacing * 1.6),

                          // Login Button
                          _cupertinoFilledButton(
                            context,
                            label: "Login",
                            icon: CupertinoIcons.person_fill,
                            onPressed: () => context.go('/login'),
                          ),

                          SizedBox(height: verticalSpacing * 0.8),

                          // Register Button
                          _cupertinoFrostedButton(
                            context,
                            label: "Register",
                            icon: CupertinoIcons.person_badge_plus,
                            onPressed: () => context.go('/signup'),
                          ),

                          SizedBox(height: verticalSpacing * 1.2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Decorative background circle - sized relative to screen
  Widget _decorativeCircle(Color color, Size screenSize) {
    final double circleSize = screenSize.width * 0.6; // 60% of screen width
    
    return Container(
      height: circleSize,
      width: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
      ),
    );
  }

  // Frosted glass app icon with dynamic size
  Widget _frostedIcon({required double iconSize}) {
    return Container(
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
        borderRadius: BorderRadius.circular(iconSize * 0.3),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: EdgeInsets.all(iconSize * 0.25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(iconSize * 0.3),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              CupertinoIcons.book_fill,
              size: iconSize,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ),
      ),
    );
  }

  // Filled login button with responsive sizing
  Widget _cupertinoFilledButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final double buttonHeight = MediaQuery.of(context).size.height * 0.065;
    final double fontSize = MediaQuery.of(context).size.width * 0.04;
    final double iconSize = fontSize * 1.1;
    
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        height: buttonHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A84FF), Color(0xFF0077E6)],
          ),
          borderRadius: BorderRadius.circular(buttonHeight * 0.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A84FF).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: iconSize),
            SizedBox(width: fontSize * 0.5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Frosted glass register button with responsive sizing
  Widget _cupertinoFrostedButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final double buttonHeight = MediaQuery.of(context).size.height * 0.065;
    final double fontSize = MediaQuery.of(context).size.width * 0.04;
    final double iconSize = fontSize * 1.1;
    
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(buttonHeight * 0.5),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            width: double.infinity,
            height: buttonHeight,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(buttonHeight * 0.5),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: CupertinoColors.systemBlue, size: iconSize),
                SizedBox(width: fontSize * 0.5),
                Text(
                  label,
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}