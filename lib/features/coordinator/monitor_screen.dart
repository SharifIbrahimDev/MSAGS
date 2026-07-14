// lib/features/coordinator/monitor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/models/student.dart';
import '../../core/models/evaluation.dart';
import '../../core/app_theme.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/status_badge.dart';

class MonitorScreen extends ConsumerWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          const AppHeader(
            title: 'Monitor Assessment',
            subtitle: 'Track assessment progress for all students',
            icon: Icons.monitor_heart_rounded,
          ),
          Expanded(
            child: StreamBuilder(
              stream: fs.studentsStream(),
              builder: (context, studentSnap) {
                if (studentSnap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Error loading students: ${studentSnap.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.red)),
                    ),
                  );
                }
                if (studentSnap.connectionState == ConnectionState.waiting && !studentSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final students = studentSnap.data ?? [];
                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No students registered yet.',
                            style: GoogleFonts.outfit(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return StreamBuilder(
                  stream: fs.allResultsStream(),
                  builder: (context, resultSnap) {
                    if (resultSnap.hasError) {
                      return Center(
                        child: Text('Error loading results: ${resultSnap.error}',
                            style: GoogleFonts.outfit(color: Colors.red)),
                      );
                    }
                    if (resultSnap.connectionState == ConnectionState.waiting && !resultSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final results = {
                      for (final r in (resultSnap.data ?? [])) r.studentId: r
                    };

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: students.length,
                      itemBuilder: (context, i) {
                        final s = students[i];
                        final result = results[s.id];
                        return _MonitorTile(student: s, result: result);
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

class _MonitorTile extends StatelessWidget {
  final Student student;
  final EvaluationResult? result;

  const _MonitorTile({required this.student, required this.result});

  @override
  Widget build(BuildContext context) {
    final supervisorSubmitted = result?.supervisorScore != null;
    final assessorsTotal = result?.assessorCount ?? student.assessorIds.length;
    final assessorsDone = result?.assessorsSubmitted ?? 0;

    final supStatus = student.supervisorId == null
        ? SubmissionStatus.notAssigned
        : supervisorSubmitted
            ? SubmissionStatus.submitted
            : SubmissionStatus.pending;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.coordinatorColor.withValues(alpha: 0.1),
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                  style: GoogleFonts.outfit(
                    color: AppTheme.coordinatorColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name,
                        style: GoogleFonts.outfit(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('${student.matricNo} • ${student.department}',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              // Supervisor status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Supervisor (60%)',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    StatusBadge(status: supStatus),
                  ],
                ),
              ),
              // Assessors progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assessors (40%)',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$assessorsDone / $assessorsTotal',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: assessorsDone == assessorsTotal && assessorsTotal > 0
                                ? AppTheme.secondary
                                : AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: assessorsTotal > 0
                                  ? assessorsDone / assessorsTotal
                                  : 0,
                              minHeight: 6,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                assessorsDone == assessorsTotal && assessorsTotal > 0
                                    ? AppTheme.secondary
                                    : AppTheme.warning,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
