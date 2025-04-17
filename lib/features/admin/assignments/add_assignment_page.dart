import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class AddAssignmentPage extends StatefulWidget {
  const AddAssignmentPage({super.key});

  @override
  State<AddAssignmentPage> createState() => _AddAssignmentPageState();
}

class _AddAssignmentPageState extends State<AddAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedTeacherId;
  String? _selectedClassName;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    _loadClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    try {
      final response = await Supabase.instance.client
          .from('teachers')
          .select('id, full_name')
          .eq(
            'role_id',
            '42ba7a8b-51ba-4ea4-87f9-d807a05af783',
          ); // Teacher role ID

      setState(() {
        _teachers =
            (response as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadClasses() async {
    try {
      final response = await Supabase.instance.client
          .from('students')
          .select('class, department_id')
          .eq(
            'role_id',
            '1392a59a-1ddc-4bf5-a5a2-20e7a177ad7c',
          ) // Student role ID
          .not('class', 'is', null);

      // Get unique classes
      final uniqueClasses =
          (response as List)
              .map((teachers) => teachers['class'] as String)
              .toSet()
              .toList();

      // Get department names
      final departmentIds =
          (response)
              .map((teachers) => teachers['department_id'] as String)
              .toSet()
              .toList();
      final departmentsRes = await Supabase.instance.client
          .from('departments')
          .select('id, name')
          .in_('id', departmentIds);

      final departmentMap = {
        for (var dept in departmentsRes)
          dept['id'] as String: dept['name'] as String,
      };

      // Create class list with department names
      final classes =
          uniqueClasses.map((className) {
            final teachers = (response).firstWhere(
              (p) => p['class'] == className,
            );
            final departmentId = teachers['department_id'] as String;
            return {
              'id': className,
              'name': className,
              'department_name':
                  departmentMap[departmentId] ?? 'Unknown Department',
            };
          }).toList();

      setState(() {
        _classes = classes;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _addAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacherId == null) {
      setState(() => _error = 'Please select a teacher');
      return;
    }
    if (_selectedClassName == null) {
      setState(() => _error = 'Please select a class');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.from('assignments').insert({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'due_date': _dueDate.toIso8601String(),
        'teacher_id': _selectedTeacherId,
        'class': _selectedClassName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Assignment added successfully')),
        );
        context.go('/admin/assignments');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    bool isRequired = true,
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
              maxLines: maxLines,
              validator:
                  validator ??
                  (val) =>
                      isRequired && (val == null || val.isEmpty)
                          ? "Please enter ${label.toLowerCase()}"
                          : null,
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

  Widget _buildDatePicker() {
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder:
                              (BuildContext context) => Container(
                                height: 216,
                                padding: const EdgeInsets.only(bottom: 6),
                                margin: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom,
                                ),
                                color: CupertinoColors.systemBackground
                                    .resolveFrom(context),
                                child: SafeArea(
                                  top: false,
                                  child: CupertinoDatePicker(
                                    initialDateTime: _dueDate,
                                    mode: CupertinoDatePickerMode.date,
                                    use24hFormat: true,
                                    onDateTimeChanged: (DateTime newDate) {
                                      setState(() => _dueDate = newDate);
                                    },
                                  ),
                                ),
                              ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Due Date",
                            style: TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          Text(
                            '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
    required String? selected,
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
                              bool isSelected = selected == item[valueField];
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
                            selected != null
                                ? items.firstWhere(
                                  (item) => item[valueField] == selected,
                                  orElse:
                                      () => <String, String>{
                                        displayField: placeholder,
                                      },
                                )[displayField]
                                : placeholder,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  selected != null
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
                color: const Color(0xFFFF2D55).withOpacity(0.2),
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
                            onPressed: () => context.go('/admin/assignments'),
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
                            "Add Assignment",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildFormField(
                        label: "Title",
                        icon: CupertinoIcons.doc_text,
                        controller: _titleController,
                        validator:
                            (val) =>
                                val != null && val.isNotEmpty
                                    ? null
                                    : "Please enter a title",
                      ),
                      _buildFormField(
                        label: "Description",
                        icon: CupertinoIcons.text_alignleft,
                        controller: _descriptionController,
                        maxLines: 3,
                        isRequired: false,
                      ),
                      _buildDatePicker(),
                      _buildAppleStyleDropdown(
                        label: "Teacher",
                        icon: CupertinoIcons.person,
                        selected: _selectedTeacherId,
                        items: _teachers,
                        displayField: 'full_name',
                        valueField: 'id',
                        onChanged: (value) {
                          setState(() {
                            _selectedTeacherId = value;
                          });
                        },
                        placeholder: 'Select a teacher',
                      ),
                      _buildAppleStyleDropdown(
                        label: "Class",
                        icon: CupertinoIcons.rectangle_stack,
                        selected: _selectedClassName,
                        items: _classes,
                        displayField: 'name',
                        valueField: 'id',
                        onChanged: (value) {
                          setState(() {
                            _selectedClassName = value;
                          });
                        },
                        placeholder: 'Select a class',
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
                        onPressed: _isLoading ? null : _addAssignment,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A84FF), Color(0xFF0871DB)],
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
                                          "Add Assignment",
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
