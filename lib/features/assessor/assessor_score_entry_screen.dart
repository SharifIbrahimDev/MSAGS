// lib/features/assessor/assessor_score_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/models/evaluation.dart';
import '../../core/scoring_service.dart';
import '../../core/app_theme.dart';
import '../../shared/utils/error_utils.dart';

class AssessorScoreEntryScreen extends ConsumerStatefulWidget {
  final String studentId;
  const AssessorScoreEntryScreen({super.key, required this.studentId});

  @override
  ConsumerState<AssessorScoreEntryScreen> createState() =>
      _AssessorScoreEntryScreenState();
}

class _AssessorScoreEntryScreenState
    extends ConsumerState<AssessorScoreEntryScreen> {
  double _oral = 0;
  double _attitudinal = 0;
  double _display = 0;
  bool _submitting = false;
  bool _prepopulated = false;

  double get _preview => ScoringService.assessorScore(
        oral: _oral,
        attitude: _attitudinal,
        dressing: _display,
      );

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      if (currentUser == null) throw Exception('Not logged in');

      final eval = AssessorEvaluation(
        studentId: widget.studentId,
        assessorId: currentUser.uid,
        oral: _oral,
        attitudinal: _attitudinal,
        display: _display,
        submittedAt: DateTime.now(),
        isLocked: true,
      );

      await ref.read(firestoreServiceProvider).submitAssessorEval(eval);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Scores submitted! Contribution: ${_preview.toStringAsFixed(1)}/40'),
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Assessment Scores'),
        backgroundColor: AppTheme.assessorColor,
        foregroundColor: Colors.white,
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
              stream: ref
                  .watch(firestoreServiceProvider)
                  .assessorEvalStream(widget.studentId, currentUser.uid),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(getFriendlyError(snap.error),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: AppTheme.error)),
                    ),
                  );
                }
                // Pre-populate with existing scores
                if (snap.hasData && snap.data != null && !_prepopulated) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _oral = snap.data!.oral;
                        _attitudinal = snap.data!.attitudinal;
                        _display = snap.data!.display;
                        _prepopulated = true;
                      });
                    }
                  });
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Confidentiality notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.visibility_off_outlined,
                                color: Colors.blue[600], size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your scores are confidential. Supervisor cannot see individual assessor scores.',
                                style: GoogleFonts.outfit(
                                    fontSize: 13, color: Colors.blue[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Preview card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF), // indigo-50
                          border: Border.all(color: const Color(0xFFC7D2FE)), // indigo-200
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Assessor Score',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF111827))),
                                Text(
                                  '${_preview.toStringAsFixed(0)} / 40',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF4F46E5), // indigo-600
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '40% of final evaluation',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: const Color(0xFF4B5563)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      _AssessorSlider(
                        label: 'Oral Presentation',
                        value: _oral,
                        max: 15,
                        color: AppTheme.assessorColor,
                        onChanged: (v) => setState(() => _oral = v),
                      ),
                      const SizedBox(height: 16),
                      _AssessorSlider(
                        label: 'Attitude & Comportment',
                        value: _attitudinal,
                        max: 15,
                        color: const Color(0xFF2E7D32),
                        onChanged: (v) => setState(() => _attitudinal = v),
                      ),
                      const SizedBox(height: 16),
                      _AssessorSlider(
                        label: 'Dressing & Appearance',
                        value: _display,
                        max: 10,
                        color: const Color(0xFF388E3C),
                        onChanged: (v) => setState(() => _display = v),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.assessorColor),
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded),
                          label: const Text('Submit Assessment'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _AssessorSlider extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  const _AssessorSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.15),
              overlayColor: color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: max,
              divisions: max.toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
