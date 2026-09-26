/// Centralized form validators for consistent validation across all forms.
/// Each method returns null (valid) or an error message string (invalid).
class AppValidators {
  AppValidators._();

  // ── Email ─────────────────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address (e.g. you@example.com).';
    }
    return null;
  }

  // ── Password ──────────────────────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  /// Strong password — at least 8 chars, 1 uppercase, 1 lowercase, 1 digit.
  static String? passwordStrong(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Include at least one uppercase letter.';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Include at least one lowercase letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Include at least one number.';
    }
    return null;
  }

  /// Confirm password — checks it matches [original].
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != original) {
      return 'Passwords do not match.';
    }
    return null;
  }

  // ── Name ──────────────────────────────────────────────────────────────────
  static String? requiredName(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    if (value.trim().length < 2) {
      return '$label must be at least 2 characters.';
    }
    return null;
  }

  // ── Phone ─────────────────────────────────────────────────────────────────
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    final digits = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number.';
    }
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      return 'Phone number should contain only digits.';
    }
    return null;
  }

  // ── Generic required ──────────────────────────────────────────────────────
  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  // ── Journal / notes ───────────────────────────────────────────────────────
  static String? journalEntry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please write something before saving.';
    }
    if (value.trim().length < 10) {
      return 'Your entry seems too short. Share a bit more.';
    }
    return null;
  }

  // ── Birthday & Age ────────────────────────────────────────────────────────
  static String? birthday(String? value, {int minAge = 18}) {
    if (value == null || value.trim().isEmpty) {
      return 'Birthday is required.';
    }
    final trimmed = value.trim();
    DateTime? parsed;

    // Handle mm/dd/yyyy format
    final slashParts = trimmed.split('/');
    if (slashParts.length == 3) {
      final m = int.tryParse(slashParts[0]);
      final d = int.tryParse(slashParts[1]);
      final y = int.tryParse(slashParts[2]);
      if (m != null && d != null && y != null) {
        parsed = DateTime(y, m, d);
      }
    }

    // Handle yyyy-mm-dd format
    if (parsed == null) {
      final dashParts = trimmed.split('-');
      if (dashParts.length == 3) {
        final y = int.tryParse(dashParts[0]);
        final m = int.tryParse(dashParts[1]);
        final d = int.tryParse(dashParts[2]);
        if (y != null && m != null && d != null) {
          parsed = DateTime(y, m, d);
        }
      }
    }

    if (parsed == null) {
      return 'Enter a valid date.';
    }

    final now = DateTime.now();
    int age = now.year - parsed.year;
    if (now.month < parsed.month || (now.month == parsed.month && now.day < parsed.day)) {
      age--;
    }

    if (age < minAge) {
      return 'You must be at least $minAge years old to use Kausap AI.';
    }

    return null;
  }
}

