import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class TeachersListPage extends StatefulWidget {
  const TeachersListPage({super.key});

  @override
  State<TeachersListPage> createState() => _TeachersListPageState();
}

class _TeachersListPageState extends State<TeachersListPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _filteredTeachers = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  bool _isFiltered = false;
  bool _showSearch = false;

  static const String teacherRoleId = '42ba7a8b-51ba-4ea4-87f9-d807a05af783';

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTeachers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTeachers = List.from(_teachers);
        _isFiltered = false;
      } else {
        _filteredTeachers = _teachers.where((teacher) {
          final name = teacher['full_name']?.toString().toLowerCase() ?? '';
          final email = teacher['email']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return name.contains(searchQuery) ||
              email.contains(searchQuery);
        }).toList();
        _isFiltered = true;
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _filterTeachers('');
      }
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
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
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _filterTeachers,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: Icon(CupertinoIcons.search, color: CupertinoColors.systemGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: () {
                _searchController.clear();
                _filterTeachers('');
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

  Future<void> _loadTeachers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await Supabase.instance.client
          .from('teachers')
          .select()
          .eq('role_id', teacherRoleId)
          .order('full_name');

      setState(() {
        _teachers = List<Map<String, dynamic>>.from(response);
        _filteredTeachers = List.from(_teachers);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTeacher(String teacherId) async {
    try {
      await Supabase.instance.client
          .from('teachers')
          .delete()
          .eq('id', teacherId);
      
      await _loadTeachers(); // Reload the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Teacher deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error deleting teacher: $e')),
        );
      }
    }
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
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
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_crop_circle_badge_checkmark,
                    color: CupertinoColors.systemGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher['full_name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        teacher['email'] ?? 'No Email',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => context.push('/admin/teachers/edit/${teacher['id']}'),
                      child: const Icon(
                        CupertinoIcons.pencil,
                        color: CupertinoColors.systemBlue,
                        size: 20,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Delete Teacher'),
                          content: const Text('Are you sure you want to delete this teacher?'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('Delete'),
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteTeacher(teacher['id']);
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
                color: CupertinoColors.systemGreen.withOpacity(0.1),
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
                      Row(
                        children: [
                          const Text(
                            "Teachers",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (_isFiltered) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Filtered',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
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
                                color: _isFiltered ? CupertinoColors.systemGreen : CupertinoColors.systemGrey,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => context.go('/admin/teachers/add'),
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
                                color: CupertinoColors.systemGreen,
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
                  const Expanded(
                    child: Center(
                      child: CustomLoader(),
                    ),
                  )
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
                            onPressed: _loadTeachers,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: _filteredTeachers.isEmpty
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
                                      ? 'No teachers found'
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
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _filteredTeachers.length,
                            itemBuilder: (context, index) =>
                                _buildTeacherCard(_filteredTeachers[index]),
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