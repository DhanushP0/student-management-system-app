import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';
import 'package:student_management_app/core/widgets/app_scaffold.dart';

class TeacherSignUpPage extends StatefulWidget {
  const TeacherSignUpPage({super.key});
  @override
  State<TeacherSignUpPage> createState() => _TeacherSignUpPageState();
}

class _TeacherSignUpPageState extends State<TeacherSignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _classes = [];
  String? _selectedDepartmentId;
  String? _selectedClassId;

  bool _isLoading = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _loadDepartments();
    setState(() => _isLoading = false);
  }

  Future<void> _loadDepartments() async {
    try {
      final res = await Supabase.instance.client
          .from('departments')
          .select('id, name')
          .order('name');
      _departments = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('❌ Error loading departments: $e');
    }
  }

  Future<void> _loadClasses(String departmentId) async {
    try {
      final res = await Supabase.instance.client
          .from('classes')
          .select('id, name')
          .eq('department_id', departmentId)
          .order('name');
      setState(() {
        _classes = List<Map<String, dynamic>>.from(res);
        _selectedClassId = null; // Reset selected class when department changes
      });
    } catch (e) {
      print('❌ Error loading classes: $e');
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Show loading dialog
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CustomLoader(size: 60, color: Color(0xFF0A84FF)),
          ),
    );

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final className = _selectedClassId;
      final subject = _subjectController.text.trim();

      // Sign up with Supabase Auth
      final authRes = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final userId = authRes.user?.id;
      if (userId != null) {
        final teacherData = {
          'id': userId,
          'full_name': name,
          'email': email,
          'phone_number': phone,
          'class': className,
          'subject': subject,
          'department_id': _selectedDepartmentId,
          'role_id': '42ba7a8b-51ba-4ea4-87f9-d807a05af783', // Teacher role ID
        };

        try {
          await Supabase.instance.client.from('teachers').insert(teacherData);
        } catch (error) {
          throw Exception('Insert failed: $error');
        }

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading dialog
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('✅ Signup successful!')));
          // Navigate to login page
          context.go('/login');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss loading dialog
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget backButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0.0, left: 10.0),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => context.go('/'),
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
            CupertinoIcons.chevron_left,
            color: CupertinoColors.systemBlue,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoFormField({
    required TextEditingController controller,
    required String placeholder,
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
            child: FormField<String>(
              initialValue: controller.text,
              validator: validator,
              builder: (FormFieldState<String> field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CupertinoTextField(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      placeholder: placeholder,
                      placeholderStyle: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 16,
                      ),
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Icon(
                          icon,
                          color: CupertinoColors.systemGrey,
                          size: 20,
                        ),
                      ),
                      suffix:
                          suffix != null
                              ? Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: suffix,
                              )
                              : null,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      keyboardType: keyboardType,
                      obscureText: obscureText,
                      onChanged: (value) {
                        field.didChange(value);
                        if (field.hasError) {
                          _formKey.currentState!.validate();
                        }
                      },
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          top: 8,
                          bottom: 4,
                        ),
                        child: Text(
                          field.errorText!,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
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
    return AppScreen(
      isLoading: _isLoading,
      child: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60), // Space for back button
                  // Rest of your content
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Avatar with frosted glass effect
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10.0,
                                  sigmaY: 10.0,
                                ),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.8),
                                        Colors.white.withOpacity(0.5),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      CupertinoIcons.person_badge_plus_fill,
                                      size: 36,
                                      color: CupertinoColors.systemIndigo,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          "Teacher Registration",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "Create a new teacher account",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8E8E93),
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Form fields
                        _buildCupertinoFormField(
                          controller: _nameController,
                          placeholder: "Full Name",
                          icon: CupertinoIcons.person,
                          validator:
                              (val) =>
                                  val != null && val.isNotEmpty
                                      ? null
                                      : "Please enter your name",
                        ),

                        _buildCupertinoFormField(
                          controller: _emailController,
                          placeholder: "Email Address",
                          icon: CupertinoIcons.mail,
                          keyboardType: TextInputType.emailAddress,
                          validator:
                              (val) =>
                                  val != null && val.contains('@')
                                      ? null
                                      : 'Enter a valid email',
                        ),

                        _buildCupertinoFormField(
                          controller: _passwordController,
                          placeholder: "Password",
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

                        _buildCupertinoFormField(
                          controller: _confirmPasswordController,
                          placeholder: "Confirm Password",
                          icon: CupertinoIcons.lock_shield,
                          obscureText: _obscureConfirm,
                          validator:
                              (val) =>
                                  val != null && val == _passwordController.text
                                      ? null
                                      : 'Passwords do not match',
                          suffix: GestureDetector(
                            onTap:
                                () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                            child: Icon(
                              _obscureConfirm
                                  ? CupertinoIcons.eye
                                  : CupertinoIcons.eye_slash,
                              color: CupertinoColors.systemGrey,
                              size: 20,
                            ),
                          ),
                        ),

                        _buildCupertinoFormField(
                          controller: _phoneController,
                          placeholder: "Phone Number",
                          icon: CupertinoIcons.phone,
                          keyboardType: TextInputType.phone,
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
                              // Load classes when department is selected
                              if (value != null) {
                                _loadClasses(value);
                              }
                            });
                          },
                          placeholder: 'Select a department',
                        ),

                        _buildAppleStyleDropdown(
                          label: "Class",
                          icon: CupertinoIcons.book,
                          selectedValue: _selectedClassId,
                          items: _classes,
                          displayField: 'name',
                          valueField: 'id',
                          onChanged:
                              (value) =>
                                  setState(() => _selectedClassId = value),
                          placeholder: 'Select a class',
                        ),

                        // _buildCupertinoFormField(
                        //   controller: _subjectController,
                        //   placeholder: "Subject",
                        //   icon: CupertinoIcons.rectangle_stack_fill,
                        // ),

                        // Error message
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: CupertinoColors.systemRed.withOpacity(
                                  0.3,
                                ),
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

                        // Create account button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _isLoading ? null : _signUp,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5856D6), Color(0xFF5E5CE6)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF5856D6,
                                  ).withOpacity(0.3),
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
                                            "Register as Teacher",
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

                        // Already have account
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 15,
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => context.go('/login'),
                                child: const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    color: CupertinoColors.systemIndigo,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Student Signup Link
                        Center(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => context.go('/signup'),
                            child: const Text(
                              "Go to Student Signup",
                              style: TextStyle(
                                color: CupertinoColors.systemBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 0,
            left: 22,
            child: backButton(context),
          ),
        ],
      ),
    );
  }
}
