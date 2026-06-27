// lib/features/coordinator/assign_supervisor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/models/app_user.dart';
import '../../core/app_theme.dart';

class AssignSupervisorScreen extends ConsumerStatefulWidget {
  final String studentId;
  const AssignSupervisorScreen({super.key, required this.studentId});

  @override
  ConsumerState<AssignSupervisorScreen> createState() =>
      _AssignSupervisorScreenState();
}

class _AssignSupervisorScreenState
    extends ConsumerState<AssignSupervisorScreen> {
  String? _selectedSupervisorId;
  bool _loading = false;

  Future<void> _assign() async {
    if (_selectedSupervisorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supervisor.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .assignSupervisor(widget.studentId, _selectedSupervisorId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supervisor assigned!'),
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
        title: const Text('Assign Supervisor'),
        backgroundColor: AppTheme.supervisorColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<AppUser>>(
        future: ref
            .read(firestoreServiceProvider)
            .getUsersByRole(UserRole.supervisor),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final supervisors = snap.data!;
          if (supervisors.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.supervisor_account,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No supervisors registered yet.',
                      style: GoogleFonts.outfit(color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/coordinator/register-user'),
                    child: const Text('Register a Supervisor'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: supervisors.length,
                  itemBuilder: (context, i) {
                    final sup = supervisors[i];
                    final selected = _selectedSupervisorId == sup.uid;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.supervisorColor.withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppTheme.supervisorColor
                              : Colors.grey[200]!,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: RadioListTile<String>(
                        value: sup.uid,
                        groupValue: _selectedSupervisorId,
                        onChanged: (v) =>
                            setState(() => _selectedSupervisorId = v),
                        activeColor: AppTheme.supervisorColor,
                        title: Text(sup.name,
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(sup.email,
                            style:
                                GoogleFonts.outfit(color: Colors.grey[500])),
                        secondary: CircleAvatar(
                          backgroundColor:
                              AppTheme.supervisorColor.withValues(alpha: 0.1),
                          child: Text(
                            sup.name.isNotEmpty
                                ? sup.name[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.outfit(
                              color: AppTheme.supervisorColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.supervisorColor),
                    onPressed: _loading ? null : _assign,
                    child: _loading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)
                        : const Text('Assign Supervisor'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
