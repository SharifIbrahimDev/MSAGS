// lib/features/coordinator/bulk_upload_screen.dart

import 'dart:convert';
import 'dart:io' as io;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../core/models/app_user.dart';
import '../../core/models/student.dart';
import '../../core/providers.dart';
import '../../shared/utils/error_utils.dart';

class BulkUploadScreen extends ConsumerStatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  ConsumerState<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends ConsumerState<BulkUploadScreen> {
  // Config state
  String? _selectedDept = AppConstants.departments.first;
  String? _selectedCompany = AppConstants.placesOfAttachment.first;

  // File / Paste Data state
  PlatformFile? _pickedFile;
  final _pasteCtrl = TextEditingController();
  bool _usePastedData = false;

  // Processing state
  bool _loading = false;
  double _progress = 0.0;
  String _statusText = '';

  // Results state
  bool _showResults = false;
  int _successCount = 0;
  int _skippedCount = 0;
  int _supervisorAssignedCount = 0;
  final List<String> _logs = [];
  final Set<String> _unmatchedSupervisors = {};

  @override
  void dispose() {
    _pasteCtrl.dispose();
    super.dispose();
  }

  // Helper normalizer for supervisor name matching
  String _normalizeName(String name) {
    String norm = name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (norm.contains('ruqayya')) norm = norm.replaceAll('ruqayya', 'rukayya');
    return norm;
  }

