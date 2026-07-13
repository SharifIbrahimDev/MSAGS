import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme.dart';

class StudentTile extends StatelessWidget {
  final dynamic student;
  final VoidCallback onAssignSupervisor;
  final VoidCallback onAssignAssessors;

  const StudentTile({
    super.key,
    required this.student,
    required this.onAssignSupervisor,
    required this.onAssignAssessors,
  });

  @override
  Widget build(BuildContext context) {
    final hasSupervisor = student.supervisorId != null;
    final assessorCount = (student.assessorIds as List?)?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Student Name
          Text(
            student.name,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          /// Matric No & Department
          Text(
            '${student.matricNo} • ${student.department}',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAssignSupervisor,
                  icon: Icon(
                    hasSupervisor
                        ? Icons.check_circle
                        : Icons.supervisor_account,
                    size: 18,
                  ),
                  label: Text(
                    hasSupervisor
                        ? 'Supervisor Assigned'
                        : 'Assign Supervisor',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.supervisorColor,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: GoogleFonts.outfit(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAssignAssessors,
                  icon: const Icon(Icons.group, size: 18),
                  label: Text(
                    'Assessors ($assessorCount/10)',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.assessorColor,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: GoogleFonts.outfit(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  context.go('/coordinator/student/${student.id}'),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View Profile'),
            ),
          ),
        ],
      ),
    );
  }
}