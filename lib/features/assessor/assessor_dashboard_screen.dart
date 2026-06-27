// lib/features/assessor/assessor_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/app_theme.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/status_badge.dart';

class AssessorDashboardScreen extends ConsumerWidget {
  const AssessorDashboardScreen({super.key});

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
            title: 'SIWES Assessor Portal',
            subtitle: currentUser.name,
            icon: Icons.assignment_ind_rounded,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder(
              stream: fs.studentsForAssessor(currentUser.uid),
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
                      stream:
                          fs.assessorEvalStream(s.id, currentUser.uid),
                      builder: (context, evalSnap) {
                        final hasSubmitted = evalSnap.data != null;
                        final isLocked = evalSnap.data?.isLocked ?? false;

                        final status = !hasSubmitted
                            ? SubmissionStatus.pending
                            : isLocked
                                ? SubmissionStatus.submitted
                                : SubmissionStatus.unlocked;

                        final canSubmit = !hasSubmitted || !isLocked;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    AppTheme.assessorColor.withValues(alpha: 0.1),
                                child: Text(
                                  s.name.isNotEmpty
                                      ? s.name[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.assessorColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name,
                                        style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                    Text('${s.matricNo} • ${s.department}',
                                        style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: Colors.grey[500])),
                                    const SizedBox(height: 6),
                                    StatusBadge(status: status),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: canSubmit
                                    ? () => context.go(
                                        '/assessor/score/${s.id}')
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canSubmit
                                      ? AppTheme.assessorColor
                                      : Colors.grey[300],
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  textStyle: GoogleFonts.outfit(fontSize: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(hasSubmitted ? 'Edit' : 'Score'),
                              ),
                            ],
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
