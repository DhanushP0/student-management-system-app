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

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _selectedClassId;
  String? _selectedDepartmentId;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _years = [];
  String? _selectedYearId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadYears();
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

  // _loadClasses function ensures that the dropdown list is updated
  Future<void> _loadClasses(String departmentId) async {
    try {
      final response = await Supabase.instance.client
          .from('classes')
          .select('id, name')
          .eq('department_id', departmentId)
          .order('name');

      setState(() {
        _classes = List<Map<String, dynamic>>.from(response);
        _selectedClassId = null; // Reset selected class if needed
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load classes';
      });
    }
  }

  Future<void> _loadYears() async {
    try {
      final response = await Supabase.instance.client
          .from('years')
          .select('id, year')
          .order('year');

      setState(() {
        _years = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load years';
      });
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
        final roleResponse =
            await Supabase.instance.client
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
          'class_id': _selectedClassId,
          'department_id': _selectedDepartmentId,
          'role_id': studentRoleId,
          'uucms_id': _uucmsController.text.trim(),
          'year_id': _selectedYearId,
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

  Widget _buildAppleClassesDropdown({
    required String label,
    required IconData icon,
    required String? selectedValue,
    required List<Map<String, dynamic>> items,
    required String displayField,
    required String valueField,
    required Function(String?) onChanged,
    required String placeholder,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.systemGrey5,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder:
                      (BuildContext context) => CupertinoActionSheet(
                        title: Text('Select $label'),
                        message: const Text('Tap an option to select it'),
                        actions:
                            items.map((item) {
                              bool isSelected =
                                  selectedValue == item[valueField];
                              return CupertinoActionSheetAction(
                                onPressed: () {
                                  onChanged(item[valueField]);
                                  Navigator.pop(context);
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item[displayField],
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? CupertinoColors.activeBlue
                                                : CupertinoColors.label,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        CupertinoIcons.check_mark,
                                        color: CupertinoColors.activeBlue,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                        cancelButton: CupertinoActionSheetAction(
                          isDefaultAction: true,
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: CupertinoColors.secondaryLabel, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedValue != null
                                ? items.firstWhere(
                                  (item) => item[valueField] == selectedValue,
                                  orElse: () => {displayField: placeholder},
                                )[displayField]
                                : placeholder,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  selectedValue != null
                                      ? CupertinoColors.label
                                      : CupertinoColors.tertiaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      color: CupertinoColors.tertiaryLabel,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppleStyleDropdown({
    required String label,
    required IconData icon,
    required String? selectedValue,
    required List<Map<String, dynamic>> items,
    required String displayField,
    required String valueField,
    required Function(String?) onChanged,
    required String placeholder,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.systemGrey5,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder:
                      (BuildContext context) => CupertinoActionSheet(
                        title: Text('Select $label'),
                        message: const Text('Tap an option to select it'),
                        actions:
                            items.map((item) {
                              bool isSelected =
                                  selectedValue == item[valueField];
                              return CupertinoActionSheetAction(
                                onPressed: () {
                                  onChanged(item[valueField]);
                                  Navigator.pop(context);
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item[displayField],
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? CupertinoColors.activeBlue
                                                : CupertinoColors.label,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        CupertinoIcons.check_mark,
                                        color: CupertinoColors.activeBlue,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                        cancelButton: CupertinoActionSheetAction(
                          isDefaultAction: true,
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: CupertinoColors.secondaryLabel, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedValue != null
                                ? items.firstWhere(
                                  (item) => item[valueField] == selectedValue,
                                  orElse: () => {displayField: placeholder},
                                )[displayField]
                                : placeholder,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  selectedValue != null
                                      ? CupertinoColors.label
                                      : CupertinoColors.tertiaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      color: CupertinoColors.tertiaryLabel,
                      size: 14,
                    ),
                  ],
                ),
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
                        validator:
                            (val) =>
                                val != null && val.isNotEmpty
                                    ? null
                                    : "Please enter a name",
                      ),
                      _buildFormField(
                        controller: _emailController,
                        label: "Email Address",
                        icon: CupertinoIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        validator:
                            (val) =>
                                val != null && val.contains('@')
                                    ? null
                                    : 'Enter a valid email',
                      ),
                      _buildFormField(
                        controller: _passwordController,
                        label: "Password",
                        icon: CupertinoIcons.lock,
                        obscureText: _obscurePassword,
                        validator:
                            (val) =>
                                val != null && val.length >= 6
                                    ? null
                                    : 'Password must be at least 6 characters',
                        suffix: GestureDetector(
                          onTap:
                              () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
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
                      _buildAppleStyleDropdown(
                        label: "Department",
                        icon: CupertinoIcons.building_2_fill,
                        selectedValue: _selectedDepartmentId,
                        items: _departments,
                        displayField: 'name',
                        valueField: 'id',
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartmentId = value;
                            // Trigger loading classes when department is changed
                            if (value != null) {
                              _loadClasses(
                                value,
                              ); // Correctly call _loadClasses when the department is changed
                            }
                          });
                        },
                        placeholder: 'Select a department',
                      ),
                      _buildAppleClassesDropdown(
                        label: 'Class',
                        icon: CupertinoIcons.book,
                        selectedValue: _selectedClassId,
                        items: _classes,
                        displayField: 'name',
                        valueField: 'id',
                        onChanged:
                            (value) => setState(() => _selectedClassId = value),
                        placeholder: 'Select Class',
                      ),
                      _buildAppleStyleDropdown(
                        label: "Academic Year",
                        icon: CupertinoIcons.calendar,
                        selectedValue: _selectedYearId,
                        items: _years,
                        displayField:
                            'year',
                        valueField: 'id',
                        onChanged: (value) {
                          setState(() => _selectedYearId = value);
                        },
                        placeholder: 'Select year',
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
                            child:
                                _isLoading
                                    ? const CustomLoader(
                                      size: 28,
                                      color: Colors.white,
                                    )
                                    : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
