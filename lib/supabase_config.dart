import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String supabaseUrl = dotenv.env['supabaseUrl'] ?? '';
  static String supabaseAnonKey = dotenv.env['supabaseAnonKey'] ?? '';

  // Bakong KHQR
  static String get bakongAccountId => dotenv.env['BAKONG_ACCOUNT_ID'] ?? '';
  static String get bakongMerchantName =>
      dotenv.env['BAKONG_MERCHANT_NAME'] ?? 'Bus Express';
  static bool get isBakongConfigured => bakongAccountId.isNotEmpty;
  static String get bakongAccessToken =>
      dotenv.env['BAKONG_ACCESS_TOKEN'] ?? '';
  static String get bakongApiUrl =>
      dotenv.env['BAKONG_API_URL'] ?? 'https://api-bakong.nbc.gov.kh';

  static SupabaseClient? _testClient;

  /// Override client for testing. Never use in production.
  @visibleForTesting
  static void setTestClient(SupabaseClient client) {
    _testClient = client;
  }

  @visibleForTesting
  static void clearTestClient() {
    _testClient = null;
  }

  static SupabaseClient get client => _testClient ?? Supabase.instance.client;

  static String get storageUrl => '$supabaseUrl/storage/v1/object/public';

  /// Automatically updates status to 'completed' for trips whose scheduled time has passed.
  /// - Scheduled (not started): auto-completes when departure time is over.
  /// - In progress: auto-completes when arrival time is over.
  static Future<void> syncOverdueTrips() async {
    try {
      final today = DateTime.now().toLocal().toIso8601String().split('T')[0];
      final now = DateTime.now();

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

      for (final trip in trips) {
        final schedule = trip['schedules'] as Map<String, dynamic>?;
        if (schedule == null) continue;

        final tripDateStr = trip['trip_date'] as String;
        final departureTimeStr = schedule['departure_time'] as String?;
        final arrivalTimeStr = schedule['arrival_time'] as String;
        final status = trip['status'] as String;

        if (departureTimeStr == null) continue;

        try {
          final tripDate = DateTime.parse(tripDateStr);
          final depParts = departureTimeStr.split(':');

          if (status == 'scheduled') {
            // Driver never started — auto-complete if departure time is past
            final plannedDeparture = DateTime(
              tripDate.year,
              tripDate.month,
              tripDate.day,
              int.parse(depParts[0]),
              int.parse(depParts[1]),
            );
            if (now.isAfter(plannedDeparture)) {
              final nowIso = now.toIso8601String();
              await client
                  .from('trips')
                  .update({'status': 'completed', 'arrived_at': nowIso})
                  .eq('id', trip['id'] as String);
              debugPrint(
                '[TripAutoEnd] Scheduled trip ${trip['id']} auto-completed. '
                'Departure was $plannedDeparture',
              );
            }
          } else if (status == 'in_progress') {
            // Trip underway — auto-complete if arrival time is past
            final arrivalParts = arrivalTimeStr.split(':');
            var plannedArrival = DateTime(
              tripDate.year,
              tripDate.month,
              tripDate.day,
              int.parse(arrivalParts[0]),
              int.parse(arrivalParts[1]),
            );

            final depTotal =
                int.parse(depParts[0]) * 60 + int.parse(depParts[1]);
            final arrTotal =
                int.parse(arrivalParts[0]) * 60 + int.parse(arrivalParts[1]);
            if (arrTotal < depTotal) {
              plannedArrival = plannedArrival.add(const Duration(days: 1));
            }

            if (now.isAfter(plannedArrival)) {
              final nowIso = now.toIso8601String();
              await client
                  .from('trips')
                  .update({'status': 'completed', 'arrived_at': nowIso})
                  .eq('id', trip['id'] as String);
              debugPrint(
                '[TripAutoEnd] Trip ${trip['id']} auto-completed. '
                'Arrival was $plannedArrival',
              );
            }
          }
        } catch (e) {
          debugPrint('[TripAutoEnd] Error processing trip ${trip['id']}: $e');
        }
      }
    } catch (e) {
      debugPrint('[TripAutoEnd] Error syncing overdue trips: $e');
    }
  }
}
