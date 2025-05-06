import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';

class GiveGradePage extends StatefulWidget {
  final String studentId;
  const GiveGradePage({super.key, required this.studentId});

  @override
  State<GiveGradePage> createState() => _GiveGradePageState();
}

class _GiveGradePageState extends State<GiveGradePage> {
  final supabase = Supabase.instance.client;
  String? selectedSubjectId;
  String? selectedTeacherId;
  double? grade;
  String? remarks;
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> teachers = [];
  Map<String, dynamic>? studentInfo;
  String? className;
  bool isSaving = false;
  bool marksGiven = false;
  final _gradeController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    // Fetch student info with class name
    final studentRes =
        await supabase
            .from('students')
            .select('id, full_name, email, class_id, classes(name)')
            .eq('id', widget.studentId)
            .single();
    studentInfo = studentRes;
    className = studentRes['classes']?['name'] ?? 'Not Assigned';

    final subjectData = await supabase.from('subjects').select('id, name');
    final teacherData = await supabase.from('teachers').select('id, full_name');
    setState(() {
      subjects = List<Map<String, dynamic>>.from(subjectData);
      teachers = List<Map<String, dynamic>>.from(teacherData);
    });
  }

  Future<void> checkMarksGiven() async {
    if (selectedSubjectId == null) {
      setState(() => marksGiven = false);
      return;
    }
    final gradeRes = await supabase
        .from('grades')
        .select('id')
        .eq('student_id', widget.studentId)
        .eq('subject_id', selectedSubjectId);
    setState(() {
      marksGiven = gradeRes != null && gradeRes.isNotEmpty;
    });
  }

  @override
  void didUpdateWidget(covariant GiveGradePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedSubjectId != null) {
      checkMarksGiven();
    }
  }

  Future<void> saveGrade() async {
    if (selectedSubjectId == null ||
        selectedTeacherId == null ||
        grade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }
    setState(() => isSaving = true);
    try {
      await supabase.from('grades').insert({
        'student_id': widget.studentId,
        'subject_id': selectedSubjectId,
        'teacher_id': selectedTeacherId,
        'grade': grade,
        'remarks': remarks,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Grade saved successfully!')),
      );
      setState(() {
        selectedSubjectId = null;
        selectedTeacherId = null;
        grade = null;
        remarks = null;
        _gradeController.clear();
        _remarksController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving grade: $e')));
    } finally {
      setState(() => isSaving = false);
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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

  Widget _buildStudentInfoCard() {
    if (studentInfo == null) return const SizedBox.shrink();
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
                    CupertinoIcons.person,
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
                        studentInfo!['full_name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1E1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        studentInfo!['email'] ?? 'No Email',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Class: $className',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarksGivenBadge() {
    if (!marksGiven) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.check_mark_circled,
            color: CupertinoColors.systemGreen,
            size: 24,
          ),
          SizedBox(width: 8),
          Text(
            'Marks Given',
            style: TextStyle(
              color: CupertinoColors.systemGreen,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if ((subjects.isEmpty || teachers.isEmpty || studentInfo == null) &&
        !isSaving) {
      return const Scaffold(body: Center(child: CustomLoader()));
    }
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
                          "Give Grade",
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
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildStudentInfoCard(),
                      if (marksGiven) _buildMarksGivenBadge(),
                      _buildAppleStyleDropdown(
                        label: "Subject",
                        icon: CupertinoIcons.book,
                        selectedValue: selectedSubjectId,
                        items: subjects,
                        displayField: 'name',
                        valueField: 'id',
                        onChanged: (value) async {
                          setState(() => selectedSubjectId = value);
                          await checkMarksGiven();
                        },
                        placeholder: 'Select a subject',
                      ),
                      _buildAppleStyleDropdown(
                        label: "Teacher",
                        icon: CupertinoIcons.person,
                        selectedValue: selectedTeacherId,
                        items: teachers,
                        displayField: 'full_name',
                        valueField: 'id',
                        onChanged: (value) {
                          setState(() => selectedTeacherId = value);
                        },
                        placeholder: 'Select a teacher',
                      ),
                      _buildFormField(
                        controller: _gradeController,
                        label: 'Grade (e.g., 95.5)',
                        icon: CupertinoIcons.number,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a grade';
                          }
                          final grade = double.tryParse(value);
                          if (grade == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      _buildFormField(
                        controller: _remarksController,
                        label: 'Remarks (optional)',
                        icon: CupertinoIcons.text_quote,
                      ),
                      const SizedBox(height: 24),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: isSaving ? null : saveGrade,
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
                                color: CupertinoColors.systemBlue.withOpacity(
                                  0.3,
                                ),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child:
                              isSaving
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
                                    'Save Grade',
                                    textAlign: TextAlign.center,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