  // CSV parsing logic
  List<List<String>> _parseCsv(String csvContent) {
    final List<List<String>> result = [];
    final lines = csvContent.split(RegExp(r'\r?\n'));
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final List<String> row = [];
      final StringBuffer buffer = StringBuffer();
      bool inQuotes = false;
      for (int i = 0; i < line.length; i++) {
        final char = line[i];
        if (char == '"') {
          inQuotes = !inQuotes;
        } else if (char == ',' && !inQuotes) {
          row.add(buffer.toString().trim());
          buffer.clear();
        } else {
          buffer.write(char);
        }
      }
      row.add(buffer.toString().trim());
      result.add(row);
    }
    return result;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _usePastedData = false;
          _showResults = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${getFriendlyError(e)}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _processData() async {
    String rawContent = '';
    if (_usePastedData) {
      rawContent = _pasteCtrl.text.trim();
      if (rawContent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please paste some CSV data first.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
    } else {
      if (_pickedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a CSV file first.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      try {
        if (_pickedFile!.bytes != null) {
          rawContent = utf8.decode(_pickedFile!.bytes!);
        } else if (!kIsWeb && _pickedFile!.path != null) {
          final file = io.File(_pickedFile!.path!);
          rawContent = await file.readAsString();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error reading file: ${getFriendlyError(e)}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _loading = true;
      _progress = 0.0;
      _statusText = 'Loading supervisor list...';
      _showResults = false;
      _successCount = 0;
      _skippedCount = 0;
      _supervisorAssignedCount = 0;
      _logs.clear();
      _unmatchedSupervisors.clear();
    });

    try {
      // 1. Fetch supervisors for fuzzy matching
      final db = ref.read(firestoreServiceProvider);
      final supervisorsList = await db.getUsersByRole(UserRole.supervisor);

      // 2. Parse CSV rows
      final parsedRows = _parseCsv(rawContent);
      if (parsedRows.isEmpty) {
        throw Exception('The CSV file is empty or formatted incorrectly.');
      }

      // 3. Find column indices (Header Row detection)
      int headerIndex = -1;
      int nameCol = -1;
      int matricCol = -1;
      int supervisorCol = -1;
      int deptCol = -1;
      int companyCol = -1;

      for (int i = 0; i < parsedRows.length; i++) {
        final row = parsedRows[i];
        for (int j = 0; j < row.length; j++) {
          final val = row[j].toLowerCase();
          if (val.contains('matric')) matricCol = j;
          if (val.contains('name')) nameCol = j;
          if (val.contains('supervisor')) supervisorCol = j;
          if (val.contains('department') || val.contains('dept')) deptCol = j;
          if (val.contains('company') || val.contains('attachment') || val.contains('place of')) companyCol = j;
        }
        if (nameCol != -1 && matricCol != -1) {
          headerIndex = i;
          break;
        }
      }

      if (headerIndex == -1) {
        // Assume default indices matching standard format:
        // SN (0), CSN (1), Name (2), Matric No (3), Supervisors (4)
        nameCol = 2;
        matricCol = 3;
        supervisorCol = 4;
        _logs.add('Notice: No explicit header row found. Using default column order (Col 3: Name, Col 4: Matric, Col 5: Supervisor).');
      } else {
        _logs.add('Detected header row at index $headerIndex. Mapping columns: Name (Col ${nameCol + 1}), Matric (Col ${matricCol + 1}), Supervisor (Col ${supervisorCol + 1}).');
      }

      final int startIndex = headerIndex != -1 ? headerIndex + 1 : 0;
      final int dataRowsCount = parsedRows.length - startIndex;
      if (dataRowsCount <= 0) {
        throw Exception('No student data rows found after the header.');
      }

      // Keep track of the current supervisor to carry down (merged cell layout)
      String? currentSupervisorId;
      String? currentSupervisorName;

      for (int i = startIndex; i < parsedRows.length; i++) {
        final row = parsedRows[i];
        final rowIndexDisplay = i + 1;

        // Skip rows that are too short to contain basic columns
        final maxColNeeded = [nameCol, matricCol].reduce((a, b) => a > b ? a : b);
        if (row.length <= maxColNeeded) {
          _logs.add('Row $rowIndexDisplay: Skipped (does not contain all required columns).');
          continue;
        }

        final studentName = row[nameCol].trim();
        final studentMatric = row[matricCol].trim();

        // Skip if name or matric is empty (likely empty spacing/title rows)
        if (studentName.isEmpty && studentMatric.isEmpty) {
          continue;
        }
        if (studentName.isEmpty || studentMatric.isEmpty) {
          _logs.add('Row $rowIndexDisplay: Skipped (missing Name or Matric No.).');
          continue;
        }

        // Supervisor assignment handling
        String? csvSupervisor;
        if (supervisorCol != -1 && row.length > supervisorCol) {
          csvSupervisor = row[supervisorCol].trim();
        }

        if (csvSupervisor != null && csvSupervisor.isNotEmpty) {
          // A new supervisor is listed in this row, look them up
          final normalizedCsv = _normalizeName(csvSupervisor);
          AppUser? matchedSupervisor;
          for (var sup in supervisorsList) {
            if (_normalizeName(sup.name) == normalizedCsv) {
              matchedSupervisor = sup;
              break;
            }
          }

          if (matchedSupervisor != null) {
            currentSupervisorId = matchedSupervisor.uid;
            currentSupervisorName = matchedSupervisor.name;
          } else {
            currentSupervisorId = null;
            currentSupervisorName = null;
            _unmatchedSupervisors.add(csvSupervisor);
          }
        }

        // Overwrite department and company if specified in CSV, else fallback to selected defaults
        String finalDept = _selectedDept ?? '';
        if (deptCol != -1 && row.length > deptCol && row[deptCol].trim().isNotEmpty) {
          finalDept = row[deptCol].trim();
        }

        String finalCompany = _selectedCompany ?? '';
        if (companyCol != -1 && row.length > companyCol && row[companyCol].trim().isNotEmpty) {
          finalCompany = row[companyCol].trim();
        }

        // Check if student with same Matric No already exists
        setState(() {
          _statusText = 'Checking student: $studentMatric ($studentName)...';
          _progress = (i - startIndex) / dataRowsCount;
        });

        final existing = await FirebaseFirestore.instance
            .collection('students')
            .where('matricNo', isEqualTo: studentMatric)
            .get();

        if (existing.docs.isNotEmpty) {
          _skippedCount++;
          _logs.add('Student $studentName ($studentMatric) already exists. Skipped.');
        } else {
          final student = Student(
            id: '',
            name: studentName,
            matricNo: studentMatric,
            department: finalDept,
            company: finalCompany,
            supervisorId: currentSupervisorId,
            assessorIds: const [],
            createdAt: DateTime.now(),
          );

          await db.createStudent(student);
          _successCount++;
          if (currentSupervisorId != null) {
            _supervisorAssignedCount++;
          }
        }
      }

      setState(() {
        _progress = 1.0;
        _statusText = 'Completed successfully!';
        _showResults = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing failed: ${getFriendlyError(e)}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Upload Students'),
        backgroundColor: AppTheme.coordinatorColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions / Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.coordinatorColor),
                        const SizedBox(width: 8),
                        Text(
                          'CSV Upload Guidelines',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Provide a CSV file containing columns for student allocations. Standard headers:',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Name, Matric No., Supervisors [, Department, Company]',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Merged Cells: Leave subsequent rows in the Supervisors column empty to allocate those students to the last active supervisor.\n'
                      '• Fuzzy Matching: Supervisor names will be mapped automatically (e.g. "Mr. Abubakar Mu\'azu" to "Mr Abubakar Muazu").\n'
                      '• Duplicates: Already registered matric numbers are skipped.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Settings Card (Default fallbacks)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default Values (Fallback)',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedDept,
                      decoration: const InputDecoration(
                        labelText: 'Default Department',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: AppConstants.departments.map((dept) {
                        return DropdownMenuItem<String>(
                          value: dept,
                          child: Text(dept),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedDept = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCompany,
                      decoration: const InputDecoration(
                        labelText: 'Default Place of Attachment',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      items: AppConstants.placesOfAttachment.map((company) {
                        return DropdownMenuItem<String>(
                          value: company,
                          child: Text(company),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCompany = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Toggle file picker vs Paste text
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Select CSV File')),
                    selected: !_usePastedData,
                    onSelected: (v) {
                      if (v) setState(() => _usePastedData = false);
                    },
                    selectedColor: AppTheme.coordinatorColor.withValues(alpha: 0.1),
                    labelStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: !_usePastedData ? AppTheme.coordinatorColor : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Paste CSV Text')),
                    selected: _usePastedData,
                    onSelected: (v) {
                      if (v) setState(() => _usePastedData = true);
                    },
                    selectedColor: AppTheme.coordinatorColor.withValues(alpha: 0.1),
                    labelStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: _usePastedData ? AppTheme.coordinatorColor : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content input zone
            if (!_usePastedData) ...[
              GestureDetector(
                onTap: _loading ? null : _pickFile,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _pickedFile != null ? AppTheme.secondary : Colors.grey[300]!,
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _pickedFile != null ? Icons.check_circle_outline_rounded : Icons.cloud_upload_outlined,
                        size: 48,
                        color: _pickedFile != null ? AppTheme.secondary : Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _pickedFile != null ? _pickedFile!.name : 'Click to select CSV File',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _pickedFile != null ? AppTheme.secondary : Colors.grey[600],
                        ),
                      ),
                      if (_pickedFile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _pasteCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Paste CSV Data here',
                  alignLabelWithHint: true,
                  hintText: 'Name, Matric No., Supervisors\nJohn Doe, KASU/23/CSC/1001, Mr Abubakar Muazu',
                ),
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),

            // Progress Indicators during upload
            if (_loading) ...[
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.coordinatorColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _statusText,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ],

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.coordinatorColor,
                ),
                onPressed: _loading ? null : _processData,
                child: _loading
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    : const Text('Process and Import Students'),
              ),
            ),
            const SizedBox(height: 24),

            // Summary Results UI
            if (_showResults) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppTheme.secondary, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Import Complete',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              label: 'Imported',
                              count: _successCount,
                              color: AppTheme.secondary,
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              label: 'Assigned Sup',
                              count: _supervisorAssignedCount,
                              color: AppTheme.supervisorColor,
                              icon: Icons.assignment_turned_in_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              label: 'Skipped',
                              count: _skippedCount,
                              color: AppTheme.warning,
                              icon: Icons.block_flipped,
                            ),
                          ),
                        ],
                      ),
                      if (_unmatchedSupervisors.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Unmatched Supervisors (${_unmatchedSupervisors.length})',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'These supervisor names were not found in the users collection. Students were imported but need supervisor assignment:\n'
                          '${_unmatchedSupervisors.join(", ")}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], height: 1.4),
                        ),
                      ],
                      if (_logs.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Import Logs',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          maxHeight: 180,
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _logs.length,
                            itemBuilder: (context, idx) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  _logs[idx],
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: _logs[idx].contains('Skipped')
                                        ? AppTheme.warning
                                        : _logs[idx].contains('Notice')
                                            ? AppTheme.coordinatorColor
                                            : Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
