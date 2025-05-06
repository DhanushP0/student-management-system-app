import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  String? _errorMessage;

  // Controllers for animations
  late AnimationController _mainAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _floatingAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _welcomeAnimationController;

  // Controllers for staggered animations
    late List<AnimationController> _statCardControllers;
  late List<AnimationController> _navButtonControllers;
  late List<AnimationController> _quickActionControllers;

  // Animation values
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // For parallax and interactive effects
  final double _backgroundOffsetX = 0;
  final double _backgroundOffsetY = 0;
  final double _maxBackgroundOffset = 15.0;

  // Mouse hover states for menu items
  final Map<int, bool> _navButtonHoverStates = {};
  final Map<int, bool> _quickActionHoverStates = {};
  final Map<int, bool> _statCardHoverStates = {};

  // For scrolling animations
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  // For time-based greeting
  String _greeting = "Good morning";

  // For micro-interactions
  bool _isRefreshing = false;
  final bool _hasNewNotification = true;
  final int _notificationCount = 3;

  // For glowing effect
  bool _showGlow = false;
  Timer? _glowTimer;

  // Stats for dashboard
  int _assignmentsCount = 0;
  int _gradesCount = 0;
  int _attendanceCount = 0;
  int _subjectsCount = 0;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadStats();
    _initializeAnimations();
    _startStaggeredAnimations();
    

    // Listen to scroll events for parallax effects
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });

    // Setup periodic glow effect
    _glowTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _showGlow = true;
        });
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _showGlow = false;
            });
          }
        });
      }
    });
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = "Good morning";
      } else if (hour < 17) {
        _greeting = "Good afternoon";
      } else {
        _greeting = "Good evening";
      }
    });
  }

  void _initializeAnimations() {
    _statCardControllers = List.generate(
      4,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    // Main animation controller
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Welcome animation controller for initial loading sequence
    _welcomeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Pulse animation for breathing effects
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Floating animation for hover effects
    _floatingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Background animation for subtle movement
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30000),
    )..repeat();

    // Scale and fade animations
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOut),
    );

    // Individual controllers for staggered animations
    _navButtonControllers = List.generate(
      6,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
    );

    _quickActionControllers = List.generate(
      4,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      ),
    );

    // Start main animations
    _mainAnimationController.forward();
    _welcomeAnimationController.forward();
  }

