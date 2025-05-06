import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> students = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isFiltered = false;
  bool _showSearch = false;
  List<Map<String, dynamic>> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    setState(() {
      _filteredStudents =
          students.where((student) {
            final studentName =
                student['full_name']?.toString().toLowerCase() ?? '';
            final studentEmail =
                student['email']?.toString().toLowerCase() ?? '';
            final className =
                student['classes']?['name']?.toString().toLowerCase() ?? '';
            final searchText = _searchController.text.toLowerCase();

            return searchText.isEmpty ||
                studentName.contains(searchText) ||
                studentEmail.contains(searchText) ||
                className.contains(searchText);
          }).toList();

      _isFiltered = _searchController.text.isNotEmpty;
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _filterStudents();
      }
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                _filterStudents();
              },
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search by student name, email or class...',
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: CupertinoColors.systemGrey,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: () {
                _searchController.clear();
                _filterStudents();
              },
              child: const Icon(
                CupertinoIcons.clear_circled_solid,
                color: CupertinoColors.systemGrey,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get teacher id robustly
      final teacherCheck = await Supabase.instance.client
          .from('teachers')
          .select()
          .eq('id', user.id);
      String teacherId = user.id;
      if (teacherCheck.isEmpty) {
        final emailCheck = await Supabase.instance.client
            .from('teachers')
            .select()
            .eq('email', user.email);
        if (emailCheck.isNotEmpty) {
          teacherId = emailCheck[0]['id'];
        }
      }

      // Get classes for this teacher
      final classesRes = await Supabase.instance.client
          .from('classes')
          .select('id')
          .eq('teacher_id', teacherId);
      final classIds = List<String>.from(
        classesRes.map((c) => c['id'].toString()),
      );

      // Get students in these classes with class name
      final studentsRes = await Supabase.instance.client
          .from('students')
          .select('id, full_name, email, class_id, classes(name)')
          .in_('class_id', classIds);

      // Get grades for these students
      final studentIds = studentsRes.map((s) => s['id']).toList();
      final gradesRes = await Supabase.instance.client
          .from('grades')
          .select('student_id')
          .in_('student_id', studentIds);
      final gradedStudentIds = Set<String>.from(
        gradesRes.map((g) => g['student_id']),
      );

      // Attach grade status to each student
      final studentsWithStatus =
          List<Map<String, dynamic>>.from(studentsRes).map((student) {
            return {
              ...student,
              'marksGiven': gradedStudentIds.contains(student['id']),
            };
          }).toList();

      setState(() {
        students = studentsWithStatus;
        _filteredStudents = studentsWithStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load students: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final className = student['classes']?['name'] ?? 'Not Assigned';
    final marksGiven = student['marksGiven'] == true;
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.person,
                    color: CupertinoColors.systemBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['full_name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1E1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student['email'] ?? 'No Email',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Class: $className',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      if (marksGiven)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.check_mark_circled,
                              color: CupertinoColors.systemGreen,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Marks Given',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.systemGreen,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    context.push('/teacher/grades/give/${student['id']}');
                  },
                  child: const Icon(
                    CupertinoIcons.chevron_right,
                    color: CupertinoColors.systemBlue,
                    size: 20,
                  ),
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
                color: const Color(0xFF5856D6).withOpacity(0.20),
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
                color: const Color(0xFF5856D6).withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Give Grades",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _toggleSearch,
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
                          child: Icon(
                            CupertinoIcons.search,
                            color:
                                _isFiltered
                                    ? CupertinoColors.systemBlue
                                    : CupertinoColors.systemGrey,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showSearch) _buildSearchBar(),
                if (_isLoading)
                  const Expanded(child: Center(child: CustomLoader()))
                else if (_errorMessage != null)
                  Expanded(
                    child: Center(
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
                            onPressed: loadStudents,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child:
                        _filteredStudents.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    CupertinoIcons.search,
                                    color: Color(0xFF8E8E93),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? 'No students found'
                                        : 'No results found for "${_searchController.text}"',
                                    style: const TextStyle(
                                      color: Color(0xFF8E8E93),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              itemCount: _filteredStudents.length,
                              itemBuilder:
                                  (context, index) => _buildStudentCard(
                                    _filteredStudents[index],
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
