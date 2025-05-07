import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _filteredSchedules = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  bool _isFiltered = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSchedules() {
    setState(() {
      _filteredSchedules =
          _schedules.where((schedule) {
            final roomName = schedule['room']?.toString().toLowerCase() ?? '';
            final subjectName =
                schedule['subjects']?['name']?.toString().toLowerCase() ?? '';
            final className =
                schedule['classes']?['name']?.toString().toLowerCase() ?? '';
            final departmentName =
                schedule['departments']?['name']?.toString().toLowerCase() ??
                '';
            final time = schedule['time']?.toString().toLowerCase() ?? '';
            final searchText = _searchController.text.toLowerCase();
            final matchesSearch =
                searchText.isEmpty ||
                roomName.contains(searchText) ||
                subjectName.contains(searchText) ||
                className.contains(searchText) ||
                departmentName.contains(searchText) ||
                time.contains(searchText);
            return matchesSearch;
          }).toList();
      _isFiltered = _searchController.text.isNotEmpty;
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _filterSchedules();
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
                _filterSchedules();
              },
              autofocus: true,
              decoration: const InputDecoration(
                hintText:
                    'Search by Room, Subject, Class...'
                    ' (e.g. Math, 101, Science)',
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
                _filterSchedules();
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

  Future<void> _loadSchedules() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First, check if the teacher exists by ID
      final teacherCheck = await Supabase.instance.client
          .from('teachers')
          .select()
          .eq('id', user.id);

      String teacherId = user.id;

      // If not found by ID, try by email
      if (teacherCheck.isEmpty) {
        final emailCheck = await Supabase.instance.client
            .from('teachers')
            .select()
            .eq('email', user.email);

        if (emailCheck.isNotEmpty) {
          teacherId = emailCheck[0]['id'];
        }
      }

      final response = await Supabase.instance.client
          .from('schedule')
          .select('''
            *,
            teachers(id, full_name),
            departments(id, name),
            classes(id, name),
            subjects(id, name)
          ''')
          .eq('teacher_id', teacherId)
          .order('created_at');

      setState(() {
        _schedules = List<Map<String, dynamic>>.from(response);
        _filteredSchedules = List.from(_schedules);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<bool> isAttendanceTaken(String scheduleId) async {
    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final res = await Supabase.instance.client
        .from('attendance')
        .select('id')
        .eq('schedule_id', scheduleId)
        .eq('date', todayStr);
    return res != null && res.isNotEmpty;
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final teacherName = schedule['teachers']?['full_name'] ?? '';
    final className = schedule['classes']?['name'] ?? 'Not Assigned';
    final subjectName = schedule['subjects']?['name'] ?? 'Not Assigned';
    final room = schedule['room'] ?? 'Not Assigned';
    final time = schedule['time'] ?? 'Not Scheduled';
    final departmentName = schedule['departments']?['name'] ?? 'Not Assigned';
    final date = schedule['date'] != null ? schedule['date'].toString() : '';
    final scheduleId = schedule['id'];

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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1E1E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Room: $room',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E93),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.book,
                  label: 'Subject',
                  value: subjectName,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.group,
                  label: 'Class',
                  value: className,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.business,
                  label: 'Department',
                  value: departmentName,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: date,
                ),
                const SizedBox(height: 16),
                FutureBuilder<bool>(
                  future: isAttendanceTaken(scheduleId),
                  builder: (context, snapshot) {
                    final taken = snapshot.data ?? false;
                    return Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          context.push('/teacher/attendance/$scheduleId');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                taken
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.systemBlue,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            taken ? 'Edit Attendance' : 'Take Attendance',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8E8E93)),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF1E1E1E)),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                      onPressed: () => context.go('/teacher'),
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
                      "My Schedule",
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
                          color: Color(0xFF00C7BE),
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
                          onPressed: _loadSchedules,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child:
                      _filteredSchedules.isEmpty
                          ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.calendar,
                                  color: Color(0xFF8E8E93),
                                  size: 48,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No schedules found',
                                  style: TextStyle(
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
                            itemCount: _filteredSchedules.length,
                            itemBuilder:
                                (context, index) => _buildScheduleCard(
                                  _filteredSchedules[index],
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
