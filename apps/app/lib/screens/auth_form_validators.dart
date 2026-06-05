/// Shared form validators for the auth screens. Pure functions (no widget
/// state) so they are unit testable and reused by both Log In and Sign Up.
library;

/// Returns an error string for an invalid email, or null when valid.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email.';
  // Lightweight shape check: something@something.tld. Supabase does the real
  // validation server-side; this just catches obvious typos before a round trip.
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  return ok ? null : 'Enter a valid email.';
}

/// Returns an error string for an invalid password, or null when valid.
/// Mirrors the local Supabase rule (`minimum_password_length = 6`).
String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Enter a password.';
  if (password.length < 6) return 'Password must be at least 6 characters.';
  return null;
}

/// Returns an error when [repeat] does not match [original], or null when it
/// matches (and is itself a valid password).
String? validatePasswordRepeat(String? repeat, String original) {
  final base = validatePassword(repeat);
  if (base != null) return base;
  if (repeat != original) return 'Passwords do not match.';
  return null;
}
