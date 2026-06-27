// lib/features/coordinator/register_student_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/models/student.dart';
import '../../core/app_theme.dart';

class RegisterStudentScreen extends ConsumerStatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  ConsumerState<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends ConsumerState<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _matricCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _matricCtrl.dispose();
    _deptCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final fs = ref.read(firestoreServiceProvider);
      await fs.createStudent(Student(
        id: '',
        name: _nameCtrl.text.trim(),
        matricNo: _matricCtrl.text.trim(),
        department: _deptCtrl.text.trim(),
        company: _companyCtrl.text.trim(),
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
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
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
              _buildField(
                id: 'student_name',
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) => (v?.isEmpty ?? true) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                id: 'student_matric',
                controller: _matricCtrl,
                label: 'Matric Number',
                icon: Icons.badge_outlined,
                validator: (v) => (v?.isEmpty ?? true) ? 'Matric number is required' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                id: 'student_dept',
                controller: _deptCtrl,
                label: 'Department',
                icon: Icons.account_balance_outlined,
                validator: (v) => (v?.isEmpty ?? true) ? 'Department is required' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                id: 'student_company',
                controller: _companyCtrl,
                label: 'Company / Placement',
                icon: Icons.business_outlined,
                validator: (v) => (v?.isEmpty ?? true) ? 'Company is required' : null,
              ),
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

  Widget _buildField({
    required String id,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      key: ValueKey(id),
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }
}
