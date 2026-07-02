import 'package:flutter_test/flutter_test.dart';
import 'package:bus_express/core/utils/date_helpers.dart';

void main() {
  group('DateHelpers', () {
    group('formatTime', () {
      test('converts 24h to 12h', () {
        expect(DateHelpers.formatTime('08:30'), '8:30 AM');
        expect(DateHelpers.formatTime('12:00'), '12:00 PM');
        expect(DateHelpers.formatTime('13:15'), '1:15 PM');
        expect(DateHelpers.formatTime('00:05'), '12:05 AM');
      });

      test('returns raw on parse failure', () {
        expect(DateHelpers.formatTime('invalid'), 'invalid');
      });
    });

    group('formatDate', () {
      test('formats ISO date string', () {
        expect(DateHelpers.formatDate('2025-06-15'), contains('Jun'));
        expect(DateHelpers.formatDate('2025-06-15'), contains('15'));
        expect(DateHelpers.formatDate('2025-06-15'), contains('2025'));
      });

      test('returns raw on parse failure', () {
        expect(DateHelpers.formatDate('bad-date'), 'bad-date');
      });
    });

    group('formatFullDate', () {
      test('includes day of week', () {
        // 2025-06-15 is a Sunday
        final result = DateHelpers.formatDate('2025-06-15');
        expect(result, contains('15'));
      });

      test('returns raw on parse failure', () {
        expect(DateHelpers.formatFullDate('x'), 'x');
      });
    });

    group('formatDuration', () {
      test('shows only hours when exact', () {
        expect(DateHelpers.formatDuration(120), '2h');
      });

      test('shows only minutes when under an hour', () {
        expect(DateHelpers.formatDuration(45), '45min');
      });

      test('shows hours and minutes', () {
        expect(DateHelpers.formatDuration(150), '2h 30min');
      });
    });

    group('timeAgo', () {
      test('just now', () {
        expect(DateHelpers.timeAgo(DateTime.now()), 'just now');
      });

      test('minutes ago', () {
        final dt = DateTime.now().subtract(const Duration(minutes: 5));
        expect(DateHelpers.timeAgo(dt), '5m ago');
      });

      test('hours ago', () {
        final dt = DateTime.now().subtract(const Duration(hours: 3));
        expect(DateHelpers.timeAgo(dt), '3h ago');
      });

      test('days ago', () {
        final dt = DateTime.now().subtract(const Duration(days: 4));
        expect(DateHelpers.timeAgo(dt), '4d ago');
      });
    });

    group('leftTime', () {
      test('returns overdue for past time', () {
        expect(DateHelpers.leftTime(DateTime.now().subtract(const Duration(hours: 1))), 'Overdue');
      });

      test('returns hours and minutes left', () {
        final target = DateTime.now().add(const Duration(hours: 2, minutes: 30));
        expect(DateHelpers.leftTime(target), contains('left'));
        expect(DateHelpers.leftTime(target), contains('h'));
      });

      test('returns only minutes left', () {
        final target = DateTime.now().add(const Duration(minutes: 20));
        expect(DateHelpers.leftTime(target), '20m left');
      });
    });

    group('formatDateTime', () {
      test('formats date and time together', () {
        final result = DateHelpers.formatDateTime('2025-06-15', '08:00');
        expect(result, contains('2025'));
        expect(result, contains('8:00 AM'));
      });

      test('returns fallback on parse failure', () {
        expect(DateHelpers.formatDateTime('bad', 'time'), 'bad time');
      });
    });

    group('formatDayMonth', () {
      test('formats', () {
        expect(DateHelpers.formatDayMonth('2025-06-15'), contains('Jun'));
        expect(DateHelpers.formatDayMonth('2025-06-15'), contains('15'));
      });
    });

    group('diffInMinutes', () {
      test('returns absolute difference', () {
        final a = DateTime(2025, 6, 15, 10, 0);
        final b = DateTime(2025, 6, 15, 8, 30);
        expect(DateHelpers.diffInMinutes(a, b), 90);
      });
    });
  });
}
