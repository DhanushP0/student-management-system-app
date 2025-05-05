import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  String? _errorMessage;
  String _selectedSubject = '';
  String _selectedAssignment = '';
  List<Map<String, dynamic>> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final studentsResponse = await Supabase.instance.client
          .from('students')
          .select()
          .order('first_name');

      final assignmentsResponse = await Supabase.instance.client
          .from('assignments')
          .select()
          .order('due_date');

      setState(() {
        _students = List<Map<String, dynamic>>.from(studentsResponse);
        _assignments = List<Map<String, dynamic>>.from(assignmentsResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGrade(String studentId, String grade) async {
    try {
      await Supabase.instance.client.from('grades').insert({
        'student_id': studentId,
        'subject': _selectedSubject,
        'assignment_id': _selectedAssignment,
        'grade': grade,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Grade saved successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save grade: $e')));
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
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grades'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
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
                    value: _selectedSubject.isEmpty ? null : _selectedSubject,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: const [
                      DropdownMenuItem(value: 'Math', child: Text('Math')),
                      DropdownMenuItem(
                        value: 'Science',
                        child: Text('Science'),
                      ),
                      DropdownMenuItem(
                        value: 'English',
                        child: Text('English'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value!;
                        _selectedAssignment = '';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value:
                        _selectedAssignment.isEmpty
                            ? null
                            : _selectedAssignment,
                    decoration: const InputDecoration(labelText: 'Assignment'),
                    items:
                        _assignments
                            .where(
                              (assignment) =>
                                  assignment['subject'] == _selectedSubject,
                            )
                            .map((assignment) {
                              return DropdownMenuItem(
                                value: assignment['id'].toString(),
                                child: Text(assignment['title']),
                              );
                            })
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAssignment = value!;
                      });
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
                        student['first_name'][0].toString().toUpperCase(),
                      ),
                    ),
                    title: Text(
                      '${student['first_name']} ${student['last_name']}',
                    ),
                    subtitle: const Text('Enter grade'),
                    trailing: SizedBox(
                      width: 100,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Grade',
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _saveGrade(student['id'].toString(), value);
                          }
                        },
                      ),
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
