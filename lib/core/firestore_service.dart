// lib/core/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/app_user.dart';
import 'models/student.dart';
import 'models/evaluation.dart';
import 'scoring_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collections ────────────────────────────────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _students => _db.collection('students');
  CollectionReference get _supervisorEvals => _db.collection('supervisor_evaluations');
  CollectionReference get _assessorEvals => _db.collection('assessor_evaluations');
  CollectionReference get _results => _db.collection('results');

  // ─── User Operations ─────────────────────────────────────────────────────────

  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data() as Map<String, dynamic>);
  }

  Stream<AppUser?> userStream(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromMap(uid, snap.data() as Map<String, dynamic>);
    });
  }

  Future<void> createUser(AppUser user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    final snap = await _users.where('role', isEqualTo: role.name).get();
    return snap.docs
        .map((d) => AppUser.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  // ─── Student Operations ───────────────────────────────────────────────────────

  Future<String> createStudent(Student student) async {
    final ref = await _students.add(student.toMap());
    return ref.id;
  }

  Stream<List<Student>> studentsStream() {
    return _students.orderBy('name').snapshots().map((snap) => snap.docs
        .map((d) => Student.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Stream<List<Student>> studentsForSupervisor(String supervisorId) {
    return _students
        .where('supervisorId', isEqualTo: supervisorId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Student.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<Student>> studentsForAssessor(String assessorId) {
    return _students
        .where('assessorIds', arrayContains: assessorId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Student.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> assignSupervisor(String studentId, String supervisorId) async {
    await _students.doc(studentId).update({'supervisorId': supervisorId});
  }

  Future<void> assignAssessors(String studentId, List<String> assessorIds) async {
    if (assessorIds.length > 10) {
      throw Exception('Cannot assign more than 10 assessors per student.');
    }
    await _students.doc(studentId).update({
      'assessorIds': assessorIds,
    });
    // Update result doc count
    await _results.doc(studentId).set({
      'assessorCount': assessorIds.length,
    }, SetOptions(merge: true));
  }

  // ─── Supervisor Evaluation ────────────────────────────────────────────────────

  Future<void> submitSupervisorEval(SupervisorEvaluation eval) async {
    await _supervisorEvals.doc(eval.studentId).set(eval.toMap());
    // Recalculate result
    await _recalculateResult(eval.studentId);
  }

  Stream<SupervisorEvaluation?> supervisorEvalStream(String studentId) {
    return _supervisorEvals.doc(studentId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return SupervisorEvaluation.fromMap(
          studentId, snap.data() as Map<String, dynamic>);
    });
  }

  Future<void> unlockSupervisorEval(String studentId) async {
    await _supervisorEvals.doc(studentId).update({'isLocked': false});
  }

  // ─── Assessor Evaluation ──────────────────────────────────────────────────────

  Future<void> submitAssessorEval(AssessorEvaluation eval) async {
    await _assessorEvals
        .doc(eval.studentId)
        .collection('assessors')
        .doc(eval.assessorId)
        .set(eval.toMap());
    // Recalculate result
    await _recalculateResult(eval.studentId);
  }

  Future<bool> hasAssessorSubmitted(String studentId, String assessorId) async {
    final doc = await _assessorEvals
        .doc(studentId)
        .collection('assessors')
        .doc(assessorId)
        .get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>;
    return data['isLocked'] == true;
  }

  Stream<AssessorEvaluation?> assessorEvalStream(
      String studentId, String assessorId) {
    return _assessorEvals
        .doc(studentId)
        .collection('assessors')
        .doc(assessorId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return AssessorEvaluation.fromMap(
          studentId, assessorId, snap.data() as Map<String, dynamic>);
    });
  }

  Future<List<AssessorEvaluation>> getAllAssessorEvals(String studentId) async {
    final snap = await _assessorEvals
        .doc(studentId)
        .collection('assessors')
        .get();
    return snap.docs
        .map((d) => AssessorEvaluation.fromMap(
            studentId, d.id, d.data()))
        .toList();
  }

  Future<void> unlockAssessorEval(String studentId, String assessorId) async {
    await _assessorEvals
        .doc(studentId)
        .collection('assessors')
        .doc(assessorId)
        .update({'isLocked': false});
  }

  // ─── Results ──────────────────────────────────────────────────────────────────

  Future<void> _recalculateResult(String studentId) async {
    double? supervisorScaled;
    double? assessorAvg;

    // Get supervisor score
    final supDoc = await _supervisorEvals.doc(studentId).get();
    if (supDoc.exists) {
      final supEval = SupervisorEvaluation.fromMap(
          studentId, supDoc.data() as Map<String, dynamic>);
      supervisorScaled = supEval.scaledScore;
    }

    // Get all assessor scores
    final assessorEvals = await getAllAssessorEvals(studentId);
    if (assessorEvals.isNotEmpty) {
      final scores = assessorEvals.map((e) => e.scaledScore).toList();
      assessorAvg = ScoringService.assessorAverage(scores);
    }

    double? finalScore;
    if (supervisorScaled != null && assessorAvg != null) {
      finalScore = ScoringService.finalScore(
        supervisorTotal: supervisorScaled,
        assessorAveraged: assessorAvg,
      );
    }

    await _results.doc(studentId).set({
      'supervisorScore': supervisorScaled,
      'assessorAverage': assessorAvg,
      'finalScore': finalScore,
      'assessorsSubmitted': assessorEvals.length,
    }, SetOptions(merge: true));
  }

  Stream<StudentResult?> resultStream(String studentId) {
    return _results.doc(studentId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return StudentResult.fromMap(studentId, snap.data() as Map<String, dynamic>);
    });
  }

  Stream<List<StudentResult>> allResultsStream() {
    return _results.snapshots().map((snap) => snap.docs
        .map((d) => StudentResult.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> finalizeResult(String studentId) async {
    await _results.doc(studentId).update({'isFinalized': true});
  }

  Future<void> unlockResult(String studentId) async {
    await _results.doc(studentId).update({'isFinalized': false});
    // Also unlock supervisor eval
    final supDoc = await _supervisorEvals.doc(studentId).get();
    if (supDoc.exists) {
      await _supervisorEvals.doc(studentId).update({'isLocked': false});
    }
  }
}
