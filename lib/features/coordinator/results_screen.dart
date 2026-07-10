// lib/features/coordinator/results_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/models/evaluation.dart';
import '../../core/app_theme.dart';
import '../../core/scoring_service.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/status_badge.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          const AppHeader(
            title: 'Overall Results',
            subtitle: 'Final SIWES grading sheet',
            icon: Icons.analytics_rounded,
          ),
          Expanded(
            child: StreamBuilder(
              stream: fs.studentsStream(),
              builder: (context, studentSnap) {
                return StreamBuilder(
                  stream: fs.allResultsStream(),
                  builder: (context, resultSnap) {
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
                    if (resultSnap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text('Error loading results: ${resultSnap.error}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(color: Colors.red)),
                        ),
                      );
                    }
                    if ((studentSnap.connectionState == ConnectionState.waiting && !studentSnap.hasData) || 
                        (resultSnap.connectionState == ConnectionState.waiting && !resultSnap.hasData)) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final students = studentSnap.data ?? [];
                    final results = {
                      for (final r in (resultSnap.data ?? [])) r.studentId: r
                    };

                    if (students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.analytics_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('No students registered yet.',
                                style: GoogleFonts.outfit(color: Colors.grey[500])),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: students.length,
                      itemBuilder: (context, i) {
                        final s = students[i];
                        final result = results[s.id];
                        return _ResultTile(
                          studentName: s.name,
                          matricNo: s.matricNo,
                          result: result,
                          onFinalize: result?.finalScore != null &&
                                  !(result?.isFinalized ?? false)
                              ? () => _confirmFinalize(context, ref, s.id, s.name)
                              : null,
                          onUnlock: (result?.isFinalized ?? false)
                              ? () => _confirmUnlock(context, ref, s.id, s.name)
                              : null,
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

  void _confirmFinalize(
      BuildContext context, WidgetRef ref, String studentId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalize Result'),
        content: Text(
            'Finalize result for $name? This will lock the scores permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(firestoreServiceProvider).finalizeResult(studentId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('$name result finalized!'),
                      backgroundColor: AppTheme.secondary),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );
  }

  void _confirmUnlock(
      BuildContext context, WidgetRef ref, String studentId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unlock Submission'),
        content: Text(
            'Unlock submission for $name? The supervisor can re-enter scores.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(firestoreServiceProvider).unlockResult(studentId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('$name submission unlocked.'),
                      backgroundColor: AppTheme.warning),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String studentName;
  final String matricNo;
  final StudentResult? result;
  final VoidCallback? onFinalize;
  final VoidCallback? onUnlock;

  const _ResultTile({
    required this.studentName,
    required this.matricNo,
    required this.result,
    this.onFinalize,
    this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final supScore = result?.supervisorScore;
    final assAvg = result?.assessorAverage;
    final finalScore = result?.finalScore;
    final isFinalized = result?.isFinalized ?? false;

    final grade = result?.grade ?? (finalScore != null
        ? ScoringService.gradeFromScore(finalScore)
        : null);

    final statusBadge = isFinalized
        ? SubmissionStatus.finalized
        : finalScore != null
            ? SubmissionStatus.submitted
            : SubmissionStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName,
                        style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(matricNo,
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
              ),
              StatusBadge(status: statusBadge),
            ],
          ),

          const Divider(height: 20),

          // Score row
          Row(
            children: [
              _ScorePill(
                  label: 'Supervisor', value: supScore, max: 60, color: AppTheme.supervisorColor),
              const SizedBox(width: 8),
              _ScorePill(
                  label: 'Assessor Avg', value: assAvg, max: 40, color: AppTheme.assessorColor),
              const SizedBox(width: 8),
              _ScorePill(
                  label: 'Total', value: finalScore, max: 100, color: AppTheme.coordinatorColor),
              const SizedBox(width: 8),
              _GradePill(grade: grade),
            ],
          ),

          if (onFinalize != null || onUnlock != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onFinalize != null)
                  ElevatedButton.icon(
                    onPressed: onFinalize,
                    icon: const Icon(Icons.lock, size: 16),
                    label: const Text('Finalize'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      textStyle: GoogleFonts.outfit(fontSize: 13),
                    ),
                  ),
                if (onUnlock != null)
                  OutlinedButton.icon(
                    onPressed: onUnlock,
                    icon: const Icon(Icons.lock_open, size: 16),
                    label: const Text('Unlock'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warning,
                      side: const BorderSide(color: AppTheme.warning),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      textStyle: GoogleFonts.outfit(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GradePill extends StatelessWidget {
  final String? grade;

  const _GradePill({required this.grade});

  @override
  Widget build(BuildContext context) {
    final color = grade != null ? _gradeColor(grade!) : Colors.grey;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              grade ?? '--',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              'Grade',
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A': return AppTheme.secondary;
      case 'B': return AppTheme.primary;
      case 'C': return AppTheme.warning;
      case 'D': return Colors.orange;
      default: return AppTheme.error;
    }
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final double? value;
  final double max;
  final Color color;

  const _ScorePill({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value != null ? value!.toStringAsFixed(1) : '--',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
