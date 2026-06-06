import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String supabaseUrl = dotenv.env['supabaseUrl'] ?? '';
  static String supabaseAnonKey = dotenv.env['supabaseAnonKey'] ?? '';

  static SupabaseClient get client => Supabase.instance.client;

  static String get storageUrl => '$supabaseUrl/storage/v1/object/public';

  /// Automatically updates status to 'completed' for any trip that is scheduled or in progress
  /// whose scheduled arrival time has already passed.
  static Future<void> syncOverdueTrips() async {
    try {
      final today = DateTime.now().toLocal().toIso8601String().split('T')[0];

      // Query trips that are scheduled or in progress for today or earlier
      final trips = await client
          .from('trips')
          .select('''
            id, trip_date, status, departed_at, arrived_at,
            schedules (
              departure_time, arrival_time
            )
          ''')
          .inFilter('status', ['scheduled', 'in_progress'])
          .lte('trip_date', today);

      final now = DateTime.now();

      for (final trip in trips) {
        final schedule = trip['schedules'] as Map<String, dynamic>?;
        if (schedule == null) continue;

        final tripDateStr = trip['trip_date'] as String;
        final departureTimeStr = schedule['departure_time'] as String?;
        final arrivalTimeStr = schedule['arrival_time'] as String;

        try {
          final arrivalParts = arrivalTimeStr.split(':');
          final tripDate = DateTime.parse(tripDateStr);
          var plannedArrival = DateTime(
            tripDate.year,
            tripDate.month,
            tripDate.day,
            int.parse(arrivalParts[0]),
            int.parse(arrivalParts[1]),
          );

          if (departureTimeStr != null) {
            final depParts = departureTimeStr.split(':');
            final depHours = int.parse(depParts[0]);
            final depMins = int.parse(depParts[1]);
            final arrHours = int.parse(arrivalParts[0]);
            final arrMins = int.parse(arrivalParts[1]);

            final depTotalMinutes = depHours * 60 + depMins;
            final arrTotalMinutes = arrHours * 60 + arrMins;

            if (arrTotalMinutes < depTotalMinutes) {
              // Crossed midnight, arrival is on the next day
              plannedArrival = plannedArrival.add(const Duration(days: 1));
            }
          }

          // If the current time is past the planned arrival time, auto-end the trip
          if (now.isAfter(plannedArrival)) {
            final nowIso = now.toIso8601String();
            await client
                .from('trips')
                .update({'status': 'completed', 'arrived_at': nowIso})
                .eq('id', trip['id'] as String);

            debugPrint(
              '[TripAutoEnd] Trip ${trip['id']} auto-completed. Scheduled arrival was $plannedArrival',
            );
          }
        } catch (e) {
          debugPrint(
            '[TripAutoEnd] Error parsing arrival time for trip ${trip['id']}: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('[TripAutoEnd] Error syncing overdue trips: $e');
    }
  }
}
