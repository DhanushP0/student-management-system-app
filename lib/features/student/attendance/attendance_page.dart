import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key});

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _attendance = [];
  Map<String, dynamic> _stats = {
    'present': 0,
    'absent': 0,
    'late': 0,
    'total': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get student's info first
      final studentResponse =
          await Supabase.instance.client
              .from('students')
              .select('id, class_id')
              .eq('email', user.email)
              .single();

      if (studentResponse == null) throw Exception('Student not found');

      // Get attendance records with related data
      final response = await Supabase.instance.client
          .from('attendance')
          .select('''
          id,
          date,
          status,
          schedule!inner (
            id,
            time,
            room,
            subject:subject_id (
              id,
              name
            )
          ),
          teachers (
            id,
            full_name
          )
        ''')
          .eq('student_id', studentResponse['id'])
          .order('date', ascending: false);

      setState(() {
        _attendance = List<Map<String, dynamic>>.from(response);
        _calculateStats();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading attendance: $e');
      setState(() {
        _errorMessage = 'Failed to load attendance: $e';
        _isLoading = false;
      });
    }
  }

  void _calculateStats() {
    _stats = {
      'present': 0,
      'absent': 0,
      'late': 0,
      'excused': 0,
      'total': _attendance.length,
    };

    for (var record in _attendance) {
      final status = record['status'] as String;
      _stats[status] = (_stats[status] ?? 0) + 1;
    }
  }

  // void _calculateStats() {
  //   _stats = {
  //     'present': 0,
  //     'absent': 0,
  //     'late': 0,
  //     'total': _attendance.length,
  //   };

  //   for (var record in _attendance) {
  //     switch (record['status']) {
  //       case 'present':
  //         _stats['present']++;
  //         break;
  //       case 'absent':
  //         _stats['absent']++;
  //         break;
  //       case 'late':
  //         _stats['late']++;
  //         break;
  //     }
  //   }
  // }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Present',
                      _stats['present'],
                      CupertinoColors.systemGreen,
                    ),
                    _buildStatItem(
                      'Absent',
                      _stats['absent'],
                      CupertinoColors.systemRed,
                    ),
                    _buildStatItem(
                      'Late',
                      _stats['late'],
                      CupertinoColors.systemOrange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total Classes: ${_stats['total']}',
                    style: const TextStyle(
                      color: CupertinoColors.systemBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final schedule = record['schedule'] as Map<String, dynamic>;
    final subject = schedule['subject'] as Map<String, dynamic>;
    final teacher = record['teachers'] as Map<String, dynamic>;
    final date = DateTime.parse(record['date']);
    final status = record['status'] as String;
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'present':
        statusColor = CupertinoColors.systemGreen;
        statusIcon = CupertinoIcons.checkmark_circle;
        break;
      case 'absent':
        statusColor = CupertinoColors.systemRed;
        statusIcon = CupertinoIcons.xmark_circle;
        break;
      case 'late':
        statusColor = CupertinoColors.systemOrange;
        statusIcon = CupertinoIcons.clock;
        break;
      default:
        statusColor = CupertinoColors.systemGrey;
        statusIcon = CupertinoIcons.question_circle;
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      teacher['full_name'],
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.calendar,
                      size: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
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
                  child: Row(
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
                        "Attendance",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _loadAttendance,
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
                ),
                _buildStatsCard(),
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
                                  onPressed: _loadAttendance,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                          : _attendance.isEmpty
                          ? const Center(
                            child: Text(
                              'No attendance records found',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 16,
                              ),
                            ),
                          )
                          : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            children:
                                _attendance.map(_buildAttendanceCard).toList(),
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
