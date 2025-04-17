import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class EditStudentPage extends StatefulWidget {
  final String studentId;

  const EditStudentPage({
    super.key,
    required this.studentId,
  });

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _uucmsController = TextEditingController();
  final _classController = TextEditingController();

  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _uucmsController.dispose();
    _classController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load student data
      final studentResponse = await Supabase.instance.client
          .from('students')
          .select()
          .eq('id', widget.studentId)
          .single();

      // Load departments
      final departmentsResponse = await Supabase.instance.client
          .from('departments')
          .select()
          .order('name');

      if (mounted) {
        setState(() {
          // Set form values
          _nameController.text = studentResponse['full_name'] ?? '';
          _emailController.text = studentResponse['email'] ?? '';
          _phoneController.text = studentResponse['phone'] ?? '';
          _uucmsController.text = studentResponse['uucms_id'] ?? '';
          _classController.text = studentResponse['class'] ?? '';
          _selectedDepartmentId = studentResponse['department_id'];
          
          // Set departments
          _departments = List<Map<String, dynamic>>.from(departmentsResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client.from('students').update({
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'class': _classController.text.trim(),
        'department_id': _selectedDepartmentId,
        'uucms_id': _uucmsController.text.trim(),
      }).eq('id', widget.studentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Student updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error updating student: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              validator: validator,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedDepartmentId,
              items: _departments.map((department) {
                return DropdownMenuItem<String>(
                  value: department['id'],
                  child: Text(department['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDepartmentId = value);
              },
              decoration: const InputDecoration(
                labelText: 'Department',
                prefixIcon: Icon(CupertinoIcons.building_2_fill),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
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
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => context.pop(),
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
                      const Expanded(
                        child: Text(
                          "Edit Student",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 44), // Balance the back button
                    ],
                  ),
                ),
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
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          _buildFormField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: CupertinoIcons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name';
                              }
                              return null;
                            },
                          ),
                          _buildFormField(
                            controller: _emailController,
                            label: 'Email',
                            icon: CupertinoIcons.mail,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          _buildFormField(
                            controller: _phoneController,
                            label: 'Phone',
                            icon: CupertinoIcons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          _buildFormField(
                            controller: _uucmsController,
                            label: 'UUCMS ID',
                            icon: CupertinoIcons.number,
                          ),
                          _buildFormField(
                            controller: _classController,
                            label: 'Class',
                            icon: CupertinoIcons.book,
                          ),
                          _buildDropdownField(),
                          const SizedBox(height: 24),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _isSaving ? null : _updateStudent,
                            child: Container(
                              width: double.infinity,
                              height: 60,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    CupertinoColors.systemBlue,
                                    Color(0xFF2B88D9),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.systemBlue.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: _isSaving
                                  ? const Center(
                                      child: SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Update',                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
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