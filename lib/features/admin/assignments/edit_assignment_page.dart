import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class EditAssignmentPage extends StatefulWidget {
  final String assignmentId;

  const EditAssignmentPage({super.key, required this.assignmentId});

  @override
  State<EditAssignmentPage> createState() => _EditAssignmentPageState();
}

class _EditAssignmentPageState extends State<EditAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _dueDate = DateTime.now();
  String? _selectedTeacherId;
  String? _selectedClassName;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadAssignment();
    _loadTeachers();
    _loadClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignment() async {
    try {
      final response =
          await Supabase.instance.client
              .from('assignments')
              .select('''
            *,
            teachers:teacher_id (
              id,
              full_name,
              email
            ),
            classes:class_id (
              id,
              name,
              department_id
            )
          ''')
              .eq('id', widget.assignmentId)
              .single();

      if (mounted) {
        setState(() {
          _titleController.text = response['title'] ?? '';
          _descriptionController.text = response['description'] ?? '';
          _dueDate = DateTime.parse(response['due_date']);
          _selectedTeacherId = response['teacher_id'];
          _selectedClassName = response['classes']?['id'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load assignment details: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTeachers() async {
    try {
      final response = await Supabase.instance.client
          .from('teachers')
          .select('id,full_name')
          .eq(
            'role_id',
            '42ba7a8b-51ba-4ea4-87f9-d807a05af783',
          ); // Teacher role ID

      setState(() {
        _teachers = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadClasses() async {
    try {
      final response = await Supabase.instance.client
          .from('classes')
          .select('id, name, department_id');

      setState(() {
        _classes = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _updateAssignment() async {
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
      _isSaving = true;
      _error = null;
    });

    try {
      await Supabase.instance.client
          .from('assignments')
          .update({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'due_date': _dueDate.toIso8601String(),
            'teacher_id': _selectedTeacherId,
            'class': _selectedClassName,
          })
          .eq('id', widget.assignmentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Assignment updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
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
              keyboardType: keyboardType,
              validator: validator,
              maxLines: maxLines,
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String hintText,
    required String? selectedValue,
    required List<Map<String, dynamic>> items,
    required String itemLabelKey,
    required Function(String?) onChanged,
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
            child: InkWell(
              onTap: () {
                showCupertinoModalPopup(
                  context: context,
                  builder:
                      (BuildContext context) => Container(
                        height: 300,
                        padding: const EdgeInsets.only(bottom: 6),
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        color: CupertinoColors.systemBackground.resolveFrom(
                          context,
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemBackground
                                      .resolveFrom(context),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: CupertinoColors.systemGrey4
                                          .resolveFrom(context),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Done'),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: CupertinoPicker(
                                  itemExtent: 32,
                                  onSelectedItemChanged: (index) {
                                    final item = items[index];
                                    onChanged(item['id']);
                                  },
                                  children:
                                      items.map((item) {
                                        return Center(
                                          child: Text(
                                            item[itemLabelKey] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: CupertinoColors.systemGrey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedValue != null
                                ? items.firstWhere(
                                      (item) => item['id'] == selectedValue,
                                      orElse: () => {itemLabelKey: hintText},
                                    )[itemLabelKey] ??
                                    hintText
                                : hintText,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  selectedValue != null
                                      ? CupertinoColors.label
                                      : CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      color: CupertinoColors.systemGrey,
                      size: 20,
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

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime selectedDate,
    required Function(DateTime) onChanged,
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
            child: InkWell(
              onTap: () {
                showCupertinoModalPopup(
                  context: context,
                  builder:
                      (BuildContext context) => Container(
                        height: 216,
                        padding: const EdgeInsets.only(bottom: 6),
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        color: CupertinoColors.systemBackground.resolveFrom(
                          context,
                        ),
                        child: SafeArea(
                          top: false,
                          child: CupertinoDatePicker(
                            initialDateTime: selectedDate,
                            mode: CupertinoDatePickerMode.date,
                            use24hFormat: true,
                            onDateTimeChanged: onChanged,
                          ),
                        ),
                      ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(icon, color: CupertinoColors.systemBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.calendar,
                      color: CupertinoColors.systemGrey,
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
                color:const Color(0xFFFF2D55).withOpacity(0.2),
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
                          const Text(
                            "Edit Assignment",
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
                      if (_isLoading)
                        const Center(
                          child: CustomLoader(
                            size: 40,
                            color: CupertinoColors.systemBlue,
                          ),
                        )
                      else
                        Column(
                          children: [
                            _buildFormField(
                              controller: _titleController,
                              label: "Title",
                              icon: CupertinoIcons.doc_text,
                              validator:
                                  (val) =>
                                      val != null && val.isNotEmpty
                                          ? null
                                          : "Please enter a title",
                            ),
                            _buildFormField(
                              controller: _descriptionController,
                              label: "Description",
                              icon: CupertinoIcons.text_alignleft,
                              maxLines: 3,
                              validator: (val) => null, // Optional field
                            ),
                            _buildDateField(
                              label: "Due Date",
                              icon: CupertinoIcons.calendar,
                              selectedDate: _dueDate,
                              onChanged: (date) {
                                setState(() => _dueDate = date);
                              },
                            ),
                            _buildDropdownField(
                              label: "Teacher",
                              icon: CupertinoIcons.person,
                              hintText: "Select a teacher",
                              selectedValue: _selectedTeacherId,
                              items: _teachers,
                              itemLabelKey: "name",
                              onChanged: (value) {
                                setState(() => _selectedTeacherId = value);
                              },
                            ),
                            _buildDropdownField(
                              label: "Class",
                              icon: CupertinoIcons.book,
                              hintText: "Select a class",
                              selectedValue: _selectedClassName,
                              items: _classes,
                              itemLabelKey: "name",
                              onChanged: (value) {
                                setState(() => _selectedClassName = value);
                              },
                            ),
                            if (_error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemRed.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: CupertinoColors.systemRed
                                        .withOpacity(0.3),
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
                              onPressed: _isSaving ? null : _updateAssignment,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF007AFF),
                                      Color(0xFF0066CC),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF007AFF,
                                      ).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child:
                                      _isSaving
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
                                                "Update Assignment",
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
                          ],
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
