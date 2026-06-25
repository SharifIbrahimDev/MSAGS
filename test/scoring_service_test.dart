// test/scoring_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:msags/core/scoring_service.dart';

void main() {
  // ─── Supervisor Score Tests ─────────────────────────────────────────────────
  group('ScoringService — Supervisor Score (max 60 = 20+20+20)', () {
    test('max marks → 60', () {
      expect(
        ScoringService.supervisorScore(
            logbook: 20, technicalReport: 20, industrialReport: 20),
        equals(60.0),
      );
    });

    test('zero marks → 0', () {
      expect(
        ScoringService.supervisorScore(
            logbook: 0, technicalReport: 0, industrialReport: 0),
        equals(0.0),
      );
    });

    test('half marks → 30', () {
      expect(
        ScoringService.supervisorScore(
            logbook: 10, technicalReport: 10, industrialReport: 10),
        equals(30.0),
      );
    });

    test('unequal marks are summed directly', () {
      expect(
        ScoringService.supervisorScore(
            logbook: 18, technicalReport: 15, industrialReport: 12),
        equals(45.0),
      );
    });

    test('Figma default values (15+15+15) → 45', () {
      expect(
        ScoringService.supervisorScore(
            logbook: 15, technicalReport: 15, industrialReport: 15),
        equals(45.0),
      );
    });
  });

  // ─── Assessor Score Tests ───────────────────────────────────────────────────
  group('ScoringService — Assessor Score (max 40 = 15+15+10)', () {
    test('max marks → 40', () {
      expect(
        ScoringService.assessorScore(oral: 15, attitude: 15, dressing: 10),
        equals(40.0),
      );
    });

    test('zero marks → 0', () {
      expect(
        ScoringService.assessorScore(oral: 0, attitude: 0, dressing: 0),
        equals(0.0),
      );
    });

    test('half marks → 20', () {
      expect(
        ScoringService.assessorScore(oral: 7.5, attitude: 7.5, dressing: 5),
        equals(20.0),
      );
    });

    test('Figma default values (12+12+8) → 32', () {
      expect(
        ScoringService.assessorScore(oral: 12, attitude: 12, dressing: 8),
        equals(32.0),
      );
    });

    test('max oral + zero others → 15', () {
      expect(
        ScoringService.assessorScore(oral: 15, attitude: 0, dressing: 0),
        equals(15.0),
      );
    });
  });

  // ─── Assessor Average Tests ─────────────────────────────────────────────────
  group('ScoringService — Assessor Average', () {
    test('empty list → 0', () {
      expect(ScoringService.assessorAverage([]), equals(0.0));
    });

    test('single assessor score returned as-is', () {
      expect(ScoringService.assessorAverage([32.0]), equals(32.0));
    });

    test('multiple assessors averaged', () {
      expect(
        ScoringService.assessorAverage([20.0, 30.0, 40.0]),
        closeTo(30.0, 0.001),
      );
    });

    test('10 assessors with max 40 → 40', () {
      expect(
        ScoringService.assessorAverage(List.filled(10, 40.0)),
        equals(40.0),
      );
    });
  });

  // ─── Final Score Tests ──────────────────────────────────────────────────────
  group('ScoringService — Final Score (max 100)', () {
    test('max supervisor + max assessor → 100', () {
      expect(
        ScoringService.finalScore(supervisorTotal: 60, assessorAveraged: 40),
        equals(100.0),
      );
    });

    test('zero → 0', () {
      expect(
        ScoringService.finalScore(supervisorTotal: 0, assessorAveraged: 0),
        equals(0.0),
      );
    });

    test('typical result: 45 supervisor + 32 assessor → 77', () {
      expect(
        ScoringService.finalScore(supervisorTotal: 45, assessorAveraged: 32),
        equals(77.0),
      );
    });
  });

  // ─── Grading Tests ──────────────────────────────────────────────────────────
  group('ScoringService — Grading', () {
    test('70+ → A (Excellent)', () {
      expect(ScoringService.gradeFromScore(77), equals('A'));
      expect(ScoringService.remarkFromGrade('A'), equals('Excellent'));
    });

    test('60–69 → B (Good)', () {
      expect(ScoringService.gradeFromScore(65), equals('B'));
      expect(ScoringService.remarkFromGrade('B'), equals('Good'));
    });

    test('50–59 → C (Average)', () {
      expect(ScoringService.gradeFromScore(55), equals('C'));
    });

    test('45–49 → D (Below Average)', () {
      expect(ScoringService.gradeFromScore(47), equals('D'));
    });

    test('40–44 → E (Poor)', () {
      expect(ScoringService.gradeFromScore(42), equals('E'));
    });

    test('below 40 → F (Fail)', () {
      expect(ScoringService.gradeFromScore(35), equals('F'));
      expect(ScoringService.remarkFromGrade('F'), equals('Fail'));
    });

    test('edge: exactly 70 → A', () {
      expect(ScoringService.gradeFromScore(70), equals('A'));
    });

    test('edge: exactly 40 → E', () {
      expect(ScoringService.gradeFromScore(40), equals('E'));
    });
  });
}
