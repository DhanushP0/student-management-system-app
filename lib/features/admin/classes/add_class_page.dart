import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddClassPage extends StatefulWidget {
  const AddClassPage({super.key});

  @override
  State<AddClassPage> createState() => _AddClassPageState();
}

class _AddClassPageState extends State<AddClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedDepartmentId;
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = false;
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
      setState(() {
        _error = 'Failed to load departments: $e';
      });
    }
  }

  Future<void> _addClass() async {
    if (!_formKey.currentState!.validate() || _selectedDepartmentId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First check if class name already exists
      final existingClass = await Supabase.instance.client
          .from('teachers')
          .select('id')
          .eq('class', _nameController.text.trim())
          .maybeSingle();

      if (existingClass != null) {
        setState(() {
          _error = 'A class with this name already exists';
          _isLoading = false;
        });
        return;
      }

      // Create a new class by adding it to a teacher
      await Supabase.instance.client.from('teachers').update({
        'class': _nameController.text.trim(),
        'department_id': _selectedDepartmentId,
      }).eq('class', _nameController.text.trim());

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Class added successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to add class: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                            onPressed: () => context.go('/admin/classes'),
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
                            "Add Class",
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
                      _buildFormFields(),
                      if (_error != null) _buildErrorMessage(),
                      const SizedBox(height: 30),
                      _buildAddButton(),
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

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildInputField(
          controller: _nameController,
          label: "Class Name",
          icon: CupertinoIcons.book,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter class name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDepartmentDropdown(),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
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
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
              prefixIcon: Icon(icon, color: CupertinoColors.systemGrey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return ClipRRect(
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
            decoration: const InputDecoration(
              labelText: "Department",
              labelStyle: TextStyle(color: Color(0xFF8E8E93)),
              prefixIcon: Icon(
                CupertinoIcons.building_2_fill,
                color: CupertinoColors.systemGrey,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            items: _departments.map((department) {
              return DropdownMenuItem<String>(
                value: department['id'].toString(),
                child: Text(department['name']),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedDepartmentId = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a department';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }

  Widget _buildAddButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _isLoading ? null : _addClass,
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
              ? const CupertinoActivityIndicator(color: Colors.white)
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.plus_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Add Class",
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
    );
  }
} 