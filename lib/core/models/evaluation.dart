// lib/core/models/evaluation.dart

class SupervisorEvaluation {
  final String studentId;
  final String supervisorId;
  final double logbook;        // 0–25
  final double technicalReport; // 0–25
  final double industrialReport; // 0–25
  final DateTime submittedAt;
  final bool isLocked;

  const SupervisorEvaluation({
    required this.studentId,
    required this.supervisorId,
    required this.logbook,
    required this.technicalReport,
    required this.industrialReport,
    required this.submittedAt,
    this.isLocked = true,
  });

  /// Supervisor total score scaled to 60
  /// Raw max = 20+20+20 = 60, so scaledScore = rawSum directly
  double get scaledScore => logbook + technicalReport + industrialReport;

  factory SupervisorEvaluation.fromMap(String studentId, Map<String, dynamic> data) {
    return SupervisorEvaluation(
      studentId: studentId,
      supervisorId: data['supervisorId'] ?? '',
      logbook: (data['logbook'] ?? 0).toDouble(),
      technicalReport: (data['technicalReport'] ?? 0).toDouble(),
      industrialReport: (data['industrialReport'] ?? 0).toDouble(),
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] as dynamic).toDate()
          : DateTime.now(),
      isLocked: data['isLocked'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'supervisorId': supervisorId,
        'logbook': logbook,
        'technicalReport': technicalReport,
        'industrialReport': industrialReport,
        'submittedAt': submittedAt,
        'isLocked': isLocked,
        'scaledScore': scaledScore,
      };
}

class AssessorEvaluation {
  final String studentId;
  final String assessorId;
  final double oral;        // 0–20
  final double attitudinal; // 0–20
  final double display;     // 0–10
  final DateTime submittedAt;
  final bool isLocked;

  const AssessorEvaluation({
    required this.studentId,
    required this.assessorId,
    required this.oral,
    required this.attitudinal,
    required this.display,
    required this.submittedAt,
    this.isLocked = true,
  });

  /// Assessor raw total (out of 40)
  /// Raw max = 15+15+10 = 40, so scaledScore = rawSum directly
  double get rawTotal => oral + attitudinal + display;

  /// Assessor score (max 40)
  double get scaledScore => oral + attitudinal + display;

  factory AssessorEvaluation.fromMap(
      String studentId, String assessorId, Map<String, dynamic> data) {
    return AssessorEvaluation(
      studentId: studentId,
      assessorId: assessorId,
      oral: (data['oral'] ?? 0).toDouble(),
      attitudinal: (data['attitudinal'] ?? 0).toDouble(),
      display: (data['display'] ?? 0).toDouble(),
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] as dynamic).toDate()
          : DateTime.now(),
      isLocked: data['isLocked'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'assessorId': assessorId,
        'oral': oral,
        'attitudinal': attitudinal,
        'display': display,
        'submittedAt': submittedAt,
        'isLocked': isLocked,
        'scaledScore': scaledScore,
      };
}

class StudentResult {
  final String studentId;
  final double? supervisorScore;    // scaled /60
  final double? assessorAverage;   // average of assessors' scaled scores /40
  final double? finalScore;         // sum /100
  final bool isFinalized;
  final int assessorCount;
  final int assessorsSubmitted;

  const StudentResult({
    required this.studentId,
    this.supervisorScore,
    this.assessorAverage,
    this.finalScore,
    this.isFinalized = false,
    this.assessorCount = 0,
    this.assessorsSubmitted = 0,
  });

  factory StudentResult.fromMap(String studentId, Map<String, dynamic> data) {
    return StudentResult(
      studentId: studentId,
      supervisorScore: (data['supervisorScore'] as num?)?.toDouble(),
      assessorAverage: (data['assessorAverage'] as num?)?.toDouble(),
      finalScore: (data['finalScore'] as num?)?.toDouble(),
      isFinalized: data['isFinalized'] ?? false,
      assessorCount: data['assessorCount'] ?? 0,
      assessorsSubmitted: data['assessorsSubmitted'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'supervisorScore': supervisorScore,
        'assessorAverage': assessorAverage,
        'finalScore': finalScore,
        'isFinalized': isFinalized,
        'assessorCount': assessorCount,
        'assessorsSubmitted': assessorsSubmitted,
      };
}