void _startStaggeredAnimations() {
  // Delay for welcome animation to finish
  Future.delayed(const Duration(milliseconds: 500), () {
    // Start staggered animations for stat cards first
    for (int i = 0; i < _statCardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (mounted) _statCardControllers[i].forward();
      });
    }

    // Then quick actions
    for (int i = 0; i < _quickActionControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 80 * i + 200), () {
        if (mounted) _quickActionControllers[i].forward();
      });
    }

    // Finally navigation buttons
    for (int i = 0; i < _navButtonControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 120 * i + 600), () {
        if (mounted) _navButtonControllers[i].forward();
      });
    }
  });
}

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _pulseAnimationController.dispose();
    _floatingAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _welcomeAnimationController.dispose();
    _scrollController.dispose();
    _glowTimer?.cancel();

    for (var controller in _navButtonControllers) {
      controller.dispose();
    }
    for (var controller in _quickActionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStats() async {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      // print('User data: ${user}');

      // Try to get student record by id
      var student =
          await Supabase.instance.client
              .from('students')
              .select('*')
              .eq('id', user.id)
              .maybeSingle();

      // If not found, try by email
      student ??=
          await Supabase.instance.client
              .from('students')
              .select('*')
              .eq('email', user.email)
              .maybeSingle();

      if (student == null) {
        // Try to insert, but catch duplicate key error
        try {
          final newStudent =
              await Supabase.instance.client
                  .from('students')
                  .insert({
                    'id': user.id,
                    'full_name': user.userMetadata?['name'] ?? 'Student',
                    'email': user.email,
                    'created_at': DateTime.now().toIso8601String(),
                    'department_id': user.userMetadata?['department'],
                    'class_id': null,
                  })
                  .select()
                  .single();
          student = newStudent;
        } catch (e) {
          // If duplicate key, fetch the record again
          if (e.toString().contains('duplicate key value')) {
            student =
                await Supabase.instance.client
                    .from('students')
                    .select('*')
                    .eq('id', user.id)
                    .maybeSingle();
          } else {
            rethrow;
          }
        }
      }

      _studentData = student;

      // Get student's class id
      final classId = student['class_id'];

      // Assignments count
      if (classId != null) {
        final assignmentsRes = await Supabase.instance.client
            .from('assignments')
            .select('id', const FetchOptions(count: CountOption.exact))
            .eq('class_id', classId);
        _assignmentsCount = assignmentsRes.count ?? 0;
      } else {
        _assignmentsCount = 0;
      }

      // Grades count
      final gradesRes = await Supabase.instance.client
          .from('grades')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('student_id', user.id);
      _gradesCount = gradesRes.count ?? 0;

      // Attendance count
      final attendanceRes = await Supabase.instance.client
          .from('attendance')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('student_id', user.id);
      _attendanceCount = attendanceRes.count ?? 0;

      // Subjects count
      if (classId != null) {
        final subjectsRes = await Supabase.instance.client
            .from('subjects')
            .select('id', const FetchOptions(count: CountOption.exact))
            .eq('class_id', classId);
        _subjectsCount = subjectsRes.count ?? 0;
      } else {
        _subjectsCount = 0;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load student dashboard: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    await _loadStats();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Dashboard refreshed success!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          elevation: 0,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  Widget _buildProfileSection() {
    return AnimatedBuilder(
      animation: _mainAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade600.withOpacity(0.9),
              Colors.indigo.shade800.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.shade300.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.indigo.shade700.withOpacity(0.6),
              blurRadius: 50,
              offset: const Offset(0, 20),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting and name section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          _greeting,
                          speed: const Duration(milliseconds: 150),
                          cursor: '',
                          textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                      isRepeatingAnimation: false,
                      totalRepeatCount: 1,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _studentData?['full_name'] ?? 'Student',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
          children: [
            const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
            Text(
                                'VERIFIED',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
            ),
          ],
        ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Student info section
            Row(
        children: [
                // Visual element
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background ring
          Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    // Animated progress ring
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 0.75),
                      duration: const Duration(milliseconds: 1800),
                      curve: Curves.easeOutQuart,
                      builder: (context, value, child) {
                        return SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        );
                      },
                    ),

                    // Center icon
                    AnimatedBuilder(
                      animation: _pulseAnimationController,
                      builder: (context, child) {
                        final pulseValue =
                            math.sin(
                                  _pulseAnimationController.value * math.pi,
                                ) *
                                0.1 +
                            1.0;
                        return Transform.scale(
                          scale: pulseValue,
            child: Container(
                            padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                              color: Colors.white,
                shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(width: 24),

                // Student info text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Status',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _studentData?['classes']?['name'] ??
                            'Class not assigned',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _studentData?['department'] ??
                            'Department not assigned',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String description,
    required int index,
    bool isNew = false,
  }) {
    // Initialize hover state if not present
    _navButtonHoverStates[index] ??= false;

    return AnimatedBuilder(
      animation: _navButtonControllers[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset((1 - _navButtonControllers[index].value) * 60, 0),
          child: Opacity(
            opacity: _navButtonControllers[index].value,
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _navButtonHoverStates[index] = true),
        onExit: (_) => setState(() => _navButtonHoverStates[index] = false),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _navButtonHoverStates[index] = true;
            });
            Future.delayed(const Duration(milliseconds: 150), () {
              setState(() {
                _navButtonHoverStates[index] = false;
              });
              onTap();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuint,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _navButtonHoverStates[index] == true
                      ? Colors.white.withOpacity(0.95)
                      : Colors.white.withOpacity(0.85),
                  _navButtonHoverStates[index] == true
                      ? Colors.white.withOpacity(0.85)
                      : Colors.white.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color:
                    _navButtonHoverStates[index] == true
                        ? color.withOpacity(0.3)
                        : Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(
                    _navButtonHoverStates[index] == true ? 0.25 : 0.15,
                  ),
                  blurRadius: _navButtonHoverStates[index] == true ? 25 : 15,
                  offset: Offset(
                    0,
                    _navButtonHoverStates[index] == true ? 5 : 8,
                  ),
                  spreadRadius: _navButtonHoverStates[index] == true ? 2 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _navButtonHoverStates[index] == true ? 10.0 : 5.0,
                  sigmaY: _navButtonHoverStates[index] == true ? 10.0 : 5.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern/icon
          Positioned(
                        right: -25,
                        bottom: -25,
                        child: Icon(
                          icon,
                          size: 120,
                          color: color.withOpacity(0.05),
                        ),
                      ),

                      // Animated gradient overlay
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        top: _navButtonHoverStates[index] == true ? -20 : -100,
                        right:
                            _navButtonHoverStates[index] == true ? -20 : -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                color.withOpacity(0.08),
                                color.withOpacity(0.05),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
                      ),

                      // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                        child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                            // Animated icon container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutQuint,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    color.withOpacity(
                                      _navButtonHoverStates[index] == true
                                          ? 1.0
                                          : 0.9,
                                    ),
                                    color.withOpacity(
                                      _navButtonHoverStates[index] == true
                                          ? 0.9
                                          : 1.0,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(
                                      _navButtonHoverStates[index] == true
                                          ? 0.4
                                          : 0.3,
                                    ),
                                    blurRadius:
                                        _navButtonHoverStates[index] == true
                                            ? 15
                                            : 10,
                                    offset: const Offset(0, 5),
                                    spreadRadius:
                                        _navButtonHoverStates[index] == true
                                            ? 1
                                            : 0,
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _floatingAnimationController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      _navButtonHoverStates[index] == true
                                          ? math.sin(
                                                _floatingAnimationController
                                                        .value *
                                                    math.pi *
                                                    2,
                                              ) *
                                              3
                                          : 0,
                                    ),
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                              fontWeight: FontWeight.bold,
                                            color: color,
                              letterSpacing: -0.5,
                            ),
                          ),
                                      ),
                                      if (isNew)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                              decoration: BoxDecoration(
                                            color: Colors.green.shade400,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                boxShadow: [
                                  BoxShadow(
                                                color: Colors.green.shade200
                                                    .withOpacity(0.5),
                                    blurRadius: 10,
                                                offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                                          child: Text(
                                            'NEW',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                                  const SizedBox(height: 8),
                                  Text(
                                    description,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                      height: 1.5,
                                    ),
                                  ),

                                  // Arrow indicator for hover state
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity:
                                        _navButtonHoverStates[index] == true
                                            ? 1.0
                                            : 0.0,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Row(
                    children: [
                                          Text(
                                            'EXPLORE',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: color,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: color,
                                            size: 16,
                          ),
                        ],
                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                      ),

                      // New feature badge
                      if (isNew)
                        Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .scale(
                                duration: 1.seconds,
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.2, 1.2),
                              )
                              .then()
                              .scale(
                                duration: 1.seconds,
                                begin: const Offset(1.2, 1.2),
                                end: const Offset(0.8, 0.8),
            ),
          ),
        ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int index,
  }) {
    // Initialize hover state if not present
    _quickActionHoverStates[index] ??= false;

    return AnimatedBuilder(
      animation: _quickActionControllers[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _quickActionControllers[index].value) * 40),
          child: Opacity(
            opacity: _quickActionControllers[index].value,
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _quickActionHoverStates[index] = true),
        onExit: (_) => setState(() => _quickActionHoverStates[index] = false),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _quickActionHoverStates[index] = true;
            });
            Future.delayed(const Duration(milliseconds: 150), () {
              setState(() {
                _quickActionHoverStates[index] = false;
              });
              onTap();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuint,
            decoration: BoxDecoration(
              color:
                  _quickActionHoverStates[index] == true ? color : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    _quickActionHoverStates[index] == true
                        ? Colors.transparent
                        : color.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(
                    _quickActionHoverStates[index] == true ? 0.4 : 0.15,
                  ),
                  blurRadius: _quickActionHoverStates[index] == true ? 20 : 10,
                  offset: Offset(
                    0,
                    _quickActionHoverStates[index] == true ? 5 : 8,
                  ),
                  spreadRadius: _quickActionHoverStates[index] == true ? 2 : 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
              children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          _quickActionHoverStates[index] == true
                              ? Colors.white.withOpacity(0.25)
                              : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color:
                          _quickActionHoverStates[index] == true
                              ? Colors.white
                              : color,
                    ),
                  ),
                  const SizedBox(width: 14),
                Text(
                  title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                    fontWeight: FontWeight.w600,
                      color:
                          _quickActionHoverStates[index] == true
                              ? Colors.white
                              : color,
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.black54,
            size: 24,
          ),
        ),
        if (_hasNewNotification)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                _notificationCount.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    // Initialize hover state if not present
    _navButtonHoverStates[index] ??= false;
  return AnimatedBuilder(
    animation: _statCardControllers[index],
    builder: (context, child) {
      return Transform.translate(
        offset: Offset(0, 50 * (1 - _statCardControllers[index].value)),
        child: Opacity(
          opacity: _statCardControllers[index].value,
          child: child,
        ),
      );
    },
      child: MouseRegion(
        onEnter: (_) => setState(() => _navButtonHoverStates[index] = true),
        onExit: (_) => setState(() => _navButtonHoverStates[index] = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform:
              _navButtonHoverStates[index] == true
                  ? (Matrix4.identity()..translate(0.0, -8.0))
                  : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(
                  _navButtonHoverStates[index] == true ? 0.4 : 0.25,
                ),
                blurRadius: _navButtonHoverStates[index] == true ? 25 : 15,
                offset: Offset(
                  0,
                  _navButtonHoverStates[index] == true ? 8 : 10,
                ),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 0,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    // Animated gradient overlay
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeInOut,
                      top: _navButtonHoverStates[index] == true ? -100 : -150,
                      left: _navButtonHoverStates[index] == true ? -100 : -150,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Background pattern
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        icon,
                        size: 120,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(icon, size: 26, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 4),
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: count),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Text(
                                value.toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define color schemes
    final assignmentsColor = Colors.blue.shade600;
    final gradesColor = Colors.purple.shade600;
    final scheduleColor = Colors.amber.shade700;
    final attendanceColor = Colors.green.shade600;
    const subjectsColor = Color(0xFF5856D6);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          // Background effects
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    math.sin(
                              _backgroundAnimationController.value *
                                  math.pi *
                                  2,
                            ) *
                            _maxBackgroundOffset +
                        _backgroundOffsetX,
                    math.cos(
                              _backgroundAnimationController.value *
                                  math.pi *
                                  2,
                            ) *
                            _maxBackgroundOffset +
                        _backgroundOffsetY,
                  ),
                  child: child,
                );
              },
              child: Opacity(
                opacity: 1.0,
                child: Image.asset(
                  'assets/images/image3.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Main content
          _isLoading
              ? const Center(child: CustomLoader())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 24),
                Text(
                      'Oops! Something went wrong',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                    fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _loadStats,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : SafeArea(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // App bar with profile and actions
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      floating: true,
                      pinned: false,
                      automaticallyImplyLeading: false,
                      actions: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Refresh button
                              InkWell(
                                onTap: _isRefreshing ? null : _refreshData,
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child:
                                      _isRefreshing
                                          ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.blue.shade600,
                                                  ),
                                            ),
                                          )
                                          : const Icon(
                                            Icons.refresh_rounded,
                                            color: Colors.black54,
                                            size: 24,
                                          ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Notification badge
                              InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Notifications panel will be available soon!',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: _buildNotificationBadge(),
                              ),
                              const SizedBox(width: 16),

                              // Profile avatar
                              InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  context.push('/profile');
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          _showGlow
                                              ? Colors.blue.shade400
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      if (_showGlow)
                                        BoxShadow(
                                          color: Colors.blue.shade400
                                              .withOpacity(0.5),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      (_studentData?['full_name']?[0] ?? 'S')
                                          .toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      expandedHeight: 80,
                    ),

                    // Main content
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Profile and welcome section
                          _buildProfileSection(),
                          const SizedBox(height: 36),

                          // Quick stats grid
                          Text(
                            'Quick Stats',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWideScreen = constraints.maxWidth > 600;
                              final isMediumScreen =
                                  constraints.maxWidth > 400 &&
                                  constraints.maxWidth <= 600;
                              final isSmallScreen = constraints.maxWidth <= 400;
                              double aspectRatio;
                              if (isWideScreen) {
                                aspectRatio = 1.4;
                              } else if (isMediumScreen) {
                                aspectRatio = 0.9;
                              } else {
                                aspectRatio = 0.7;
                              }
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 20,
                                childAspectRatio: aspectRatio,
                                children: [
                                  _buildStatCard(
                                    title: 'Assignmen',
                                    count: _assignmentsCount,
                                    icon: Icons.assignment_rounded,
                                    color: Colors.blue.shade600,
                                    index: 0,
                                  ),
                                  _buildStatCard(
                                    title: 'Grades',
                                    count: _gradesCount,
                                    icon: Icons.grade_rounded,
                                    color: Colors.purple.shade600,
                                    index: 1,
                                  ),
                                  _buildStatCard(
                                    title: 'Attendance',
                                    count: _attendanceCount,
                                    icon: Icons.person_pin_rounded,
                                    color: Colors.green.shade600,
                                    index: 2,
                                  ),
                                  _buildStatCard(
                                    title: 'Subjects',
                                    count: _subjectsCount,
                                    icon: Icons.book_rounded,
                                    color: const Color(0xFF5856D6),
                                    index: 3,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 36),

                          // Quick actions row
                          Text(
                            'Quick Actions',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildQuickActionButton(
                                  title: 'View Assignments',
                                  icon: Icons.assignment_rounded,
                                  color: assignmentsColor,
                                  onTap:
                                      () =>
                                          context.push('/student/assignments'),
                                  index: 0,
                                ),
                                const SizedBox(width: 16),
                                _buildQuickActionButton(
                                  title: 'Check Grades',
                                  icon: Icons.grade_rounded,
                                  color: gradesColor,
                                  onTap: () => context.push('/student/grades'),
                                  index: 1,
                                ),
                                const SizedBox(width: 16),
                                _buildQuickActionButton(
                                  title: 'View Schedule',
                                  icon: Icons.calendar_today_rounded,
                                  color: scheduleColor,
                                  onTap:
                                      () => context.push('/student/schedule'),
                                  index: 2,
                                ),
                                const SizedBox(width: 16),
                                _buildQuickActionButton(
                                  title: 'Attendance',
                                  icon: Icons.person_pin_rounded,
                                  color: attendanceColor,
                                  onTap:
                                      () => context.push('/student/attendance'),
                                  index: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Navigation menu
                          Text(
                            'Navigation',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Navigation buttons
                          _buildNavigationButton(
                            title: 'Assignments',
                            icon: Icons.assignment_rounded,
                            color: assignmentsColor,
                            description:
                                'View and manage your assignments and submissions',
                            onTap: () => context.push('/student/assignments'),
                            index: 0,
                          ),
                          _buildNavigationButton(
                            title: 'Grades',
                            icon: Icons.grade_rounded,
                            color: gradesColor,
                            description:
                                'Check your grades and academic performance',
                            onTap: () => context.push('/student/grades'),
                            index: 1,
                          ),
                          _buildNavigationButton(
                            title: 'Schedule',
                            icon: Icons.calendar_today_rounded,
                            color: scheduleColor,
                            description: 'View your class schedule and timings',
                            onTap: () => context.push('/student/schedule'),
                            index: 2,
                          ),
                          _buildNavigationButton(
                            title: 'Attendance',
                            icon: Icons.person_pin_rounded,
                            color: attendanceColor,
                            description:
                                'Track your attendance records and statistics',
                            onTap: () => context.push('/student/attendance'),
                            index: 3,
                          ),
                          _buildNavigationButton(
                            title: 'Subjects',
                            icon: Icons.book_rounded,
                            color: subjectsColor,
                            description:
                                'View your enrolled subjects and teachers',
                            onTap: () => context.push('/student/subjects'),
                            index: 4,
                          ),
                          _buildNavigationButton(
                            title: 'Settings',
                            icon: Icons.settings_rounded,
                            color: Colors.blueGrey.shade600,
                            description:
                                'Configure your profile and preferences',
                            onTap: () => context.push('/student/settings'),
                            index: 5,
                          ),

                          // Footer spacing
                          const SizedBox(height: 40),

                          // Footer with app info
                          Center(
                            child: Text(
                              'Student Management System v1.2.0',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                    fontWeight: FontWeight.w500,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
