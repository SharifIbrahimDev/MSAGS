// lib/core/models/app_user.dart

enum UserRole { coordinator, supervisor, assessor }

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
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => throw Exception('Unknown user role: ${data['role']}'),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role.name,
      };
}
