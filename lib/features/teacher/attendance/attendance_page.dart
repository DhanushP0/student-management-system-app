import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class AttendancePage extends StatefulWidget {
  final String scheduleId;

  const AttendancePage({super.key, required this.scheduleId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceStatus = {};
  Map<String, dynamic>? schedule;
  bool _isLoading = true;
  bool isSaving = false;
  bool attendanceAlreadyTaken = false;
  DateTime selectedDate = DateTime.now();

  final List<String> statusOptions = ['present', 'absent', 'late', 'excused'];

  @override
  void initState() {
    super.initState();
    fetchScheduleAndStudents();
  }

  Future<void> fetchScheduleAndStudents() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch schedule details with related data
      final scheduleResponse =
          await supabase
              .from('schedule')
              .select('''
            *,
            teachers!inner(id, full_name),
            departments!inner(id, name),
            classes(id, name),
            subjects(id, name)
          ''')
              .eq('id', widget.scheduleId)
              .single();

      final classId = scheduleResponse['class_id'];
      final teacherId = scheduleResponse['teacher_id'];
      // print('classId: $classId');

      if (classId == null || teacherId == null) {
        throw Exception('class_id or teacher_id is missing from schedule');
      }

      // Check if attendance has already been taken for this schedule and date
      final today = DateFormat('yyyy-MM-dd').format(selectedDate);
      final existingAttendance = await supabase
          .from('attendance')
          .select()
          .eq('schedule_id', widget.scheduleId)
          .eq('date', today);

      if (existingAttendance.isNotEmpty) {
        setState(() {
          attendanceAlreadyTaken = true;
        });
      }

      // Fetch students for the class
      final studentResponse = await supabase
          .from('students')
          .select('id, full_name, email')
          .eq('class_id', classId)
          .order('full_name');

      final studentsList = List<Map<String, dynamic>>.from(studentResponse);

      // If attendance was already taken, load the existing statuses
      if (attendanceAlreadyTaken) {
        for (var record in existingAttendance) {
          attendanceStatus[record['student_id']] = record['status'];
        }
      } else {
        // Set default status as present
        for (var student in studentsList) {
          final studentId = student['id'];
          if (studentId != null) {
            attendanceStatus[studentId] = 'present';
          }
        }
      }

      setState(() {
        schedule = scheduleResponse;
        students = studentsList;
        _isLoading = false;
      });
    } catch (e) {
      // print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  Future<void> saveAttendance() async {
    if (schedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule data is missing.')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    final today = DateFormat('yyyy-MM-dd').format(selectedDate);
    final teacherId = schedule!['teacher_id'];
    final classId = schedule!['class_id'];
    final scheduleId = schedule!['id'];

    try {
      // If attendance was already taken, delete existing records first
      if (attendanceAlreadyTaken) {
        await supabase
            .from('attendance')
            .delete()
            .eq('schedule_id', scheduleId)
            .eq('date', today);
      }

      // Insert new attendance records
      for (var student in students) {
        final studentId = student['id'];
        final status = attendanceStatus[studentId];

        if ([studentId, teacherId, classId, scheduleId].contains(null)) {
          continue;
        }

        await supabase.from('attendance').insert({
          'student_id': studentId,
          'teacher_id': teacherId,
          'class_id': classId,
          'schedule_id': scheduleId,
          'date': today,
          'status': status,
        });
      }

      setState(() {
        attendanceAlreadyTaken = true;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Attendance saved successfully!')),
      );

      // Use go_router to navigate back to the schedule page
      Future.delayed(const Duration(milliseconds: 500), () {
        context.go('/teacher/schedule/$classId');
      });
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      // print('Error saving attendance: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save attendance: $e')));
    }
  }

  Widget _buildStatusDropdown(String studentId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(
          attendanceStatus[studentId] ?? 'present',
        ).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(
            attendanceStatus[studentId] ?? 'present',
          ).withOpacity(0.3),
        ),
      ),
      child: DropdownButton<String>(
        value: attendanceStatus[studentId],
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        items:
            statusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
        onChanged: (value) {
          setState(() {
            attendanceStatus[studentId] = value!;
          });
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CustomLoader()));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF2F6FF), Color(0xFFF9F9F9)],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C7BE).withOpacity(0.2),
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
                color: const Color(0xFF00C7BE).withOpacity(0.08),
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
                      Text(
                        'Attendance',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E1E1E),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (schedule != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule!['subjects']?['name'] ?? 'Subject',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${schedule!['time']} • ${schedule!['room']}',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Class: ${schedule!['classes']?['name'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child:
                      students.isEmpty
                          ? const Center(child: Text('No students found.'))
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              final student = students[index];
                              final studentId = student['id'];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      (student['full_name'] ?? '')[0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    student['full_name'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    student['email'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: _buildStatusDropdown(studentId),
                                ),
                              );
                            },
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : saveAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CupertinoColors.activeBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        elevation: 2,
                      ),
                      icon:
                          isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.save),
                      label: Text(
                        attendanceAlreadyTaken
                            ? 'Update Attendance'
                            : 'Save Attendance',
                      ),
                    ),
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
