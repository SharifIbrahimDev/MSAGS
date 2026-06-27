// lib/features/coordinator/assign_assessors_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/models/app_user.dart';
import '../../core/app_theme.dart';

class AssignAssessorsScreen extends ConsumerStatefulWidget {
  final String studentId;
  const AssignAssessorsScreen({super.key, required this.studentId});

  @override
  ConsumerState<AssignAssessorsScreen> createState() =>
      _AssignAssessorsScreenState();
}

class _AssignAssessorsScreenState
    extends ConsumerState<AssignAssessorsScreen> {
  final Set<String> _selectedIds = {};
  bool _loading = false;

  Future<void> _assign() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one assessor.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .assignAssessors(widget.studentId, _selectedIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIds.length} assessor(s) assigned!'),
            backgroundColor: AppTheme.secondary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.error),
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
        title: const Text('Assign Assessors'),
        backgroundColor: AppTheme.assessorColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<AppUser>>(
        future: ref
            .read(firestoreServiceProvider)
            .getUsersByRole(UserRole.assessor),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final assessors = snap.data!;
          if (assessors.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No assessors registered yet.',
                      style: GoogleFonts.outfit(color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/coordinator/register-user'),
                    child: const Text('Register an Assessor'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Counter banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: AppTheme.assessorColor.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppTheme.assessorColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedIds.length} / 10 assessors selected',
                        style: GoogleFonts.outfit(
                          color: AppTheme.assessorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_selectedIds.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _selectedIds.clear()),
                        child: Text('Clear all',
                            style: GoogleFonts.outfit(
                                color: AppTheme.error, fontSize: 13)),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: assessors.length,
                  itemBuilder: (context, i) {
                    final a = assessors[i];
                    final selected = _selectedIds.contains(a.uid);
                    final maxReached = _selectedIds.length >= 10 && !selected;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.assessorColor.withValues(alpha: 0.08)
                            : maxReached
                                ? Colors.grey[50]
                                : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppTheme.assessorColor
                              : Colors.grey[200]!,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: selected,
                        onChanged: maxReached
                            ? null
                            : (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedIds.add(a.uid);
                                  } else {
                                    _selectedIds.remove(a.uid);
                                  }
                                });
                              },
                        activeColor: AppTheme.assessorColor,
                        title: Text(a.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: maxReached ? Colors.grey[400] : null,
                            )),
                        subtitle: Text(a.email,
                            style: GoogleFonts.outfit(
                                color: maxReached
                                    ? Colors.grey[300]
                                    : Colors.grey[500])),
                        secondary: CircleAvatar(
                          backgroundColor: selected
                              ? AppTheme.assessorColor.withValues(alpha: 0.2)
                              : Colors.grey[100],
                          child: Text(
                            a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                            style: GoogleFonts.outfit(
                              color: selected
                                  ? AppTheme.assessorColor
                                  : Colors.grey[400],
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
                        backgroundColor: AppTheme.assessorColor),
                    onPressed: _loading ? null : _assign,
                    child: _loading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)
                        : Text('Assign ${_selectedIds.length} Assessor(s)'),
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
