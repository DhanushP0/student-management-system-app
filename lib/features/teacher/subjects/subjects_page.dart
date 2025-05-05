import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _subjects = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeTeacher();
  }

  Future<void> _initializeTeacher() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if teacher exists
      final teacherResponse = await Supabase.instance.client
          .from('teachers')
          .select()
          .eq('id', user.id);

      if (teacherResponse.isEmpty) {
        // Check if teacher exists with the same email
        final emailCheck = await Supabase.instance.client
            .from('teachers')
            .select()
            .eq('email', user.email);

        if (emailCheck.isNotEmpty) {
          // Instead of updating the ID, we'll use the existing teacher record
          // No need to update anything, just proceed with loading subjects
        } else {
          // Show dialog to collect teacher information
          if (!mounted) return;

          final result = await showDialog<Map<String, String>>(
            context: context,
            barrierDismissible: false,
            builder: (context) => const TeacherInfoDialog(),
          );

          if (result == null) {
            throw Exception('Teacher information is required');
          }

          // Create teacher record
          await Supabase.instance.client.from('teachers').insert({
            'id': user.id,
            'full_name': result['full_name'],
            'email': result['email'],
            'phone_number': result['phone_number'],
          });
        }
      }

      // Load subjects after teacher is set up
      await _loadSubjects();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize teacher: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First, let's check if the teacher exists
      final teacherCheck = await Supabase.instance.client
          .from('teachers')
          .select()
          .eq('id', user.id);

      String teacherId = user.id;

      // If teacher not found by ID, try to find by email
      if (teacherCheck.isEmpty) {
        final emailCheck = await Supabase.instance.client
            .from('teachers')
            .select()
            .eq('email', user.email);

        if (emailCheck.isNotEmpty) {
          teacherId = emailCheck[0]['id'];
        }
      }

      // Get the teacher's subjects
      final response = await Supabase.instance.client
          .from('teacher_subject_years')
          .select('''
            id,
            subject_id,
            year_id,
            subjects (
              id,
              name
            ),
            years (
              id,
              year
            )
          ''')
          .eq('teacher_id', teacherId)
          .order('created_at');

      setState(() {
        _subjects = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load subjects: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final subjectData = subject['subjects'] as Map<String, dynamic>;
    final yearData = subject['years'] as Map<String, dynamic>;

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
                    color: CupertinoColors.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.book,
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
                        subjectData['name'] ?? 'No Subject',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1E1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Year: ${yearData['year']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey,
                  size: 20,
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
                        "My Subjects",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _loadSubjects,
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
                            color: Color(0xFF5856D6),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const Expanded(
                    child: Center(child: CupertinoActivityIndicator()),
                  )
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
                            onPressed: _initializeTeacher,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child:
                        _subjects.isEmpty
                            ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.book,
                                    color: Color(0xFF8E8E93),
                                    size: 48,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No subjects assigned yet',
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
                              itemCount: _subjects.length,
                              itemBuilder:
                                  (context, index) =>
                                      _buildSubjectCard(_subjects[index]),
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

class TeacherInfoDialog extends StatefulWidget {
  const TeacherInfoDialog({super.key});

  @override
  State<TeacherInfoDialog> createState() => _TeacherInfoDialogState();
}

class _TeacherInfoDialogState extends State<TeacherInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Teacher Information'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'full_name': _fullNameController.text,
                'email': _emailController.text,
                'phone_number': _phoneController.text,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
