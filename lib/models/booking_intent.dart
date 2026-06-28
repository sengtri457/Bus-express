import 'dart:convert';

class BookingIntent {
  final String? origin;
  final String? destination;
  final int? passengers;
  final String? dateStr;
  final String? operatorId;
  final String? operatorName;

  const BookingIntent({
    this.origin,
    this.destination,
    this.passengers,
    this.dateStr,
    this.operatorId,
    this.operatorName,
  });

  bool get isComplete => origin != null && destination != null;

  DateTime? resolveDate() {
    if (dateStr == null) return null;
    final trimmed = dateStr!.trim().toLowerCase();
    final now = DateTime.now();

    if (trimmed == 'today') return now;
    if (trimmed == 'tomorrow') return now.add(const Duration(days: 1));
    if (trimmed == 'day after tomorrow') return now.add(const Duration(days: 2));

    try {
      return DateTime.parse(dateStr!);
    } catch (_) {}

    try {
      final parts = dateStr!.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}

    return null;
  }

  static String? _extractBookingJson(String text) {
    final start = text.indexOf('[BOOKING]');
    if (start == -1) return null;
    final end = text.indexOf('[/BOOKING]', start);
    if (end == -1) return null;
    return text.substring(start + 9, end);
  }

  static BookingIntent? tryParse(String text) {
    final jsonStr = _extractBookingJson(text);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return BookingIntent(
        origin: map['origin'] as String?,
        destination: map['destination'] as String?,
        passengers: map['passengers'] as int?,
        dateStr: map['date'] as String?,
        operatorId: map['operator_id'] as String?,
        operatorName: map['operator_name'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static String stripBookingTag(String text) {
    return text.replaceAll(RegExp(r'\[BOOKING\].*?\[/BOOKING\]'), '').trim();
  }
}
