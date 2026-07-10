// lib/features/supervisor/supervisor_shell.dart
import 'package:flutter/material.dart';

class SupervisorShell extends StatelessWidget {
  final Widget child;
  const SupervisorShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
    );
  }
}
