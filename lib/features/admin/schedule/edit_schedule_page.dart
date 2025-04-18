import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class EditSchedulePage extends StatefulWidget {
  final String scheduleId;

  const EditSchedulePage({super.key, required this.scheduleId});

  @override
  State<EditSchedulePage> createState() => _EditSchedulePageState();
}

class _EditSchedulePageState extends State<EditSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();
  final _roomController = TextEditingController();

  // Add new time-related controllers
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  bool _useCustomDuration = false;

  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _error;
  String? _selectedTeacherId;
  String? _selectedDepartmentId;
  String? _selectedClassId;
  String? _selectedSubjectId;

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadScheduleDetails();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _roomController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadScheduleDetails() async {
    try {
      setState(() {
        _isInitialLoading = true;
        _error = null;
      });

      // Load the schedule details
      final scheduleResponse =
          await Supabase.instance.client
              .from('schedule')
              .select('''
            *,
            teachers!inner(id, full_name),
            departments!inner(id, name),
            classes(id, name),
            subjects(id, name, classes(name))
          ''')
              .eq('id', widget.scheduleId)
              .single();

      // Set form values
      _timeController.text = scheduleResponse['time'] ?? '';
      _roomController.text = scheduleResponse['room'] ?? '';
      _selectedTeacherId = scheduleResponse['teacher_id'];
      _selectedDepartmentId = scheduleResponse['department_id'];
      _selectedClassId = scheduleResponse['class_id'];
      _selectedSubjectId = scheduleResponse['subject_id'];

      // Parse the time slot if it has the format "start - end"
      final String timeSlot = scheduleResponse['time'] ?? '';
      if (timeSlot.contains(' - ')) {
        final parts = timeSlot.split(' - ');
        if (parts.length == 2) {
          _startTimeController.text = parts[0];
          _endTimeController.text = parts[1];

          // Check if this is not a default 1-hour slot
          final startTime = _parseTimeString(parts[0]);
          final endTime = _parseTimeString(parts[1]);

          if (startTime != null && endTime != null) {
            // Calculate the difference in minutes
            int startMinutes = startTime.hour * 60 + startTime.minute;
            int endMinutes = endTime.hour * 60 + endTime.minute;

            // Adjust for crossing midnight
            if (endMinutes < startMinutes) {
              endMinutes += 24 * 60; // Add a day in minutes
            }

            final diffMinutes = endMinutes - startMinutes;

            // If it's not exactly 60 minutes, it's a custom duration
            if (diffMinutes != 60) {
              _useCustomDuration = true;
            }
          }
        }
      }

      // Load dropdown data
      await Future.wait([_loadDepartments(), _loadTeachers(), _loadSubjects()]);

      // Load classes after department is set
      if (_selectedDepartmentId != null) {
        await _loadClasses();
      }

      setState(() {
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load schedule details: $e';
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadTeachers() async {
    try {
      final response = await Supabase.instance.client
          .from('teachers')
          .select('id, full_name')
          .order('full_name');

      setState(() {
        _teachers = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load teachers: $e';
      });
    }
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
      setState(() {
        _error = 'Failed to load departments: $e';
      });
    }
  }

  Future<void> _loadClasses() async {
    if (_selectedDepartmentId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('classes')
          .select('id, name')
          .eq('department_id', _selectedDepartmentId)
          .order('name');

      setState(() {
        _classes = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load classes: $e';
      });
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final response = await Supabase.instance.client
          .from('subjects')
          .select('id, name, classes(name)')
          .order('name');

      setState(() {
        _subjects = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load subjects: $e';
      });
    }
  }

  Future<void> _updateSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacherId == null || _selectedDepartmentId == null) {
      setState(() {
        _error = 'Please select all required fields (Teacher and Department)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Ensure the time field is properly set
      String timeValue;
      if (_useCustomDuration) {
        timeValue = '${_startTimeController.text} - ${_endTimeController.text}';
      } else {
        timeValue = _timeController.text;
      }

      final scheduleData = {
        'time': timeValue.trim(),
        'room': _roomController.text.trim(),
        'teacher_id': _selectedTeacherId,
        'department_id': _selectedDepartmentId,
        'class_id': _selectedClassId,
        'subject_id': _selectedSubjectId,
      };

      await Supabase.instance.client
          .from('schedule')
          .update(scheduleData)
          .eq('id', widget.scheduleId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Schedule updated successfully')),
        );
        context.go('/admin/schedule');
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
                                ? _getDisplayText(
                                  items,
                                  selectedValue,
                                  displayField,
                                  valueField,
                                )
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

  String _getDisplayText(
    List<Map<String, dynamic>> items,
    String selectedValue,
    String displayField,
    String valueField,
  ) {
    final item = items.firstWhere(
      (item) => item[valueField] == selectedValue,
      orElse: () => {displayField: 'Unknown'},
    );

    // For subjects, include the class name if available
    if (valueField == 'id' && displayField == 'name' && items == _subjects) {
      final className = item['classes']?['name'];
      if (className != null) {
        return '${item[displayField]} (Class: $className)';
      }
    }

    return item[displayField] ?? 'Unknown';
  }

  Future<void> _showTimePicker() async {
    TimeOfDay initialTime = TimeOfDay.now();

    // If there's already a start time set, parse and use it
    if (_startTimeController.text.isNotEmpty) {
      final parsedTime = _parseTimeString(_startTimeController.text);
      if (parsedTime != null) {
        initialTime = parsedTime;
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00C7BE),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format start time: "1:30 PM"
        final hour = picked.hour;
        final minute = picked.minute;
        final period = hour < 12 ? 'AM' : 'PM';
        final formattedHour =
            hour > 12
                ? hour - 12
                : hour == 0
                ? 12
                : hour;
        final formattedMinute = minute.toString().padLeft(2, '0');

        _startTimeController.text = '$formattedHour:$formattedMinute $period';

        if (!_useCustomDuration) {
          // Default: add 1 hour to end time
          final endHour = (hour + 1) % 24;
          final endPeriod = endHour < 12 ? 'AM' : 'PM';
          final formattedEndHour =
              endHour > 12
                  ? endHour - 12
                  : endHour == 0
                  ? 12
                  : endHour;

          _endTimeController.text =
              '$formattedEndHour:$formattedMinute $endPeriod';

          // Update the combined time display
          _timeController.text =
              '$formattedHour:$formattedMinute $period - $formattedEndHour:$formattedMinute $endPeriod';
        } else {
          // When using custom duration, only update the start time
          // and leave the end time as is, then update the combined display
          _updateCombinedTimeDisplay();
        }
      });
    }
  }

  Future<void> _showEndTimePicker() async {
    TimeOfDay initialTime = TimeOfDay.now();

    // If there's already an end time set, parse and use it
    if (_endTimeController.text.isNotEmpty) {
      final parsedTime = _parseTimeString(_endTimeController.text);
      if (parsedTime != null) {
        initialTime = parsedTime;
      }
    } else if (_startTimeController.text.isNotEmpty) {
      // Otherwise, use start time + 1 hour as the initial value
      final parsedTime = _parseTimeString(_startTimeController.text);
      if (parsedTime != null) {
        final hour = (parsedTime.hour + 1) % 24;
        initialTime = TimeOfDay(hour: hour, minute: parsedTime.minute);
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00C7BE),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format end time: "2:30 PM"
        final hour = picked.hour;
        final minute = picked.minute;
        final period = hour < 12 ? 'AM' : 'PM';
        final formattedHour =
            hour > 12
                ? hour - 12
                : hour == 0
                ? 12
                : hour;
        final formattedMinute = minute.toString().padLeft(2, '0');

        _endTimeController.text = '$formattedHour:$formattedMinute $period';

        // Update the combined time display
        _updateCombinedTimeDisplay();
      });
    }
  }

  void _updateCombinedTimeDisplay() {
    if (_startTimeController.text.isNotEmpty &&
        _endTimeController.text.isNotEmpty) {
      _timeController.text =
          '${_startTimeController.text} - ${_endTimeController.text}';
    }
  }

  void _toggleCustomDuration() {
    setState(() {
      _useCustomDuration = !_useCustomDuration;

      // If turning off custom duration, reset to default 1 hour difference
      if (!_useCustomDuration && _startTimeController.text.isNotEmpty) {
        // Parse the start time and add 1 hour
        final startTime = _parseTimeString(_startTimeController.text);
        if (startTime != null) {
          final endHour = (startTime.hour + 1) % 24;
          final endPeriod = endHour < 12 ? 'AM' : 'PM';
          final formattedEndHour =
              endHour > 12
                  ? endHour - 12
                  : endHour == 0
                  ? 12
                  : endHour;
          final formattedMinute = startTime.minute.toString().padLeft(2, '0');

          _endTimeController.text =
              '$formattedEndHour:$formattedMinute $endPeriod';
          _updateCombinedTimeDisplay();
        }
      }
    });
  }

  TimeOfDay? _parseTimeString(String timeString) {
    // Parsing time strings like "1:30 PM"
    try {
      final parts = timeString.split(' ');
      if (parts.length != 2) return null;

      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;

      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final String period = parts[1];

      // Convert to 24-hour format
      if (period == 'PM' && hour < 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
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
                color: const Color(0xFF00C7BE).withOpacity(0.2),
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
                color: const Color(0xFF00C7BE).withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child:
                _isInitialLoading
                    ? const Center(child: CustomLoader())
                    : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed:
                                        () => context.go('/admin/schedule'),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
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
                                    "Edit Schedule",
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

                              // Time picker field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Custom duration toggle
                                  Row(
                                    children: [
                                      const Text(
                                        "Time Slot",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E1E1E),
                                        ),
                                      ),
                                      const Spacer(),
                                      const Text(
                                        "Custom Duration",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CupertinoSwitch(
                                        value: _useCustomDuration,
                                        onChanged:
                                            (_) => _toggleCustomDuration(),
                                        activeTrackColor: const Color(0xFF00C7BE),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  if (_useCustomDuration) ...[
                                    // Start Time
                                    GestureDetector(
                                      onTap: _showTimePicker,
                                      child: AbsorbPointer(
                                        child: _buildFormField(
                                          controller: _startTimeController,
                                          label: "Start Time",
                                          icon: CupertinoIcons.time,
                                          validator:
                                              (val) =>
                                                  val != null && val.isNotEmpty
                                                      ? null
                                                      : "Please select a start time",
                                        ),
                                      ),
                                    ),

                                    // End Time
                                    GestureDetector(
                                      onTap: _showEndTimePicker,
                                      child: AbsorbPointer(
                                        child: _buildFormField(
                                          controller: _endTimeController,
                                          label: "End Time",
                                          icon: CupertinoIcons.time_solid,
                                          validator:
                                              (val) =>
                                                  val != null && val.isNotEmpty
                                                      ? null
                                                      : "Please select an end time",
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    // Standard 1-hour slot
                                    GestureDetector(
                                      onTap: _showTimePicker,
                                      child: AbsorbPointer(
                                        child: _buildFormField(
                                          controller: _timeController,
                                          label: "Time Slot (1 hour)",
                                          icon: CupertinoIcons.clock,
                                          validator:
                                              (val) =>
                                                  val != null && val.isNotEmpty
                                                      ? null
                                                      : "Please select a time slot",
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // Room field
                              _buildFormField(
                                controller: _roomController,
                                label: "Room Number",
                                icon: CupertinoIcons.house,
                                validator:
                                    (val) =>
                                        val != null && val.isNotEmpty
                                            ? null
                                            : "Please enter a room number",
                              ),

                              // Department dropdown
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
                                      _loadClasses();
                                    }
                                  });
                                },
                                placeholder: 'Select a department',
                              ),

                              // Class dropdown (only shown if department is selected)
                              if (_selectedDepartmentId != null)
                                _buildAppleStyleDropdown(
                                  label: "Class",
                                  icon: CupertinoIcons.group,
                                  selectedValue: _selectedClassId,
                                  items: _classes,
                                  displayField: 'name',
                                  valueField: 'id',
                                  onChanged: (value) {
                                    setState(() => _selectedClassId = value);
                                  },
                                  placeholder: 'Select a class',
                                ),

                              // Teacher dropdown
                              _buildAppleStyleDropdown(
                                label: "Teacher",
                                icon: CupertinoIcons.person_2,
                                selectedValue: _selectedTeacherId,
                                items: _teachers,
                                displayField: 'full_name',
                                valueField: 'id',
                                onChanged: (value) {
                                  setState(() => _selectedTeacherId = value);
                                },
                                placeholder: 'Select a teacher',
                              ),

                              // Subject dropdown
                              _buildAppleStyleDropdown(
                                label: "Subject",
                                icon: CupertinoIcons.book,
                                selectedValue: _selectedSubjectId,
                                items: _subjects,
                                displayField: 'name',
                                valueField: 'id',
                                onChanged: (value) {
                                  setState(() => _selectedSubjectId = value);
                                },
                                placeholder: 'Select a subject',
                              ),

                              if (_error != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemRed
                                        .withOpacity(0.1),
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
                                onPressed: _isLoading ? null : _updateSchedule,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00C7BE),
                                        Color(0xFF00B4AB),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00C7BE,
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
                                                  CupertinoIcons
                                                      .checkmark_circle,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  "Update Schedule",
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
