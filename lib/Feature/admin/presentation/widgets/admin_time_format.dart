import 'package:rosivia/l10n/app_localizations.dart';

/// Formats [time] as a short relative string ("Just now", "5 minutes
/// ago", "2 hours ago", "3 days ago") using only the given
/// timestamp — no invented data, just real elapsed time.
String formatRelativeTime(AppLocalizations lang, DateTime time) {
  final diff = DateTime.now().difference(time);

  if (diff.inMinutes < 1) return lang.adminJustNow;
  if (diff.inMinutes < 60) return lang.adminMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return lang.adminHoursAgo(diff.inHours);
  return lang.adminDaysAgo(diff.inDays);
}

/// Formats a duration between two real timestamps as e.g. "2m 14s" /
/// "45s" / "1h 03m". Returns null if either timestamp is missing.
String? formatSyncDuration(DateTime? start, DateTime? end) {
  if (start == null || end == null) return null;
  final diff = end.difference(start);
  if (diff.isNegative) return null;

  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  final seconds = diff.inSeconds % 60;

  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
  return '${seconds}s';
}

/// Parses a Firestore-stored ISO-8601 timestamp string, or returns
/// null if missing/invalid.
DateTime? parseIsoTimestamp(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
