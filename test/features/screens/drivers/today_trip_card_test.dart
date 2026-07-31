import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bus_express/features/screens/drivers/widgets/today_trip_card.dart';
import 'package:bus_express/l10n/app_localizations.dart';

Map<String, dynamic> _buildTrip() {
  final now = DateTime.now();
  final dep = now.subtract(const Duration(minutes: 30));
  final arr = now.add(const Duration(hours: 2));
  String two(int n) => n.toString().padLeft(2, '0');
  return {
    'id': 'trip-1',
    'status': 'scheduled',
    'trip_date': now.toIso8601String().split('T').first,
    'schedules': {
      'departure_time': '${two(dep.hour)}:${two(dep.minute)}',
      'arrival_time': '${two(arr.hour)}:${two(arr.minute)}',
      'routes': {
        'origin': 'Phnom Penh',
        'destination': 'Siem Reap',
        'duration_min': 120,
        'distance_km': 300,
      },
      'buses': {
        'model': 'HINO',
        'plate_number': 'PP-1234',
        'capacity': 45,
      },
    },
  };
}

void main() {
  testWidgets('TodayTripCard does not overflow at narrow widths', (tester) async {
    for (final width in [320.0, 280.0, 240.0]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('km'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: TodayTripCard(trip: _buildTrip(), onTap: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'overflow at card width $width',
      );
    }
  });
}
