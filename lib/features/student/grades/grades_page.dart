import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';
import 'package:intl/intl.dart';

class StudentGradesPage extends StatefulWidget {
  const StudentGradesPage({super.key});

  @override
  State<StudentGradesPage> createState() => _StudentGradesPageState();
}

class _StudentGradesPageState extends State<StudentGradesPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _grades = [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

Future<void> _loadGrades() async {
  try {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get student details first
    final studentResponse = await Supabase.instance.client
        .from('students')
        .select()
        .eq('email', user.email)
        .maybeSingle();

    if (studentResponse == null) {
      throw Exception('Student record not found');
    }

    // Get grades for the student with related data
    final response = await Supabase.instance.client
        .from('grades')
        .select('''
          id,
          grade,
          remarks,
          created_at,
          subjects (
            id,
            name
          ),
          teachers (
            id,
            full_name
          )
        ''')
        .eq('student_id', studentResponse['id'])
        .order('created_at', ascending: false);

    setState(() {
      _grades = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Failed to load grades: ${e.toString()}';
      _isLoading = false;
    });
  }
}

Widget _buildGradeCard(Map<String, dynamic> grade) {
  final subject = grade['subjects'] as Map<String, dynamic>;
  final teacher = grade['teachers'] as Map<String, dynamic>;
  final gradeValue = grade['grade'] as num;

  Color gradeColor;
  if (gradeValue >= 90) {
    gradeColor = CupertinoColors.systemGreen;
  } else if (gradeValue >= 70) {
    gradeColor = CupertinoColors.systemBlue;
  } else if (gradeValue >= 50) {
    gradeColor = CupertinoColors.systemOrange;
  } else {
    gradeColor = CupertinoColors.systemRed;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subject['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${gradeValue.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: gradeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.person,
                    size: 16,
                    color: Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Teacher: ${teacher['full_name']}',
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (grade['remarks'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.text_bubble,
                      size: 16,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        grade['remarks'],
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 16,
                    color: Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d, y').format(
                      DateTime.parse(grade['created_at']),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.systemBlue.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.systemIndigo.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => context.go('/student'),
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
                                CupertinoIcons.back,
                                color: CupertinoColors.systemBlue,
                                size: 20,
                              ),
                            ),
                          ),
                          const Text(
                            "Grades",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _loadGrades,
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
                                CupertinoIcons.refresh,
                                color: CupertinoColors.systemBlue,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CustomLoader())
                          : _errorMessage != null
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.exclamationmark_circle,
                                  color: CupertinoColors.systemRed,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: CupertinoColors.systemRed,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                CupertinoButton(
                                  onPressed: _loadGrades,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                          : _grades.isEmpty
                          ? const Center(
                            child: Text(
                              'No grades found',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 16,
                              ),
                            ),
                          )
                          : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            children: _grades.map(_buildGradeCard).toList(),
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
