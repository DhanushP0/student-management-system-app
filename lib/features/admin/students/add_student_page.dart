import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _uucmsController = TextEditingController();
  final _classController = TextEditingController();

  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentId;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await Supabase.instance.client
          .from('departments')
          .select('id, name')
          .order('name');
      
      setState(() {
        _departments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First create the auth user
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final userId = authResponse.user?.id;
      if (userId != null) {
        // Get the student role ID
        final roleResponse = await Supabase.instance.client
            .from('roles')
            .select('id')
            .eq('name', 'student')
            .single();
        
        final studentRoleId = roleResponse['id'];

        // Create the students
        final students = {
          'id': userId,
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'class': _classController.text.trim(),
          'department_id': _selectedDepartmentId,
          'role_id': studentRoleId,
          'uucms_id': _uucmsController.text.trim(),
        };

        await Supabase.instance.client.from('students').insert(students);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Student added successfully')),
          );
          context.go('/admin/students');
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffix,
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
                suffixIcon: suffix,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String? value,
    required void Function(String?) onChanged,
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
            child: DropdownButtonFormField<String>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['id'],
                  child: Text(item['name']),
                );
              }).toList(),
              onChanged: onChanged,
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
                color: Colors.orange.shade300.withOpacity(0.2),
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => context.go('/admin/students'),
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
                            "Add Student",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 40), // For balance
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildFormField(
                        controller: _nameController,
                        label: "Full Name",
                        icon: CupertinoIcons.person,
                        validator: (val) =>
                            val != null && val.isNotEmpty
                                ? null
                                : "Please enter a name",
                      ),
                      _buildFormField(
                        controller: _emailController,
                        label: "Email Address",
                        icon: CupertinoIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) =>
                            val != null && val.contains('@')
                                ? null
                                : 'Enter a valid email',
                      ),
                      _buildFormField(
                        controller: _passwordController,
                        label: "Password",
                        icon: CupertinoIcons.lock,
                        obscureText: _obscurePassword,
                        validator: (val) =>
                            val != null && val.length >= 6
                                ? null
                                : 'Password must be at least 6 characters',
                        suffix: GestureDetector(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            color: CupertinoColors.systemGrey,
                            size: 20,
                          ),
                        ),
                      ),
                      _buildFormField(
                        controller: _phoneController,
                        label: "Phone Number",
                        icon: CupertinoIcons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildFormField(
                        controller: _uucmsController,
                        label: "UUCMS ID",
                        icon: CupertinoIcons.number,
                      ),
                      _buildFormField(
                        controller: _classController,
                        label: "Class",
                        icon: CupertinoIcons.book,
                      ),
                      _buildDropdownField(
                        label: "Department",
                        icon: CupertinoIcons.building_2_fill,
                        items: _departments,
                        value: _selectedDepartmentId,
                        onChanged: (value) {
                          setState(() => _selectedDepartmentId = value);
                        },
                        validator: (value) =>
                            value == null
                                ? 'Please select a department'
                                : null,
                      ),
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CupertinoColors.systemRed.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_circle,
                                color: CupertinoColors.systemRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: CupertinoColors.systemRed,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _isLoading ? null : _addStudent,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A84FF), Color(0xFF0077E6)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0A84FF).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const CustomLoader(
                                    size: 28,
                                    color: Colors.white,
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.checkmark_circle,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Add Student",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 