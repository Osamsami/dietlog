import 'package:intl/intl.dart';

/// Utility class for date/time formatting and range computation.
///
/// Provides consistent date formatting across the app and helper
/// methods for computing the 7-day and 30-day temporal windows
/// used by the dashboard aggregation queries.
class DateFormatter {
  DateFormatter._();

  // ── Formatters ──────────────────────────────────────────────────────────
  static final _fullDate = DateFormat('MMM d, yyyy');
  static final _shortDate = DateFormat('MMM d');
  static final _time = DateFormat('h:mm a');
  static final _dateTime = DateFormat('MMM d, yyyy h:mm a');
  static final _isoDate = DateFormat('yyyy-MM-dd');

  /// Format as "May 25, 2026".
  static String fullDate(DateTime dt) => _fullDate.format(dt);

  /// Format as "May 25".
  static String shortDate(DateTime dt) => _shortDate.format(dt);

  /// Format as "3:45 PM".
  static String time(DateTime dt) => _time.format(dt);

  /// Format as "May 25, 2026 3:45 PM".
  static String dateTime(DateTime dt) => _dateTime.format(dt);

  /// Format as "2026-05-25" (ISO 8601 date only).
  static String isoDate(DateTime dt) => _isoDate.format(dt);

  // ── Relative Labels ─────────────────────────────────────────────────────

  /// Returns a human-readable relative label: "Today", "Yesterday", or date.
  static String relativeLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);

    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return fullDate(dt);
  }

  // ── Date Range Helpers ──────────────────────────────────────────────────

  /// Returns the start of today (midnight).
  static DateTime startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Returns the end of today (23:59:59.999).
  static DateTime endOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  }

  /// Returns a [DateTime] representing [days] days ago at midnight.
  static DateTime daysAgo(int days) {
    final now = DateTime.now();
    final target = now.subtract(Duration(days: days));
    return DateTime(target.year, target.month, target.day);
  }

  /// Returns the start of the 7-day window (for weekly dashboard).
  static DateTime startOfWeek() => daysAgo(7);

  /// Returns the start of the 30-day window (for monthly dashboard).
  static DateTime startOfMonth() => daysAgo(30);

  /// Converts a [DateTime] to an ISO 8601 string suitable for Supabase queries.
  static String toSupabaseTimestamp(DateTime dt) =>
      dt.toUtc().toIso8601String();
}
