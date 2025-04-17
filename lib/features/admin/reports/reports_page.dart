import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/app_screen.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _classPerformance = [];
  List<Map<String, dynamic>> _recentSubmissions = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get overall statistics
      final statsRes = await Supabase.instance.client
          .from('assignments')
          .select('''
            id,
            assignment_submissions (
              id,
              grade
            )
          ''');

      // Calculate statistics
      int totalAssignments = statsRes.length;
      int totalSubmissions = 0;
      int gradedSubmissions = 0;
      double totalGrade = 0;

      for (var assignment in statsRes) {
        final submissions = assignment['assignment_submissions'] as List;
        totalSubmissions += submissions.length;
        final graded = submissions.where((s) => s['grade'] != null).length;
        gradedSubmissions += graded;
        for (var submission in submissions) {
          if (submission['grade'] != null) {
            totalGrade += submission['grade'] as double;
          }
        }
      }

      final averageGrade = gradedSubmissions > 0 ? totalGrade / gradedSubmissions : 0;

      // Get class performance
      final classRes = await Supabase.instance.client
          .from('teachers')
          .select('''
            class,
            department_id,
            assignment_submissions (
              grade
            )
          ''')
          .eq('role_id', '1392a59a-1ddc-4bf5-a5a2-20e7a177ad7c')
          .not('class', 'is', null);

      // Get department names
      final departmentIds = classRes
          .map((profile) => profile['department_id'] as String)
          .toSet()
          .toList();
      final departmentsRes = await Supabase.instance.client
          .from('departments')
          .select('id, name')
          .in_('id', departmentIds);

      final departmentMap = {
        for (var dept in departmentsRes)
          dept['id'] as String: dept['name'] as String
      };

      // Process class performance
      final classPerformance = <String, Map<String, dynamic>>{};
      for (var profile in classRes) {
        final className = profile['class'] as String;
        final departmentId = profile['department_id'] as String;
        final submissions = profile['assignment_submissions'] as List;
        
        if (!classPerformance.containsKey(className)) {
          classPerformance[className] = {
            'class': className,
            'department': departmentMap[departmentId] ?? 'Unknown Department',
            'total_submissions': 0,
            'graded_submissions': 0,
            'total_grade': 0.0,
          };
        }

        final stats = classPerformance[className]!;
        stats['total_submissions'] += submissions.length;
        final graded = submissions.where((s) => s['grade'] != null).length;
        stats['graded_submissions'] += graded;
        for (var submission in submissions) {
          if (submission['grade'] != null) {
            stats['total_grade'] += submission['grade'] as double;
          }
        }
      }

      // Calculate averages for each class
      for (var stats in classPerformance.values) {
        if (stats['graded_submissions'] > 0) {
          stats['average_grade'] = stats['total_grade'] / stats['graded_submissions'];
        } else {
          stats['average_grade'] = 0.0;
        }
      }

      // Get recent submissions
      final recentSubmissionsRes = await Supabase.instance.client
          .from('assignment_submissions')
          .select('''
            id,
            submitted_at,
            grade,
            feedback,
            assignments (
              title
            ),
            profiles:student_id (
              name
            )
          ''')
          .order('submitted_at', ascending: false)
          .limit(5);

      setState(() {
        _stats = {
          'total_assignments': totalAssignments,
          'total_submissions': totalSubmissions,
          'graded_submissions': gradedSubmissions,
          'average_grade': averageGrade,
        };
        _classPerformance = classPerformance.values.toList()
          ..sort((a, b) => (b['average_grade'] as double).compareTo(a['average_grade'] as double));
        _recentSubmissions = recentSubmissionsRes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading reports: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassPerformanceItem(Map<String, dynamic> performance) {
    final averageGrade = performance['average_grade'] as double;
    final totalSubmissions = performance['total_submissions'] as int;
    final gradedSubmissions = performance['graded_submissions'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                performance['class'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.black,
                ),
              ),
              Text(
                performance['department'],
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                CupertinoIcons.doc_text,
                size: 16,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Text(
                'Submissions: $totalSubmissions',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                CupertinoIcons.checkmark_circle,
                size: 16,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Text(
                'Graded: $gradedSubmissions',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                'Avg Grade: ${averageGrade.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: averageGrade >= 70
                      ? CupertinoColors.systemGreen
                      : averageGrade >= 50
                          ? CupertinoColors.systemOrange
                          : CupertinoColors.systemRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSubmissionItem(Map<String, dynamic> submission) {
    final submittedAt = DateTime.parse(submission['submitted_at']);
    final grade = submission['grade'];
    final assignment = submission['assignments'];
    final student = submission['profiles'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assignment['title'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                CupertinoIcons.person,
                size: 16,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Text(
                student['name'],
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (grade != null)
                Text(
                  'Grade: $grade',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: grade >= 70
                        ? CupertinoColors.systemGreen
                        : grade >= 50
                            ? CupertinoColors.systemOrange
                            : CupertinoColors.systemRed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                CupertinoIcons.clock,
                size: 16,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Text(
                'Submitted: ${submittedAt.toString().split('.')[0]}',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Reports',
      child: _isLoading
          ? const Center(child: CustomLoader())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: CupertinoColors.destructiveRed),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        onPressed: _loadReports,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Overall Statistics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            title: 'Total Assignments',
                            value: _stats['total_assignments'].toString(),
                            icon: CupertinoIcons.doc_text,
                            color: const Color(0xFF0A84FF),
                          ),
                          _buildStatCard(
                            title: 'Total Submissions',
                            value: _stats['total_submissions'].toString(),
                            icon: CupertinoIcons.paperplane,
                            color: const Color(0xFF34C759),
                          ),
                          _buildStatCard(
                            title: 'Graded Submissions',
                            value: _stats['graded_submissions'].toString(),
                            icon: CupertinoIcons.checkmark_circle,
                            color: const Color(0xFFFF9500),
                          ),
                          _buildStatCard(
                            title: 'Average Grade',
                            value: _stats['average_grade'].toStringAsFixed(1),
                            icon: CupertinoIcons.chart_bar,
                            color: const Color(0xFFFF2D55),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Class Performance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._classPerformance.map(_buildClassPerformanceItem),
                      const SizedBox(height: 24),
                      const Text(
                        'Recent Submissions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._recentSubmissions.map(_buildRecentSubmissionItem),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
} 