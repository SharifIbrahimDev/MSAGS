// lib/core/router.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers.dart';
import 'models/app_user.dart';

// Feature screens
import '../features/auth/login_screen.dart';
import '../features/coordinator/all_students_screen.dart';
import '../features/coordinator/coordinator_shell.dart';
import '../features/coordinator/dashboard_screen.dart';
import '../features/coordinator/register_student_screen.dart';
import '../features/coordinator/register_user_screen.dart';
import '../features/coordinator/assign_supervisor_screen.dart';
import '../features/coordinator/assign_assessors_screen.dart';
import '../features/coordinator/monitor_screen.dart';
import '../features/coordinator/results_screen.dart';
import '../features/supervisor/supervisor_shell.dart';
import '../features/supervisor/supervisor_dashboard_screen.dart';
import '../features/supervisor/score_entry_screen.dart';
import '../features/supervisor/student_result_screen.dart';
import '../features/assessor/assessor_shell.dart';
import '../features/assessor/assessor_dashboard_screen.dart';
import '../features/assessor/assessor_score_entry_screen.dart';

// ─── Auth Notifier (refreshListenable) ──────────────────────────────────────
/// A ChangeNotifier that listens to Firebase auth + Firestore user state
/// and notifies GoRouter to re-run redirect — without rebuilding the router.
class _RouterRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _authSub;
  User? _firebaseUser;
  AppUser? _appUser;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;

  _RouterRefreshNotifier(Ref ref) {
    // Listen to Firebase auth state
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _firebaseUser = user;
      notifyListeners();
    });

    // Watch Riverpod currentUserProvider and mirror changes here
    ref.listen<AsyncValue<AppUser?>>(currentUserProvider, (_, next) {
      _appUser = next.valueOrNull;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

// ─── Router Provider ─────────────────────────────────────────────────────────
/// The GoRouter is created ONCE and never recreated.
/// Auth state changes trigger redirect re-evaluation via refreshListenable.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(_routerRefreshProvider);

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final firebaseUser = refreshNotifier.firebaseUser;
      final appUser = refreshNotifier.appUser;

      // Still loading auth state — stay put
      if (firebaseUser == null && appUser == null &&
          ref.read(authStateProvider).isLoading) {
        return null;
      }

      final isLoggedIn = firebaseUser != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) {
        if (appUser == null) return null; // role still loading
        switch (appUser.role) {
          case UserRole.coordinator:
            return '/coordinator';
          case UserRole.supervisor:
            return '/supervisor';
          case UserRole.assessor:
            return '/assessor';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Coordinator Shell ──────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => CoordinatorShell(child: child),
        routes: [
          GoRoute(
            path: '/coordinator',
            builder: (context, state) => const CoordinatorDashboardScreen(),
          ),
          GoRoute(
            path: '/coordinator/register-student',
            builder: (context, state) => const RegisterStudentScreen(),
          ),
          GoRoute(
            path: '/coordinator/register-user',
            builder: (context, state) => const RegisterUserScreen(),
          ),
          GoRoute(
            path: '/coordinator/assign-supervisor/:studentId',
            builder: (context, state) => AssignSupervisorScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
          GoRoute(
            path: '/coordinator/assign-assessors/:studentId',
            builder: (context, state) => AssignAssessorsScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
          GoRoute(
            path: '/coordinator/monitor',
            builder: (context, state) => const MonitorScreen(),
          ),
          GoRoute(
            path: '/coordinator/results',
            builder: (context, state) => const ResultsScreen(),
          ),
          GoRoute(
            path: '/coordinator/all-students',
            builder: (context, state) => const CoordinatorAllStudentsScreen(),
          ),
        ],
      ),

      // ── Supervisor Shell ───────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => SupervisorShell(child: child),
        routes: [
          GoRoute(
            path: '/supervisor',
            builder: (context, state) => const SupervisorDashboardScreen(),
          ),
          GoRoute(
            path: '/supervisor/score/:studentId',
            builder: (context, state) => SupervisorScoreEntryScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
          GoRoute(
            path: '/supervisor/result/:studentId',
            builder: (context, state) => SupervisorStudentResultScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
        ],
      ),

      // ── Assessor Shell ─────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AssessorShell(child: child),
        routes: [
          GoRoute(
            path: '/assessor',
            builder: (context, state) => const AssessorDashboardScreen(),
          ),
          GoRoute(
            path: '/assessor/score/:studentId',
            builder: (context, state) => AssessorScoreEntryScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
        ],
      ),
    ],
  );

  return router;
});
