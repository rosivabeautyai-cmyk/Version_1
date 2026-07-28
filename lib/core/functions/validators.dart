/// Centralized form validation logic for ROSIVA.
///
/// Keeping validators in one place avoids duplicated logic across
/// the login, register, and forgot password screens.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.a-zA-Z0-9!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  /// Validates that a field is not empty.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates an email address format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates a strong password:
  /// at least 8 characters, one uppercase, one lowercase,
  /// one digit, and one special character.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Add at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Add at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]/;~`]').hasMatch(value)) {
      return 'Add at least one special character';
    }
    return null;
  }

  /// Validates a simpler login password (existence only).
  /// Strength rules only apply during registration.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates that confirm password matches the original password.
  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates a full name field.
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Enter a valid full name';
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value.trim())) {
      return 'Name can only contain letters';
    }
    return null;
  }

  /// Returns a 0.0-1.0 strength score for a password, useful for
  /// driving a strength meter widget in the UI.
  static double passwordStrength(String value) {
    if (value.isEmpty) return 0;
    double score = 0;
    if (value.length >= 8) score += 0.2;
    if (value.length >= 12) score += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(value)) score += 0.2;
    if (RegExp(r'[a-z]').hasMatch(value)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(value)) score += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]/;~`]').hasMatch(value)) {
      score += 0.15;
    }
    return score.clamp(0.0, 1.0);
  }
}
