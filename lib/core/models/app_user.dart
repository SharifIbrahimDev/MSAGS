// lib/core/models/app_user.dart

enum UserRole { coordinator, supervisor, assessor, admin }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    final rawRole = (data['role'] ?? '').toString().trim().toLowerCase();
    UserRole role;
    if (rawRole == 'admin' || rawRole == 'administrator') {
      role = UserRole.admin;
    } else if (rawRole == 'coordinator') {
      role = UserRole.coordinator;
    } else if (rawRole == 'supervisor') {
      role = UserRole.supervisor;
    } else if (rawRole == 'assessor') {
      role = UserRole.assessor;
    } else {
      // Safe fallback to coordinator instead of throwing exception
      role = UserRole.coordinator;
    }

    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: role,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role.name,
      };
}
