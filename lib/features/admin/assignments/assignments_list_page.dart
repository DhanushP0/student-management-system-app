import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';
import 'package:intl/intl.dart';

class AssignmentsListPage extends StatefulWidget {
  const AssignmentsListPage({super.key});

  @override
  State<AssignmentsListPage> createState() => _AssignmentsListPageState();
}

class _AssignmentsListPageState extends State<AssignmentsListPage> {
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _filteredAssignments = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  bool _isFiltered = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _filterAssignments('');
      }
    });
  }

  void _filterAssignments(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAssignments = List.from(_assignments);
        _isFiltered = false;
      } else {
        _filteredAssignments =
            _assignments.where((assignment) {
              final title = assignment['title']?.toString().toLowerCase() ?? '';
              final description =
                  assignment['description']?.toString().toLowerCase() ?? '';
              final teacherName =
                  assignment['teacher_name']?.toString().toLowerCase() ?? '';
              final className =
                  assignment['class_id']?.toString().toLowerCase() ?? '';
              final searchQuery = query.toLowerCase();

              return title.contains(searchQuery) ||
                  description.contains(searchQuery) ||
                  teacherName.contains(searchQuery) ||
                  className.contains(searchQuery);
            }).toList();
        _isFiltered = true;
      }
    });
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch assignments
      final assignmentsRes = await Supabase.instance.client
          .from('assignments')
          .select('id, title, description, due_date, teacher_id, class_id')
          .order('due_date');

      // Fetch teacher info
      final teacherIds =
          assignmentsRes.map((a) => a['teacher_id'] as String).toSet();
      final teachersRes = await Supabase.instance.client
          .from('teachers')
          .select('id, full_name')
          .in_('id', teacherIds.toList());

      // Create a map of teacher id to name
      final teacherMap = {
        for (var teacher in teachersRes)
          teacher['id'] as String: teacher['full_name'] as String,
      };

      // Fetch class info
      final classRes = await Supabase.instance.client
          .from('classes')
          .select('id, name, department_id')
          .not('name', 'is', null);

      // Create a map of class_id to class name and department id
      final classMap = {
        for (var cls in classRes)
          cls['id'] as String: {
            'name': cls['name'] as String,
            'department_id': cls['department_id'] as String,
          },
      };

      // Fetch department info
      final departmentIds =
          classMap.values.map((cls) => cls['department_id']).toSet();
      final departmentsRes = await Supabase.instance.client
          .from('departments')
          .select('id, name')
          .in_('id', departmentIds.toList());

      // Create a map of department id to name
      final departmentMap = {
        for (var dept in departmentsRes)
          dept['id'] as String: dept['name'] as String,
      };

      // Combine all the data
      final assignments =
          assignmentsRes.map<Map<String, dynamic>>((assignment) {
            final teacherId = assignment['teacher_id'] as String;
            final classId = assignment['class_id'] as String;

            // Fetch teacher name
            final teacherName = teacherMap[teacherId] ?? 'Unknown Teacher';

            // Fetch class info
            final classInfo = classMap[classId];
            final className =
                classInfo?['name'] ??
                'Unknown Class'; // Ensure class name is fetched
            final departmentId = classInfo?['department_id'];
            final departmentName =
                departmentId != null
                    ? departmentMap[departmentId]
                    : 'Unknown Department';

            return {
              ...Map<String, dynamic>.from(assignment),
              'teacher_name': teacherName,
              'class_name': className, // Add class name to the assignment
              'department_name': departmentName,
            };
          }).toList();

      setState(() {
        _assignments = assignments.cast<Map<String, dynamic>>();
        _filteredAssignments = List.from(_assignments);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading assignments: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAssignment(String id) async {
    try {
      await Supabase.instance.client.from('assignments').delete().eq('id', id);

      if (mounted) {
        _loadAssignments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Assignment deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error deleting assignment: $e')),
        );
      }
    }
  }

  Widget _buildDialogAction({
    required Widget child,
    required VoidCallback onPressed,
    bool isDestructiveAction = false,
  }) {
    return CupertinoDialogAction(
      onPressed: onPressed,
      isDestructiveAction: isDestructiveAction,
      child: child,
    );
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
              onChanged: _filterAssignments,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search by title, description, or teacher...',
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
                _filterAssignments('');
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

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final dueDate = DateTime.parse(assignment['due_date']);
    final isOverdue = dueDate.isBefore(DateTime.now());

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isOverdue
                                ? CupertinoColors.systemRed.withOpacity(0.1)
                                : CupertinoColors.systemBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.doc_text_fill,
                        color:
                            isOverdue
                                ? CupertinoColors.systemRed
                                : CupertinoColors.systemBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            assignment['class_name'] ??
                                'No Class', // Use 'class_name' instead of 'class'
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Overdue',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  assignment['description'] ?? 'No description',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.person,
                      size: 16,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      assignment['teacher_name'] ?? 'Unknown Teacher',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      CupertinoIcons.calendar,
                      size: 16,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, y').format(dueDate),
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isOverdue
                                ? CupertinoColors.systemRed
                                : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed:
                          () => context.push(
                            '/admin/assignments/edit/${assignment['id']}',
                          ),
                      child: const Icon(
                        CupertinoIcons.pencil,
                        color: CupertinoColors.systemBlue,
                        size: 20,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed:
                          () => showCupertinoDialog(
                            context: context,
                            builder:
                                (context) => CupertinoAlertDialog(
                                  title: const Text('Delete Assignment'),
                                  content: Text(
                                    'Are you sure you want to delete "${assignment['title']}"? This action cannot be undone.',
                                  ),
                                  actions: [
                                    _buildDialogAction(
                                      child: const Text('Cancel'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    _buildDialogAction(
                                      isDestructiveAction: true,
                                      child: const Text('Delete'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteAssignment(assignment['id']);
                                      },
                                    ),
                                  ],
                                ),
                          ),
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: CupertinoColors.systemRed,
                        size: 20,
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
                color: const Color(0xFFFF2D55).withOpacity(0.2),
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
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => context.go('/admin'),
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
                          const SizedBox(width: 16),
                          const Text(
                            "Assignments",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
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
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed:
                                () => context.go('/admin/assignments/add'),
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
                                CupertinoIcons.add,
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
                if (_showSearch) _buildSearchBar(),
                if (_isLoading)
                  const Expanded(child: Center(child: CustomLoader()))
                else if (_error != null)
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
                            _error!,
                            style: const TextStyle(
                              color: CupertinoColors.systemRed,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CupertinoButton(
                            onPressed: _loadAssignments,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child:
                        _filteredAssignments.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    CupertinoIcons.doc_text_search,
                                    color: Color(0xFF8E8E93),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? 'No assignments found'
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
                              itemCount: _filteredAssignments.length,
                              itemBuilder:
                                  (context, index) => _buildAssignmentCard(
                                    _filteredAssignments[index],
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
