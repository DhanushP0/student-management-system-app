import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isLoading = true;
  int _studentCount = 0;
  int _teacherCount = 0;
  int _classCount = 0;
  int _assignmentCount = 0;
  final _profileKey = GlobalKey();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get student count
      final studentRes = await Supabase.instance.client
          .from('students')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('role_id', '1392a59a-1ddc-4bf5-a5a2-20e7a177ad7c');
      _studentCount = studentRes.count ?? 0;

      // Get teacher count
      final teacherRes = await Supabase.instance.client
          .from('teachers')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('role_id', '42ba7a8b-51ba-4ea4-87f9-d807a05af783');
      _teacherCount = teacherRes.count ?? 0;

      final classRes = await Supabase.instance.client
          .from('classes')
          .select('name')
          .not('name', 'is', null);

      _classCount = classRes.map((row) => row['name'] as String).toSet().length;

      // Get assignment count
      final assignmentsRes = await Supabase.instance.client
          .from('assignments')
          .select('id', const FetchOptions(count: CountOption.exact));
      _assignmentCount = assignmentsRes.count ?? 0;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading stats: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading stats: $e')));
      }
    }
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String description,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileMenu() {
    final RenderBox button =
        _profileKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Colors.transparent,
      items: [
        PopupMenuItem(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.15),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: CupertinoColors.systemBlue.withOpacity(
                                0.2,
                              ),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://ui-avatars.com/api/?name=Admin&background=0A84FF&color=fff',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Administrator',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildMenuItem(
                      icon: CupertinoIcons.person_crop_circle,
                      title: 'My Profile',
                      onTap: () {
                        context.push('/profile');
                      },
                    ),
                    _buildMenuItem(
                      icon: CupertinoIcons.bell,
                      title: 'Notifications',
                      onTap: () {
                        context.push('/notifications');
                      },
                    ),
                    _buildMenuItem(
                      icon: CupertinoIcons.settings,
                      title: 'Settings',
                      onTap: () {
                        context.push('/settings');
                      },
                    ),
                    _buildMenuItem(
                      icon: CupertinoIcons.square_arrow_right,
                      title: 'Sign Out',
                      isDestructive: true,
                      onTap: () async {
                        await _showSignOutConfirmation();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showSignOutConfirmation() async {
    final parentContext = context; // Capture the outer context

    return showCupertinoDialog<void>(
      context: parentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: CupertinoAlertDialog(
            title: const Text("Sign Out"),
            content: const Text("Are you sure you want to sign out?"),
            actions: <Widget>[
              CupertinoDialogAction(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Supabase.instance.client.auth.signOut();

                  // Use parentContext and mounted check
                  if (mounted) {
                    parentContext.go('/');
                  }
                },
                child: const Text("Sign Out"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color:
                    isDestructive
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemBlue,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color:
                      isDestructive
                          ? CupertinoColors.systemRed
                          : const Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _searchBar() {
  //   return ClipRRect(
  //     borderRadius: BorderRadius.circular(16),
  //     child: BackdropFilter(
  //       filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
  //       child: Container(
  //         decoration: BoxDecoration(
  //           color: Colors.white.withOpacity(0.8),
  //           borderRadius: BorderRadius.circular(16),
  //           border: Border.all(
  //             color: Colors.white.withOpacity(0.5),
  //             width: 1.5,
  //           ),
  //         ),
  //         child: const CupertinoTextField(
  //           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //           placeholder: "Search...",
  //           placeholderStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
  //           prefix: Padding(
  //             padding: EdgeInsets.only(left: 8),
  //             child: Icon(
  //               CupertinoIcons.search,
  //               color: CupertinoColors.systemGrey,
  //               size: 20,
  //             ),
  //           ),
  //           decoration: BoxDecoration(color: Colors.transparent),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _errorBox(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CupertinoColors.systemRed.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              color: CupertinoColors.systemRed,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _errorMessage = null),
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                color: CupertinoColors.systemRed,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
            child: _circle(CupertinoColors.systemBlue.withOpacity(0.1), 250),
          ),
          Positioned(
            bottom: -80,
            left: -50,
            child: _circle(CupertinoColors.systemIndigo.withOpacity(0.08), 200),
          ),
          _isLoading
              ? const Center(child: CustomLoader())
              : SafeArea(
                child: RefreshIndicator(
                  onRefresh: _loadStats,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Admin Dashboard",
                                        style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E1E1E),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Welcome back, Admin",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    key: _profileKey,
                                    onTap: _showProfileMenu,
                                    child: Container(
                                      width: 50,
                                      height: 60,
                                      margin: const EdgeInsets.only(
                                        top: 0,
                                        right: 0,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: CupertinoColors.systemBlue
                                            .withOpacity(0.1),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.8),
                                          width: 2,
                                        ),
                                        image: const DecorationImage(
                                          image: NetworkImage(
                                            'https://ui-avatars.com/api/?name=Admin&background=0A84FF&color=fff',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // _searchBar(),
                              if (_errorMessage != null)
                                _errorBox(_errorMessage!),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildQuickAction(
                                      title: "Add Student",
                                      icon: CupertinoIcons.person_badge_plus,
                                      color: CupertinoColors.systemBlue,
                                      onTap:
                                          () => context.push(
                                            '/admin/students/add',
                                          ),
                                    ),
                                    const SizedBox(width: 10),
                                    _buildQuickAction(
                                      title: "Add Teacher",
                                      icon:
                                          CupertinoIcons
                                              .person_crop_circle_badge_plus,
                                      color: CupertinoColors.systemGreen,
                                      onTap:
                                          () => context.push(
                                            '/admin/teachers/add',
                                          ),
                                    ),
                                    // const SizedBox(width: 10),
                                    // _buildQuickAction(
                                    //   title: "Reports",
                                    //   icon: CupertinoIcons.chart_bar_alt_fill,
                                    //   color: CupertinoColors.systemIndigo,
                                    //   onTap:
                                    //       () => context.push('/admin/reports'),
                                    // ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  "Dashboard Overview",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                            children: [
                              _buildStatCard(
                                title: 'Students',
                                count: _studentCount,
                                icon: CupertinoIcons.person_2_fill,
                                color: const Color(0xFF0A84FF),
                              ),
                              _buildStatCard(
                                title: 'Teachers',
                                count: _teacherCount,
                                icon:
                                    CupertinoIcons
                                        .person_crop_circle_badge_checkmark,
                                color: const Color(0xFF34C759),
                              ),
                              _buildStatCard(
                                title: 'Classes',
                                count: _classCount,
                                icon: CupertinoIcons.book_fill,
                                color: const Color(0xFFFF9500),
                              ),
                              _buildStatCard(
                                title: 'Assignments',
                                count: _assignmentCount,
                                icon: CupertinoIcons.doc_text_fill,
                                color: const Color(0xFFFF2D55),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 16,
                                ),
                                child: Text(
                                  "Manage System",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              _buildNavigationButton(
                                title: 'Students',
                                icon: CupertinoIcons.person_2_fill,
                                color: const Color(0xFF0A84FF),
                                onTap: () => context.push('/admin/students'),
                                description:
                                    'View, add, edit, and manage student profiles and enrollment',
                              ),
                              const SizedBox(height: 16),
                              _buildNavigationButton(
                                title: 'Teachers',
                                icon:
                                    CupertinoIcons
                                        .person_crop_circle_badge_checkmark,
                                color: const Color(0xFF34C759),
                                onTap: () => context.push('/admin/teachers'),
                                description:
                                    'Manage faculty information, assignments, and class allocations',
                              ),
                              const SizedBox(height: 16),
                              _buildNavigationButton(
                                title: 'Classes',
                                icon: CupertinoIcons.book_fill,
                                color: const Color(0xFFFF9500),
                                onTap: () => context.push('/admin/classes'),
                                description:
                                    'Organize and monitor classroom data, schedules, and enrollments',
                              ),
                              const SizedBox(height: 16),
                              _buildNavigationButton(
                                title: 'Assignments',
                                icon: CupertinoIcons.doc_text_fill,
                                color: const Color(0xFFFF2D55),
                                onTap: () => context.push('/admin/assignments'),
                                description:
                                    'Track and manage assignments, submissions, and grading',
                              ),
                              const SizedBox(height: 16),
                              _buildNavigationButton(
                                title: 'Subjects',
                                icon: CupertinoIcons.book,
                                color: const Color(0xFF5856D6),
                                onTap: () => context.push('/admin/subjects'),
                                description:
                                    'Manage subjects and their details',
                              ),
                              const SizedBox(height: 16),
                              _buildNavigationButton(
                                title: 'Schedule',
                                icon: CupertinoIcons.calendar,
                                color: const Color(0xFF00C7BE),
                                onTap: () => context.push('/admin/schedule'),
                                description:
                                    'Manage class timetables, room assignments, and teacher schedules',
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActionsSheet(),
        backgroundColor: CupertinoColors.systemBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showActionsSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Quick Actions'),
            message: const Text('Choose an action to perform'),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/admin/students/add');
                },
                child: const Text('Add New Student'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/admin/teachers/add');
                },
                child: const Text('Add New Teacher'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/admin/classes/add');
                },
                child: const Text('Create New Class'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/admin/assignments/add');
                },
                child: const Text('Create New Assignment'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/admin/schedule/add');
                },
                child: const Text('Add New Schedule'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ),
    );
  }
}
