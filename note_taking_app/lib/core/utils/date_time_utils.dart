import 'package:intl/intl.dart';

class DateTimeUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _fullDateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  
  /// Format DateTime to ISO string
  static String toIsoString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
  
  /// Parse ISO string to DateTime
  static DateTime? fromIsoString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      return DateTime.parse(isoString);
    } catch (e) {
      return null;
    }
  }
  
  /// Format DateTime to readable date string
  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }
  
  /// Format DateTime to readable time string
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }
  
  /// Format DateTime to readable date and time string
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
  
  /// Format DateTime to full readable date and time string
  static String formatFullDateTime(DateTime dateTime) {
    return _fullDateTimeFormat.format(dateTime);
  }
  
  /// Get relative time string (e.g., "2 hours ago", "yesterday")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? 'Yesterday' : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? '1 hour ago' : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? '1 minute ago' : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
  
  /// Check if a DateTime is today
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }
  
  /// Check if a DateTime is tomorrow
  static bool isTomorrow(DateTime dateTime) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dateTime.year == tomorrow.year &&
           dateTime.month == tomorrow.month &&
           dateTime.day == tomorrow.day;
  }
  
  /// Check if a DateTime is yesterday
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
           dateTime.month == yesterday.month &&
           dateTime.day == yesterday.day;
  }
  
  /// Get the start of day for a given DateTime
  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
  
  /// Get the end of day for a given DateTime
  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 999);
  }
  
  /// Check if a reminder is due (within the next 5 minutes)
  static bool isReminderDue(DateTime reminderTime) {
    final now = DateTime.now();
    final fiveMinutesFromNow = now.add(const Duration(minutes: 5));
    return reminderTime.isBefore(fiveMinutesFromNow) && reminderTime.isAfter(now);
  }
  
  /// Get next occurrence for recurring reminders
  static DateTime? getNextOccurrence(DateTime lastOccurrence, String interval) {
    switch (interval.toLowerCase()) {
      case 'daily':
        return lastOccurrence.add(const Duration(days: 1));
      case 'weekly':
        return lastOccurrence.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(
          lastOccurrence.year,
          lastOccurrence.month + 1,
          lastOccurrence.day,
          lastOccurrence.hour,
          lastOccurrence.minute,
        );
      case 'yearly':
        return DateTime(
          lastOccurrence.year + 1,
          lastOccurrence.month,
          lastOccurrence.day,
          lastOccurrence.hour,
          lastOccurrence.minute,
        );
      default:
        return null;
    }
  }
}