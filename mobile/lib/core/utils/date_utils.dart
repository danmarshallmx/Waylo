import 'package:intl/intl.dart';

class WayloDateUtils {
  static final DateFormat _displayFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _shortFormat = DateFormat('MMM d');
  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');

  /// Formats a date for display (e.g. "Nov 12, 2026").
  static String formatForDisplay(DateTime date) {
    return _displayFormat.format(date);
  }

  /// Formats a date in short form (e.g. "Nov 12").
  static String formatShort(DateTime date) {
    return _shortFormat.format(date);
  }

  /// Formats a date for API calls (e.g. "2026-11-12").
  static String formatForApi(DateTime date) {
    return _apiFormat.format(date);
  }

  /// Returns a human-readable date range string.
  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${DateFormat('MMM d').format(start)} – ${DateFormat('d, yyyy').format(end)}';
    } else if (start.year == end.year) {
      return '${_shortFormat.format(start)} – ${_displayFormat.format(end)}';
    }
    return '${_displayFormat.format(start)} – ${_displayFormat.format(end)}';
  }

  /// Returns the number of nights between two dates.
  static int nightsBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  /// Returns a human-readable "time ago" string.
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }
    return 'just now';
  }
}
