import 'package:intl/intl.dart';

class DateHelpers {
  DateHelpers._();

  static final _timeFormat = DateFormat('h:mm a');
  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _fullDateFormat = DateFormat('EEE, MMM d, yyyy');
  static final _dayMonthFormat = DateFormat('MMM d');
  static final _dateTimeFormat = DateFormat('MMM d, yyyy h:mm a');

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final period = h >= 12 ? 'PM' : 'AM';
      final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$dh:$m $period';
    } catch (_) {
      return timeStr;
    }
  }

  static String formatTimeFromDt(DateTime dt) => _timeFormat.format(dt.toLocal());

  static String formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return _dateFormat.format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatDateFromDt(DateTime dt) => _dateFormat.format(dt);

  static String formatFullDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return _fullDateFormat.format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatDayMonth(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return _dayMonthFormat.format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  static String formatDateTime(String dateStr, String timeStr) {
    try {
      final date = DateTime.parse(dateStr);
      final parts = timeStr.split(':');
      final dt = DateTime(
        date.year, date.month, date.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
      return _dateTimeFormat.format(dt);
    } catch (_) {
      return '$dateStr $timeStr';
    }
  }

  static String formatDateShort(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${_months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return dateStr;
    }
  }

  static String timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _dateFormat.format(dt);
  }

  static String leftTime(DateTime target) {
    final now = DateTime.now();
    if (target.isBefore(now)) return 'Overdue';
    final diff = target.difference(now);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    }
    return '${diff.inMinutes}m left';
  }

  static int diffInMinutes(DateTime a, DateTime b) =>
      a.difference(b).inMinutes.abs();
}
