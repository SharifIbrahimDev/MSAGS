// lib/features/supervisor/supervisor_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/app_theme.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/status_badge.dart';

class SupervisorDashboardScreen extends ConsumerWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final fs = ref.watch(firestoreServiceProvider);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          AppHeader(
            title: 'Supervisor — MSAGS',
            subtitle: 'SIWES Evaluation | ${currentUser.name}',
            gradientStart: AppTheme.supervisorColor,
            gradientEnd: const Color(0xFF0D47A1),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder(
              stream: fs.studentsForSupervisor(currentUser.uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final students = snap.data!;

                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No students assigned yet.',
                            style:
                                GoogleFonts.outfit(color: Colors.grey[500])),
                        const SizedBox(height: 4),
                        Text('The coordinator will assign students to you.',
                            style: GoogleFonts.outfit(
                                fontSize: 13, color: Colors.grey[400])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, i) {
                    final s = students[i];
                    return StreamBuilder(
                      stream: fs.supervisorEvalStream(s.id),
                      builder: (context, evalSnap) {
                        final hasSubmitted = evalSnap.data != null;
                        final isLocked = evalSnap.data?.isLocked ?? false;
                        final status = !hasSubmitted
                            ? SubmissionStatus.pending
                            : isLocked
                                ? SubmissionStatus.submitted
                                : SubmissionStatus.unlocked;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  AppTheme.supervisorColor.withOpacity(0.1),
                              child: Text(
                                s.name.isNotEmpty
                                    ? s.name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.supervisorColor,
                                ),
                              ),
                            ),
                            title: Text(s.name,
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${s.matricNo} • ${s.department}',
                                style: GoogleFonts.outfit(
                                    fontSize: 12, color: Colors.grey[500])),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                StatusBadge(status: status),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: (isLocked && hasSubmitted)
                                          ? null
                                          : () => context.go(
                                              '/supervisor/score/${s.id}'),
                                      child: Text(
                                          hasSubmitted ? 'Edit' : 'Score',
                                          style: GoogleFonts.outfit(
                                              fontSize: 12)),
                                    ),
                                    if (hasSubmitted)
                                      TextButton(
                                        onPressed: () => context.go(
                                            '/supervisor/result/${s.id}'),
                                        child: Text('View',
                                            style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color:
                                                    AppTheme.supervisorColor)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
}
