// lib/shared/utils/error_utils.dart

String getFriendlyError(dynamic e) {
  final raw = e.toString().toLowerCase();

  // Auth specific
  if (raw.contains('user-not-found') || raw.contains('wrong-password') || raw.contains('invalid-credential')) {
    return 'Invalid email or password. Please try again.';
  }
  if (raw.contains('user-disabled')) return 'Your account has been disabled. Please contact the coordinator.';
  if (raw.contains('invalid-email')) return 'The email address is badly formatted.';
  if (raw.contains('email-already-in-use')) return 'An account already exists with that email address.';
  if (raw.contains('weak-password')) return 'The password is too weak. Please use at least 6 characters.';
  if (raw.contains('too-many-requests')) return 'Too many failed attempts. Please try again later.';
  if (raw.contains('operation-not-allowed')) return 'This sign-in method is currently disabled.';

  // Network & Offline
  if (raw.contains('network-request-failed')) return 'Network error. Please check your internet connection and try again.';
  if (raw.contains('unavailable')) return 'The service is temporarily unavailable. Check your connection or try again later.';
  if (raw.contains('timeout')) return 'The request timed out. Please try again.';

  // Firestore permissions
  if (raw.contains('permission-denied')) return 'You do not have permission to perform this action.';
  
  // Generic fallback
  return 'An unexpected error occurred. Please try again.';
}
