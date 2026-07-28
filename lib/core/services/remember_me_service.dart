import 'package:shared_preferences/shared_preferences.dart';

/// Persists ONLY the "Remember Me" boolean flag and the last-used
/// email address for convenience. Passwords are never stored.
class RememberMeService {
  RememberMeService._();

  static const String _rememberMeKey = 'rosiva_remember_me';
  static const String _savedEmailKey = 'rosiva_saved_email';

  static Future<void> setRememberMe(bool value, {String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
    if (value && email != null && email.trim().isNotEmpty) {
      await prefs.setString(_savedEmailKey, email.trim());
    } else if (!value) {
      await prefs.remove(_savedEmailKey);
    }
  }

  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedEmailKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_savedEmailKey);
  }
}
