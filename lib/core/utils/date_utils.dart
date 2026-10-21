import 'package:intl/intl.dart';

/// Date and time formatting utilities.
class AppDateUtils {
  AppDateUtils._();

  static String formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  static String formatTime(DateTime date) => DateFormat('h:mm a').format(date);

  static String formatDateTime(DateTime date) =>
      '${formatDate(date)} at ${formatTime(date)}';

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today ${formatTime(date)}';
    if (diff == 1) return 'Yesterday ${formatTime(date)}';
    if (diff < 7) return DateFormat('EEEE h:mm a').format(date);
    return formatDateTime(date);
  }

  static String formatMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return startOfDay(date.subtract(Duration(days: weekday - 1)));
  }

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime startOfYear(DateTime date) => DateTime(date.year, 1, 1);

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
