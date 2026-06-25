// lib/core/models/student.dart

class Student {
  final String id;
  final String name;
  final String matricNo;
  final String department;
  final String company;
  final String? supervisorId;
  final List<String> assessorIds;
  final DateTime createdAt;

  const Student({
    required this.id,
    required this.name,
    required this.matricNo,
    required this.department,
    required this.company,
    this.supervisorId,
    this.assessorIds = const [],
    required this.createdAt,
  });

  factory Student.fromMap(String id, Map<String, dynamic> data) {
    return Student(
      id: id,
      name: data['name'] ?? '',
      matricNo: data['matricNo'] ?? '',
      department: data['department'] ?? '',
      company: data['company'] ?? '',
      supervisorId: data['supervisorId'],
      assessorIds: List<String>.from(data['assessorIds'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'matricNo': matricNo,
        'department': department,
        'company': company,
        'supervisorId': supervisorId,
        'assessorIds': assessorIds,
        'createdAt': createdAt,
      };

  Student copyWith({
    String? supervisorId,
    List<String>? assessorIds,
  }) {
    return Student(
      id: id,
      name: name,
      matricNo: matricNo,
      department: department,
      company: company,
      supervisorId: supervisorId ?? this.supervisorId,
      assessorIds: assessorIds ?? this.assessorIds,
      createdAt: createdAt,
    );
  }
}
