// lib/features/assessor/assessor_shell.dart
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class AssessorShell extends StatelessWidget {
  final Widget child;
  const AssessorShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.assessorColor.withValues(alpha: 0.12),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppTheme.assessorColor),
            label: 'My Students',
          ),
        ],
      ),
    );
  }
}
