/// Input validation utilities for DietLog.
///
/// Provides reusable validators for authentication forms and
/// nutritional data integrity checks.
class Validators {
  Validators._();

  // ── Email ───────────────────────────────────────────────────────────────

  /// Validates an email address format.
  ///
  /// Returns `null` if valid, or an error message string if invalid.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    // RFC 5322 simplified pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // ── Password ────────────────────────────────────────────────────────────

  /// Validates password strength.
  ///
  /// Requirements:
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one digit
  ///
  /// Returns `null` if valid, or an error message string if invalid.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one digit';
    }

    return null;
  }

  /// Validates that a confirm-password field matches the original password.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ── Name ─────────────────────────────────────────────────────────────────

  /// Validates a full name field.
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Name must be less than 100 characters';
    }
    return null;
  }

  // ── Nutritional Values ──────────────────────────────────────────────────

  /// Validates that a numeric nutritional value is non-negative.
  ///
  /// Used to enforce the database CHECK constraints at the app level
  /// before data reaches Supabase.
  static String? nonNegativeInt(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName must be a valid integer';
    }
    if (parsed < 0) {
      return '$fieldName must be non-negative';
    }
    return null;
  }

  /// Validates that a numeric nutritional value (double) is non-negative.
  static String? nonNegativeDouble(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName must be a valid number';
    }
    if (parsed < 0) {
      return '$fieldName must be non-negative';
    }
    return null;
  }
}
