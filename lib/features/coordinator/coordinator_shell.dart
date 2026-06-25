// lib/features/coordinator/coordinator_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/app_theme.dart';

class CoordinatorShell extends ConsumerWidget {
  final Widget child;
  const CoordinatorShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int selectedIndex = 0;
    if (location.contains('/monitor')) selectedIndex = 1;
    if (location.contains('/results')) selectedIndex = 2;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.coordinatorColor.withOpacity(0.12),
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/coordinator');
            case 1: context.go('/coordinator/monitor');
            case 2: context.go('/coordinator/results');
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.coordinatorColor),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_outlined),
            selectedIcon: Icon(Icons.monitor, color: AppTheme.coordinatorColor),
            label: 'Monitor',
          ),
          NavigationDestination(
            icon: const Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment, color: AppTheme.coordinatorColor),
            label: 'Results',
          ),
        ],
      ),
    );
  }
}
