// lib/core/router.dart
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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoading = authState.isLoading || currentUser.isLoading;
      if (isLoading) return null;

      final firebaseUser = authState.valueOrNull;
      final appUser = currentUser.valueOrNull;

      final isLoggedIn = firebaseUser != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) {
        if (appUser == null) return null; // still loading user role
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
});
