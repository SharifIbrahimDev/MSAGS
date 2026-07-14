// lib/features/coordinator/all_students_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/student.dart';
import '../../core/providers.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/student_tile.dart';

class CoordinatorAllStudentsScreen extends ConsumerWidget {
  const CoordinatorAllStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          AppHeader(
            title: 'All Students',
            subtitle: 'SIWES Coordinator Portal',
            icon: Icons.people_rounded,
            actions: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: fs.studentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                    ),
                  );
                }

                final students = snapshot.data ?? [];

                if (students.isEmpty) {
                  return const Center(
                    child: Text(
                      'No students found',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];

                    return StudentTile(
                      student: student,
                      onAssignSupervisor: () {
                        context.go(
                          '/coordinator/assign-supervisor/${student.id}',
                        );
                      },
                      onAssignAssessors: () {
                        context.go(
                          '/coordinator/assign-assessors/${student.id}',
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}