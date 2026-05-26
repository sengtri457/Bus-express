import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String supabaseUrl = dotenv.env['supabaseUrl'] ?? '';
  static String supabaseAnonKey = dotenv.env['supabaseAnonKey'] ?? '';

  static SupabaseClient get client => Supabase.instance.client;

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
        final arrivalTimeStr = schedule['arrival_time'] as String;

        try {
          final parts = arrivalTimeStr.split(':');
          final tripDate = DateTime.parse(tripDateStr);
          final plannedArrival = DateTime(
            tripDate.year,
            tripDate.month,
            tripDate.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );

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
