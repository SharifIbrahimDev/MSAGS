// lib/features/supervisor/score_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/models/evaluation.dart';
import '../../core/scoring_service.dart';
import '../../core/app_theme.dart';
import '../../shared/utils/error_utils.dart';

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
  bool _prepopulated = false;
  bool _submitting = false;
  bool _isLocked = false; // NEW: tracks whether the existing submission is locked

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
          SnackBar(content: Text(getFriendlyError(e)), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Supervisor Scores'),
        backgroundColor: AppTheme.supervisorColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: ref.watch(firestoreServiceProvider).supervisorEvalStream(widget.studentId),
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
          // Pre-populate if editing, and pick up the lock state
          if (snap.hasData && snap.data != null && !_prepopulated) {
            final existing = snap.data!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _logbook = existing.logbook;
                  _technicalReport = existing.technicalReport;
                  _industrialReport = existing.industrialReport;
                  _isLocked = existing.isLocked;
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
                // NEW: locked-state banner, shown only once a submission exists and is locked
                if (_isLocked) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline,
                            color: Colors.amber[800], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This evaluation has already been submitted and is locked. Ask your coordinator to unlock it if you need to make changes.',
                            style: GoogleFonts.outfit(
                                fontSize: 13, color: Colors.amber[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

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
                  enabled: !_isLocked, // NEW
                  onChanged: (v) => setState(() => _logbook = v),
                ),
                const SizedBox(height: 20),
                _ScoreSlider(
                  label: 'Technical Report',
                  value: _technicalReport,
                  max: 20,
                  color: const Color(0xFF0D47A1),
                  enabled: !_isLocked, // NEW
                  onChanged: (v) => setState(() => _technicalReport = v),
                ),
                const SizedBox(height: 20),
                _ScoreSlider(
                  label: 'Industrial Report',
                  value: _industrialReport,
                  max: 20,
                  color: const Color(0xFF1565C0),
                  enabled: !_isLocked, // NEW
                  onChanged: (v) => setState(() => _industrialReport = v),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isLocked ? Colors.grey : AppTheme.supervisorColor),
                    // NEW: disabled while locked, not just while submitting
                    onPressed: (_submitting || _isLocked) ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(_isLocked
                            ? Icons.lock_outline
                            : Icons.send_rounded),
                    label: Text(_isLocked ? 'Submission Locked' : 'Submit Scores'),
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
  final bool enabled; // NEW
  final ValueChanged<double> onChanged;

  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.enabled = true, // NEW
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : Colors.grey;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.15)),
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
                  color: effectiveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: effectiveColor,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: effectiveColor,
              thumbColor: effectiveColor,
              inactiveTrackColor: effectiveColor.withValues(alpha: 0.15),
              overlayColor: effectiveColor.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: max,
              divisions: max.toInt(),
              // NEW: locking disables the slider entirely
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}
