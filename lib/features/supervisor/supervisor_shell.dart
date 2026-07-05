// lib/features/supervisor/supervisor_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_theme.dart';

class SupervisorShell extends StatelessWidget {
  final Widget child;
  const SupervisorShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = location == '/supervisor' ? 0 : 0;

    return Scaffold(
      body: child,
    );
  }
}
