// lib/core/scoring_service.dart

/// Pure Dart scoring calculations — matching the Figma MSAGS prototype exactly.
class ScoringService {
  // ─── Supervisor Max Values ──────────────────────────────────────────────────
  static const double maxLogbook = 20;
  static const double maxTechnicalReport = 20;
  static const double maxIndustrialReport = 20;
  static const double maxSupervisor = 60; // 20+20+20

  // ─── Assessor Max Values ────────────────────────────────────────────────────
  static const double maxOral = 15;
  static const double maxAttitude = 15;
  static const double maxDressing = 10;
  static const double maxAssessor = 40; // 15+15+10

  /// Supervisor raw marks → total score (max 60)
  /// Raw max = 20+20+20 = 60 (no scaling needed)
  static double supervisorScore({
    required double logbook,
    required double technicalReport,
    required double industrialReport,
  }) {
    assert(logbook >= 0 && logbook <= maxLogbook,
        'Logbook must be 0–$maxLogbook');
    assert(technicalReport >= 0 && technicalReport <= maxTechnicalReport,
        'Technical Report must be 0–$maxTechnicalReport');
    assert(industrialReport >= 0 && industrialReport <= maxIndustrialReport,
        'Industrial Report must be 0–$maxIndustrialReport');
    return logbook + technicalReport + industrialReport;
  }

  /// Single assessor raw marks → total score (max 40)
  /// Raw max = 15+15+10 = 40 (no scaling needed)
  static double assessorScore({
    required double oral,
    required double attitude,
    required double dressing,
  }) {
    assert(oral >= 0 && oral <= maxOral, 'Oral must be 0–$maxOral');
    assert(attitude >= 0 && attitude <= maxAttitude,
        'Attitude must be 0–$maxAttitude');
    assert(dressing >= 0 && dressing <= maxDressing,
        'Dressing must be 0–$maxDressing');
    return oral + attitude + dressing;
  }

  /// Average of all assessors' scores
  static double assessorAverage(List<double> assessorScores) {
    if (assessorScores.isEmpty) return 0;
    final sum = assessorScores.reduce((a, b) => a + b);
    return sum / assessorScores.length;
  }

  /// Final grade = supervisor score + assessor average (max 100)
  static double finalScore({
    required double supervisorTotal,
    required double assessorAveraged,
  }) {
    return supervisorTotal + assessorAveraged;
  }

  /// Grade letter from final score out of 100
  static String gradeFromScore(double score) {
    if (score >= 70) return 'A';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    if (score >= 45) return 'D';
    if (score >= 40) return 'E';
    return 'F';
  }

  /// Remark from grade letter
  static String remarkFromGrade(String grade) {
    switch (grade) {
      case 'A': return 'Excellent';
      case 'B': return 'Good';
      case 'C': return 'Average';
      case 'D': return 'Below Average';
      case 'E': return 'Poor';
      default: return 'Fail';
    }
  }
}
