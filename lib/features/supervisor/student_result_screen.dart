// lib/features/supervisor/student_result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/app_theme.dart';
import '../../core/scoring_service.dart';
import '../../shared/widgets/score_card.dart';

class SupervisorStudentResultScreen extends ConsumerWidget {
  final String studentId;
  const SupervisorStudentResultScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Result'),
        backgroundColor: AppTheme.supervisorColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: fs.supervisorEvalStream(studentId),
        builder: (context, evalSnap) {
          return StreamBuilder(
            stream: fs.resultStream(studentId),
            builder: (context, resultSnap) {
              final eval = evalSnap.data;
              final result = resultSnap.data;

              if (!evalSnap.hasData && !resultSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final finalScore = result?.finalScore;
              final grade = finalScore != null
                  ? ScoringService.gradeFromScore(finalScore)
                  : null;
              final remark = grade != null
                  ? ScoringService.remarkFromGrade(grade)
                  : null;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Final result card
                    if (finalScore != null && grade != null) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _gradeColor(grade),
                              _gradeColor(grade).withValues(alpha: 0.7)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _gradeColor(grade).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text('Final Score',
                                style: GoogleFonts.outfit(
                                    fontSize: 14, color: Colors.white70)),
                            Text(
                              finalScore.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Grade: $grade',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '($remark)',
                                  style: GoogleFonts.outfit(
                                      fontSize: 16, color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text('Your Scores (60%)',
                        style: GoogleFonts.outfit(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),

                    if (eval != null) ...[
                      ScoreCard(
                        label: 'Logbook',
                        score: eval.logbook,
                        maxScore: 20,
                        color: AppTheme.supervisorColor,
                      ),
                      const SizedBox(height: 10),
                      ScoreCard(
                        label: 'Technical Report',
                        score: eval.technicalReport,
                        maxScore: 20,
                        color: const Color(0xFF0D47A1),
                      ),
                      const SizedBox(height: 10),
                      ScoreCard(
                        label: 'Industrial Report',
                        score: eval.industrialReport,
                        maxScore: 20,
                        color: const Color(0xFF1565C0),
                      ),
                      const SizedBox(height: 10),
                      ScoreCard(
                        label: 'Your Total Contribution',
                        score: eval.scaledScore,
                        maxScore: 60,
                        color: AppTheme.supervisorColor,
                      ),
                    ] else ...[
                      const Center(child: Text('No scores submitted yet.')),
                    ],

                    const SizedBox(height: 24),
                    Text('Assessors Average (40%)',
                        style: GoogleFonts.outfit(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ScoreCard(
                      label: 'Assessor Average Score',
                      score: result?.assessorAverage,
                      maxScore: 40,
                      color: AppTheme.assessorColor,
                    ),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Individual assessor scores are confidential.',
                              style: GoogleFonts.outfit(
                                  fontSize: 13, color: Colors.amber[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
