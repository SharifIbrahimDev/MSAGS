// lib/core/providers.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firestore_service.dart';
import 'models/app_user.dart';

// ─── Firebase Auth Stream ────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ─── Firestore Service Singleton ─────────────────────────────────────────────
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// ─── Current App User ────────────────────────────────────────────────────────
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return firestoreService.userStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ─── Auth Actions ─────────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firestoreServiceProvider));
});

class AuthService {
  final FirestoreService _firestoreService;
  AuthService(this._firestoreService);

  Future<void> signIn(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AppUser> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = AppUser(
      uid: cred.user!.uid,
      name: name,
      email: email.trim(),
      role: role,
    );
    await _firestoreService.createUser(user);
    return user;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
