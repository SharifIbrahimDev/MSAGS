// lib/features/coordinator/register_student_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/models/student.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../../shared/utils/error_utils.dart';

class RegisterStudentScreen extends ConsumerStatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  ConsumerState<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends ConsumerState<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _matricCtrl = TextEditingController();
  final _customDeptCtrl = TextEditingController();
  final _customCompanyCtrl = TextEditingController();

  String? _selectedDept;
  String? _selectedCompany;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _matricCtrl.dispose();
    _customDeptCtrl.dispose();
    _customCompanyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final department = _selectedDept == 'Other'
        ? _customDeptCtrl.text.trim()
        : (_selectedDept ?? '');

    final company = _selectedCompany == 'Other'
        ? _customCompanyCtrl.text.trim()
        : (_selectedCompany ?? '');

    setState(() => _loading = true);
    try {
      final fs = ref.read(firestoreServiceProvider);
      await fs.createStudent(Student(
        id: '',
        name: _nameCtrl.text.trim(),
        matricNo: _matricCtrl.text.trim(),
        department: department,
        company: company,
        createdAt: DateTime.now(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameCtrl.text.trim()} registered successfully!'),
            backgroundColor: AppTheme.secondary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyError(e)), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Student'),
        backgroundColor: AppTheme.coordinatorColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full Name field restricted to strings/letters only
              _buildTextField(
                id: 'student_name',
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.-]')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (RegExp(r'[0-9]').hasMatch(v)) return 'Name cannot contain numbers';
                  if (!RegExp(r'^[a-zA-Z\s.-]+$').hasMatch(v.trim())) {
                    return 'Name must contain only alphabetic letters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Matric Number field formatted for alphanumeric matric codes
              _buildTextField(
                id: 'student_matric',
                controller: _matricCtrl,
                label: 'Matric Number',
                icon: Icons.badge_outlined,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9/\-]')),
                ],
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Matric number is required' : null,
              ),
              const SizedBox(height: 16),
              
              // Department Dropdown
              DropdownButtonFormField<String>(
                key: const ValueKey('student_dept_dropdown'),
                value: _selectedDept,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                items: AppConstants.departments.map((dept) {
                  return DropdownMenuItem<String>(
                    value: dept,
                    child: Text(dept),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedDept = val;
                  });
                },
                validator: (v) => (v == null || v.isEmpty) ? 'Please select a department' : null,
              ),

              if (_selectedDept == 'Other') ...[
                const SizedBox(height: 12),
                _buildTextField(
                  id: 'custom_student_dept',
                  controller: _customDeptCtrl,
                  label: 'Specify Department',
                  icon: Icons.edit_note_outlined,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.-]')),
                  ],
                  validator: (v) {
                    if (_selectedDept == 'Other') {
                      if (v == null || v.trim().isEmpty) return 'Please specify department';
                      if (RegExp(r'[0-9]').hasMatch(v)) return 'Department cannot contain numbers';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Place of Attachment Dropdown
              DropdownButtonFormField<String>(
                key: const ValueKey('student_company_dropdown'),
                value: _selectedCompany,
                decoration: const InputDecoration(
                  labelText: 'Place of Attachment',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                items: AppConstants.placesOfAttachment.map((place) {
                  return DropdownMenuItem<String>(
                    value: place,
                    child: Text(place),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCompany = val;
                  });
                },
                validator: (v) => (v == null || v.isEmpty) ? 'Please select place of attachment' : null,
              ),

              if (_selectedCompany == 'Other') ...[
                const SizedBox(height: 12),
                _buildTextField(
                  id: 'custom_student_company',
                  controller: _customCompanyCtrl,
                  label: 'Specify Place of Attachment',
                  icon: Icons.edit_location_alt_outlined,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.&,\-]')),
                  ],
                  validator: (v) {
                    if (_selectedCompany == 'Other' && (v?.trim().isEmpty ?? true)) {
                      return 'Please specify place of attachment';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coordinatorColor,
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)
                      : const Text('Register Student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String id,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      key: ValueKey(id),
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }
}
