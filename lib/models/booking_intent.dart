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

  BookingIntent copyWith({
    String? origin,
    String? destination,
    int? passengers,
    String? dateStr,
  }) {
    return BookingIntent(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      passengers: passengers ?? this.passengers,
      dateStr: dateStr ?? this.dateStr,
    );
  }

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
      final parts2 = dateStr!.split('/');
      if (parts2.length == 3) {
        return DateTime(int.parse(parts2[2]), int.parse(parts2[1]), int.parse(parts2[0]));
      }
    } catch (_) {}

    return null;
  }

  // ── Regex extraction from user messages ──

  static const _knownCities = [
    'Phnom Penh', 'Siem Reap', 'Sihanoukville',
    'Battambang', 'Kampot', 'Kep', 'Kratie',
  ];

  static final _routeWithPassengersPattern = RegExp(
    r'([A-Za-z][A-Za-z\s]*?)\s+(?:to|→|->|-|–)\s+([A-Za-z][A-Za-z\s]*?)\s+(?:for|with)\s+(\d+)',
    caseSensitive: false,
  );

  static final _bookRoutePattern = RegExp(
    r'(?:book|need|want|get|reserve)\s+.*?([A-Za-z][A-Za-z\s]*?)\s+(?:to|→|->|-|–)\s+([A-Za-z][A-Za-z\s]*?)(?:\s|\,|\.|$)',
    caseSensitive: false,
  );

  static final _routeSimplePattern = RegExp(
    r'([A-Za-z][A-Za-z\s]*?)\s+(?:to|→|->|-|–)\s+([A-Za-z][A-Za-z\s]*?)$',
    caseSensitive: false,
  );

  static final _passengerPattern = RegExp(
    r'(\d+)\s*(?:people|person|passenger|tickets?|seat|pax)',
    caseSensitive: false,
  );

  static final _dateWordPattern = RegExp(
    r'\b(today|tomorrow|tonight|day after tomorrow)\b',
    caseSensitive: false,
  );

  static final _dayPattern = RegExp(
    r'\b(this|next|on)\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    caseSensitive: false,
  );

  static final _datePattern = RegExp(
    r'\b(\d{1,2}[/-]\d{1,2}([/-]\d{2,4})?)\b',
  );

  static String? _matchCity(RegExpMatch match, int group) {
    final raw = match.group(group)?.trim();
    if (raw == null) return null;
    for (final city in _knownCities) {
      if (raw.toLowerCase() == city.toLowerCase()) return city;
    }
    for (final city in _knownCities) {
      if (city.toLowerCase().contains(raw.toLowerCase()) ||
          raw.toLowerCase().contains(city.toLowerCase())) {
        return city;
      }
    }
    return null;
  }

  static String? extractDate(String text) {
    final lower = text.toLowerCase();
    final wordMatch = _dateWordPattern.firstMatch(lower);
    if (wordMatch != null) return wordMatch.group(1);

    final dayMatch = _dayPattern.firstMatch(lower);
    if (dayMatch != null) return '${dayMatch.group(1)} ${dayMatch.group(2)}';

    final dateMatch = _datePattern.firstMatch(text);
    if (dateMatch != null) return dateMatch.group(1);

    return null;
  }

  static int? _extractPassengers(String text) {
    final match = _passengerPattern.firstMatch(text);
    if (match != null) return int.tryParse(match.group(1) ?? '');
    return null;
  }

  static BookingIntent? extractFromUserMessage(String text) {
    final lower = text.trim();

    // 1. Structured: "[city] to [city] for [N] [people]"
    final routePassMatch = _routeWithPassengersPattern.firstMatch(lower);
    if (routePassMatch != null) {
      final origin = _matchCity(routePassMatch, 1);
      final dest = _matchCity(routePassMatch, 2);
      if (origin != null && dest != null) {
        return BookingIntent(
          origin: origin,
          destination: dest,
          passengers: int.tryParse(routePassMatch.group(3) ?? ''),
          dateStr: extractDate(lower),
        );
      }
    }

    // 2. "book/need/want [X] [city] to [city]"
    final bookMatch = _bookRoutePattern.firstMatch(lower);
    if (bookMatch != null) {
      final origin = _matchCity(bookMatch, 1);
      final dest = _matchCity(bookMatch, 2);
      if (origin != null && dest != null) {
        return BookingIntent(
          origin: origin,
          destination: dest,
          passengers: _extractPassengers(lower),
          dateStr: extractDate(lower),
        );
      }
    }

    // 3. Simple "[city] to [city]" (no book/for keywords)
    final simpleMatch = _routeSimplePattern.firstMatch(lower);
    if (simpleMatch != null) {
      final origin = _matchCity(simpleMatch, 1);
      final dest = _matchCity(simpleMatch, 2);
      if (origin != null && dest != null) {
        return BookingIntent(
          origin: origin,
          destination: dest,
          passengers: _extractPassengers(lower),
          dateStr: extractDate(lower),
        );
      }
    }

    return null;
  }

  static bool detectDateOnly(String text) {
    final lower = text.trim().toLowerCase();
    if (_dateWordPattern.hasMatch(lower) &&
        !_routeSimplePattern.hasMatch(lower)) {
      return true;
    }
    if (_dayPattern.hasMatch(lower) &&
        !_routeSimplePattern.hasMatch(lower)) {
      return true;
    }
    if (_datePattern.hasMatch(text) &&
        !_routeSimplePattern.hasMatch(lower)) {
      return true;
    }
    return false;
  }

  // ── LLM [BOOKING] tag parsing (fallback) ──

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
