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
    );
  }
}
