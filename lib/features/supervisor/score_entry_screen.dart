// lib/features/supervisor/score_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/models/evaluation.dart';
import '../../core/scoring_service.dart';
import '../../core/app_theme.dart';

class SupervisorScoreEntryScreen extends ConsumerStatefulWidget {
  final String studentId;
  const SupervisorScoreEntryScreen({super.key, required this.studentId});

  @override
  ConsumerState<SupervisorScoreEntryScreen> createState() =>
      _SupervisorScoreEntryScreenState();
}

class _SupervisorScoreEntryScreenState
    extends ConsumerState<SupervisorScoreEntryScreen> {
  double _logbook = 0;
  double _technicalReport = 0;
  double _industrialReport = 0;
  bool _loading = false;
  bool _submitting = false;

  double get _preview =>
      ScoringService.supervisorScore(
        logbook: _logbook,
        technicalReport: _technicalReport,
        industrialReport: _industrialReport,
      );

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      if (currentUser == null) throw Exception('Not logged in');

      final eval = SupervisorEvaluation(
        studentId: widget.studentId,
        supervisorId: currentUser.uid,
        logbook: _logbook,
        technicalReport: _technicalReport,
        industrialReport: _industrialReport,
        submittedAt: DateTime.now(),
        isLocked: true,
      );

      await ref.read(firestoreServiceProvider).submitSupervisorEval(eval);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Scores submitted! Contribution: ${_preview.toStringAsFixed(1)}/60'),
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pre-load existing scores
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Supervisor Scores'),
        backgroundColor: AppTheme.supervisorColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: ref.watch(firestoreServiceProvider).supervisorEvalStream(widget.studentId),
        builder: (context, snap) {
          // Pre-populate if editing
          if (snap.hasData && snap.data != null && !_loading) {
            final existing = snap.data!;
            if (_logbook == 0 && _technicalReport == 0 && _industrialReport == 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _logbook = existing.logbook;
                  _technicalReport = existing.technicalReport;
                  _industrialReport = existing.industrialReport;
                  _loading = true;
                });
              });
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                          Text('Total Supervisor Score',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827))), // gray-900
                          Text(
                            '${_preview.toStringAsFixed(0)} / 60',
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
                        '60% of final evaluation',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF4B5563)), // gray-600
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Score sliders
                _ScoreSlider(
                  label: 'Logbook',
                  value: _logbook,
                  max: 20,
                  color: AppTheme.supervisorColor,
                  onChanged: (v) => setState(() => _logbook = v),
                ),
                const SizedBox(height: 20),
                _ScoreSlider(
                  label: 'Technical Report',
                  value: _technicalReport,
                  max: 20,
                  color: const Color(0xFF0D47A1),
                  onChanged: (v) => setState(() => _technicalReport = v),
                ),
                const SizedBox(height: 20),
                _ScoreSlider(
                  label: 'Industrial Report',
                  value: _industrialReport,
                  max: 20,
                  color: const Color(0xFF1565C0),
                  onChanged: (v) => setState(() => _industrialReport = v),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.supervisorColor),
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    label: const Text('Submit Scores'),
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

class _ScoreSlider extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  const _ScoreSlider({
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
