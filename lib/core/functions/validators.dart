import 'package:rosivia/l10n/app_localizations.dart';

/// Centralized form validation logic for ROSIVA.
///
/// Keeping validators in one place avoids duplicated logic across
/// the login, register, and forgot password screens.
///
/// Validation rules are unchanged from before — only the returned
/// messages now come from [AppLocalizations] so they are shown in
/// the user's selected language.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.a-zA-Z0-9!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  /// Validates that a field is not empty.
  static String? required(String? value, AppLocalizations lang) {
    if (value == null || value.trim().isEmpty) {
      return lang.emailRequired;
    }
    return null;
  }

  /// Validates an email address format.
  static String? email(String? value, AppLocalizations lang) {
    if (value == null || value.trim().isEmpty) {
      return lang.emailRequired;
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return lang.emailInvalid;
    }
    return null;
  }

  /// Validates a strong password:
  /// at least 8 characters, one uppercase, one lowercase,
  /// one digit, and one special character.
  static String? password(String? value, AppLocalizations lang) {
    if (value == null || value.isEmpty) {
      return lang.passwordRequired;
    }
    if (value.length < 8) {
      return lang.passwordMinLength;
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return lang.passwordUppercase;
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return lang.passwordLowercase;
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return lang.passwordNumber;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]/;~`]').hasMatch(value)) {
      return lang.passwordSpecialChar;
    }
    return null;
  }

  /// Validates a simpler login password (existence only).
  /// Strength rules only apply during registration.
  static String? loginPassword(String? value, AppLocalizations lang) {
    if (value == null || value.isEmpty) {
      return lang.passwordRequired;
    }
    if (value.length < 6) {
      return lang.loginPasswordMinLength;
    }
    return null;
  }

  /// Validates that confirm password matches the original password.
  static String? confirmPassword(
    String? value,
    String originalPassword,
    AppLocalizations lang,
  ) {
    if (value == null || value.isEmpty) {
      return lang.confirmPasswordRequired;
    }
    if (value != originalPassword) {
      return lang.passwordsDoNotMatch;
    }
    return null;
  }

  /// Validates a full name field.
  static String? fullName(String? value, AppLocalizations lang) {
    if (value == null || value.trim().isEmpty) {
      return lang.fullNameRequired;
    }
    if (value.trim().length < 2) {
      return lang.fullNameInvalid;
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value.trim())) {
      return lang.fullNameLettersOnly;
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
