import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';
import 'package:student_management_app/core/widgets/app_scaffold.dart';

class AdminSignupScreen extends StatefulWidget {
  const AdminSignupScreen({super.key});
  @override
  State<AdminSignupScreen> createState() => _AdminSignUpPageState();
}

class _AdminSignUpPageState extends State<AdminSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _classController = TextEditingController();
  final _subjectController = TextEditingController();

  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentId;

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
    await Future.wait([_loadDepartments()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('departments')
          .select('id, name');
      _departments = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('❌ Error loading departments: $e');
    } finally {
      setState(() => _isLoading = false);
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
      final className = _classController.text.trim();
      final subject = _subjectController.text.trim();

      // 1. Sign up
      final authRes = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      // 2. Get user from auth response
      final user = authRes.user ?? authRes.session?.user;
      if (user == null) throw Exception('Signup failed: User is null');

      // 3. Optional buffer delay
      await Future.delayed(const Duration(seconds: 1));

      // 4. Insert into admins table
      final adminData = {
        'id': user.id,
        'full_name': name,
        'email': email,
        'phone_number': phone,
        'class': className,
        'subject': subject,
        'department_id': _selectedDepartmentId,
        'role_id': '43e9c4b8-ff53-424a-ab5a-ee1c83085e72',
      };

      await Supabase.instance.client.from('admins').insert(adminData);

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Signup successful!')));
        await Future.delayed(const Duration(milliseconds: 300)); // small buffer
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: FormField<String>(
              initialValue: value,
              validator: validator,
              builder: (FormFieldState<String> field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        // Show a cupertino style modal picker
                        showCupertinoModalPopup(
                          context: field.context,
                          builder: (BuildContext context) {
                            return Container(
                              height: 280,
                              padding: const EdgeInsets.only(top: 6.0),
                              // The bottom margin is provided to align the popup with the system navigation bar
                              margin: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              // Use a backdrop filter for the frosted glass effect
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemBackground
                                    .resolveFrom(context),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              // Use a SafeArea widget to avoid system overlaps.
                              child: SafeArea(
                                top: false,
                                child: Column(
                                  children: [
                                    // Picker header with title and done button
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemBackground
                                            .resolveFrom(context),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Select $label",
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: const Text(
                                              "Done",
                                              style: TextStyle(
                                                color:
                                                    CupertinoColors.systemBlue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Picker body
                                    Expanded(
                                      child: CupertinoPicker(
                                        magnification: 1.2,
                                        useMagnifier: true,
                                        itemExtent: 40,
                                        // This is called when selected item is changed.
                                        onSelectedItemChanged: (int i) {
                                          final selected =
                                              items[i]['id'].toString();
                                          onChanged(selected);
                                          field.didChange(selected);
                                        },
                                        scrollController:
                                            FixedExtentScrollController(
                                              initialItem:
                                                  value != null
                                                      ? items.indexWhere(
                                                        (item) =>
                                                            item['id']
                                                                .toString() ==
                                                            value,
                                                      )
                                                      : 0,
                                            ),
                                        children:
                                            items.map((item) {
                                              return Center(
                                                child: Text(
                                                  item['name'],
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              color: CupertinoColors.systemGrey,
                              size: 20,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                value != null
                                    ? items.firstWhere(
                                      (item) => item['id'].toString() == value,
                                      orElse: () => {'name': ''},
                                    )['name']
                                    : label,
                                style: TextStyle(
                                  color:
                                      value != null
                                          ? Colors.black87
                                          : const Color(0xFF8E8E93),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_down,
                              color: CupertinoColors.systemGrey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
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
                          "Admin Registration",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "Create a new Admin account",
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

                        _buildCupertinoFormField(
                          controller: _classController,
                          placeholder: "Classes Taught",
                          icon: CupertinoIcons.book,
                        ),

                        _buildCupertinoFormField(
                          controller: _subjectController,
                          placeholder: "Subject",
                          icon: CupertinoIcons.rectangle_stack_fill,
                        ),

                        _buildDropdownField(
                          label: "Department",
                          icon: CupertinoIcons.building_2_fill,
                          items: _departments,
                          value: _selectedDepartmentId,
                          onChanged: (value) {
                            setState(() => _selectedDepartmentId = value);
                          },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Please select a department'
                                      : null,
                        ),

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
                                            "Register as Admin",
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
