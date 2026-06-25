// lib/features/coordinator/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/firestore_service.dart';
import '../../core/app_theme.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/score_card.dart';

class CoordinatorDashboardScreen extends ConsumerWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final fs = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          AppHeader(
            title: 'SIWES Coordinator Portal',
            subtitle: currentUser?.name ?? 'Coordinator',
            icon: Icons.admin_panel_settings_rounded,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          ),

          Expanded(
            child: StreamBuilder(
              stream: fs.studentsStream(),
              builder: (context, studentSnap) {
                return StreamBuilder(
                  stream: fs.allResultsStream(),
                  builder: (context, resultSnap) {
                    final students = studentSnap.data ?? [];
                    final results = resultSnap.data ?? [];

                    final totalStudents = students.length;
                    final finalized = results.where((r) => r.isFinalized).length;
                    final supervisorDone = results.where((r) => r.supervisorScore != null).length;
                    final pending = totalStudents - supervisorDone;

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Stats grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                          children: [
                            StatCard(
                              title: 'Total Students',
                              value: '$totalStudents',
                              icon: Icons.people_rounded,
                              iconColor: AppTheme.coordinatorColor,
                            ),
                            StatCard(
                              title: 'Finalized',
                              value: '$finalized',
                              icon: Icons.check_circle_rounded,
                              iconColor: AppTheme.secondary,
                            ),
                            StatCard(
                              title: 'Supervisor Done',
                              value: '$supervisorDone',
                              icon: Icons.supervisor_account_rounded,
                              iconColor: AppTheme.supervisorColor,
                            ),
                            StatCard(
                              title: 'Pending',
                              value: '$pending',
                              icon: Icons.pending_actions_rounded,
                              color: AppTheme.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        Text('Quick Actions',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                            )),
                        const SizedBox(height: 12),

                        // Action cards
                        _ActionCard(
                          icon: Icons.person_add_rounded,
                          title: 'Register Student',
                          subtitle: 'Add new IT student record',
                          color: AppTheme.coordinatorColor,
                          onTap: () => context.go('/coordinator/register-student'),
                        ),
                        const SizedBox(height: 12),
                        _ActionCard(
                          icon: Icons.manage_accounts_rounded,
                          title: 'Register Supervisor / Assessor',
                          subtitle: 'Create user accounts by role',
                          color: AppTheme.supervisorColor,
                          onTap: () => context.go('/coordinator/register-user'),
                        ),
                        const SizedBox(height: 12),

                        // Recent students
                        if (students.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Recent Students',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A2E),
                              )),
                          const SizedBox(height: 12),
                          ...students.take(5).map((s) => _StudentTile(
                                student: s,
                                onAssignSupervisor: () => context.go(
                                    '/coordinator/assign-supervisor/${s.id}'),
                                onAssignAssessors: () => context.go(
                                    '/coordinator/assign-assessors/${s.id}'),
                              )),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authServiceProvider).signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.outfit(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final dynamic student;
  final VoidCallback onAssignSupervisor;
  final VoidCallback onAssignAssessors;

  const _StudentTile({
    required this.student,
    required this.onAssignSupervisor,
    required this.onAssignAssessors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student.name,
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          Text('${student.matricNo} • ${student.department}',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAssignSupervisor,
                  icon: const Icon(Icons.supervisor_account, size: 16),
                  label: Text(student.supervisorId != null ? 'Supervisor ✓' : 'Assign Supervisor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.supervisorColor,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.outfit(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAssignAssessors,
                  icon: const Icon(Icons.group, size: 16),
                  label: Text('Assessors (${student.assessorIds.length}/10)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.assessorColor,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.outfit(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
