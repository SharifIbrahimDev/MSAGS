// lib/shared/widgets/status_badge.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SubmissionStatus { pending, submitted, finalized, unlocked, notAssigned }

class StatusBadge extends StatelessWidget {
  final SubmissionStatus status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      SubmissionStatus.pending => ('Pending', const Color(0xFFFFF3CD), const Color(0xFF856404)),
      SubmissionStatus.submitted => ('Submitted', const Color(0xFFD1E7DD), const Color(0xFF0A3622)),
      SubmissionStatus.finalized => ('Finalized', const Color(0xFFCFE2FF), const Color(0xFF084298)),
      SubmissionStatus.unlocked => ('Unlocked', const Color(0xFFFFE5D0), const Color(0xFF8B3A08)),
      SubmissionStatus.notAssigned => ('Not Assigned', const Color(0xFFF8D7DA), const Color(0xFF721C24)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
