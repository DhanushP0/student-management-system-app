import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  String? _errorMessage;
  String? _selectedClassId;
  List<Map<String, dynamic>> _classes = [];
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await Supabase.instance.client
          .from('classes')
          .select()
          .eq('teacher_id', user.id);

      setState(() {
        _classes = List<Map<String, dynamic>>.from(response);
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first['id'].toString();
          _loadStudents();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load classes: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await Supabase.instance.client
          .from('students')
          .select()
          .eq('class_id', _selectedClassId)
          .order('full_name');

      setState(() {
        _students = List<Map<String, dynamic>>.from(response);
        _attendanceStatus = {
          for (var student in _students) student['id'].toString(): 'present',
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load students: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAttendance() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final attendanceRecords =
          _attendanceStatus.entries.map((entry) {
            return {
              'student_id': entry.key,
              'teacher_id': user.id,
              'class_id': _selectedClassId,
              'date': _selectedDate.toIso8601String().split('T')[0],
              'status': entry.value,
            };
          }).toList();

      await Supabase.instance.client
          .from('attendance')
          .insert(attendanceRecords);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save attendance: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CustomLoader());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            ElevatedButton(
              onPressed: _loadStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveAttendance),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items:
                        _classes.map((class_) {
                          return DropdownMenuItem(
                            value: class_['id'].toString(),
                            child: Text(class_['name']),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClassId = value;
                      });
                      _loadStudents();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('Date'),
                    subtitle: Text(_selectedDate.toString().split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        student['full_name'][0].toString().toUpperCase(),
                      ),
                    ),
                    title: Text(student['full_name']),
                    subtitle: Text(student['email'] ?? 'No email'),
                    trailing: DropdownButton<String>(
                      value: _attendanceStatus[student['id'].toString()],
                      items: const [
                        DropdownMenuItem(
                          value: 'present',
                          child: Text('Present'),
                        ),
                        DropdownMenuItem(
                          value: 'absent',
                          child: Text('Absent'),
                        ),
                        DropdownMenuItem(value: 'late', child: Text('Late')),
                        DropdownMenuItem(
                          value: 'excused',
                          child: Text('Excused'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _attendanceStatus[student['id'].toString()] = value!;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
