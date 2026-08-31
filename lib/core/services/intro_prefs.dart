import 'package:shared_preferences/shared_preferences.dart';

/// Tiny persistence helper for the one-time intro flow (language pick +
/// onboarding pages). Once the user has been through it, every later
/// launch skips straight to [AuthGate] — the launch decision is driven
/// by this flag + Firebase Auth state, never a timer.
class IntroPrefs {
  IntroPrefs._();

  static const String _seenKey = 'has_seen_intro_v1';

  /// True once the language + onboarding screens have been completed
  /// (or skipped) at least once. Reads are best-effort: any storage
  /// failure is treated as "not seen" so the user still gets the intro
  /// rather than a broken launch.
  static Future<bool> hasSeenIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_seenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Marks the intro flow as completed. Best-effort — a failure here
  /// just means the user sees the intro once more next launch.
  static Future<void> setIntroSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenKey, true);
    } catch (_) {
      // ignore
    }
  }
}
