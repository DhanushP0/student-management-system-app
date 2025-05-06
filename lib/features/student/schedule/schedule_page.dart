import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';
import 'package:intl/intl.dart';

class StudentSchedulePage extends StatefulWidget {
  const StudentSchedulePage({super.key});

  @override
  State<StudentSchedulePage> createState() => _StudentSchedulePageState();
}

class _StudentSchedulePageState extends State<StudentSchedulePage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _filteredSchedules = [];
  // String _selectedDay = 'Monday';

  // final List<String> _days = [
  //   'Monday',
  //   'Tuesday',
  //   'Wednesday',
  //   'Thursday',
  //   'Friday',
  //   'Saturday',
  // ];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

Future<void> _loadSchedules() async {
  try {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get student's class ID and department
    final studentResponse = await Supabase.instance.client
        .from('students')
        .select('class_id, departments!inner(id)')
        .eq('email', user.email)
        .maybeSingle();

    if (studentResponse == null) {
      throw Exception('Student record not found');
    }

    final classId = studentResponse['class_id'];
    final departmentId = studentResponse['departments']['id'];

    // Get schedules for the student's class and department
// Get schedules for the student's class and department
final response = await Supabase.instance.client
    .from('schedule')
    .select('''
      id,
      time,
      room,
      date,
      subject_id,
      teachers:teacher_id (
        id,
        full_name
      ),
      subjects!inner (
        id,
        name,
        class_id,
        department_id
      )
    ''')
    .eq('subjects.class_id', classId)
    .eq('subjects.department_id', departmentId);

// print('Raw Schedule Response: $response'); // Debug all schedules

    setState(() {
      _schedules = List<Map<String, dynamic>>.from(response);
      _filteredSchedules = _schedules;
      _isLoading = false;
    });
  } catch (e) {
    print('Error loading schedules: $e'); // Debug print
    setState(() {
      _errorMessage = 'Failed to load schedule: $e';
      _isLoading = false;
    });
  }
}

Widget _buildScheduleCard(Map<String, dynamic> schedule) {
  final subject = schedule['subjects'] as Map<String, dynamic>;
  final teacher = schedule['teachers'] as Map<String, dynamic>;
  final room = schedule['room'];
  final time = schedule['time'];
  final date = DateTime.parse(schedule['date']);

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
                      color: CupertinoColors.systemBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(
                        color: CupertinoColors.systemBlue,
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
                    teacher['full_name'],
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.location,
                    size: 16,
                    color: Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Room $room',
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
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
                    color: Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMM d').format(date),
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
                            "Schedule",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _loadSchedules,
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
                      const SizedBox(height: 24),
                    //   SizedBox(
                    //     height: 40,
                    //     child: ListView.builder(
                    //       scrollDirection: Axis.horizontal,
                    //       itemCount: _days.length,
                    //       itemBuilder: (context, index) {
                    //         final day = _days[index];
                    //         final isSelected = day == _selectedDay;
                    //         return Padding(
                    //           padding: const EdgeInsets.only(right: 8),
                    //           child: CupertinoButton(
                    //             padding: EdgeInsets.zero,
                    //             onPressed: () {
                    //               setState(() {
                    //                 _selectedDay = day;
                    //                 _filterSchedules();
                    //               });
                    //             },
                    //             child: Container(
                    //               padding: const EdgeInsets.symmetric(
                    //                 horizontal: 16,
                    //                 vertical: 8,
                    //               ),
                    //               decoration: BoxDecoration(
                    //                 color:
                    //                     isSelected
                    //                         ? CupertinoColors.systemBlue
                    //                         : Colors.white.withOpacity(0.8),
                    //                 borderRadius: BorderRadius.circular(20),
                    //                 boxShadow: [
                    //                   BoxShadow(
                    //                     color: Colors.black.withOpacity(0.05),
                    //                     blurRadius: 10,
                    //                     offset: const Offset(0, 4),
                    //                   ),
                    //                 ],
                    //               ),
                    //               child: Text(
                    //                 day,
                    //                 style: TextStyle(
                    //                   color:
                    //                       isSelected
                    //                           ? Colors.white
                    //                           : CupertinoColors.systemGrey,
                    //                   fontWeight: FontWeight.w600,
                    //                 ),
                    //               ),
                    //             ),
                    //           ),
                    //         );
                    //       },
                    //     ),
                    //   ),
                    // ],
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
                                  onPressed: _loadSchedules,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                          : _filteredSchedules.isEmpty
                          ? const Center(
                            child: Text(
                              'No classes scheduled',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 16,
                              ),
                            ),
                          )
                          : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            children:
                                _filteredSchedules
                                    .map(_buildScheduleCard)
                                    .toList(),
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
