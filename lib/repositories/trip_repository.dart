import '../core/error/result.dart';
import '../models/trip_model.dart';
import '../models/incident_model.dart';
import 'base_repository.dart';

class TripRepository extends BaseRepository {
  TripRepository() : super('trips');

  static const _tripSelect = '''
    id, trip_date, status, departed_at, arrived_at,
    latitude, longitude, conductor_allowed_start,
    schedules (
      id, departure_time, arrival_time, price,
      routes ( id, name, origin, destination, distance_km, duration_min ),
      buses ( id, model, plate_number, capacity )
    )
  ''';

  Future<Result<List<TripModel>>> getDriverTrips(String driverId) async {
    try {
      final data = await client
          .from('trips')
          .select(_tripSelect)
          .eq('driver_id', driverId)
          .order('trip_date', ascending: false);
      return Success(data.map((e) => TripModel.fromMap(e)).toList());
    } catch (e) {
      log('[TripRepo] getDriverTrips error: $e');
      return Failure('Failed to load trips', error: e);
    }
  }

  Future<Result<List<TripModel>>> getConductorTrips(String conductorId) async {
    try {
      final data = await client
          .from('trips')
          .select(_tripSelect)
          .eq('conductor_id', conductorId)
          .order('trip_date', ascending: false);
      return Success(data.map((e) => TripModel.fromMap(e)).toList());
    } catch (e) {
      log('[TripRepo] getConductorTrips error: $e');
      return Failure('Failed to load trips', error: e);
    }
  }

  Future<Result<TripModel?>> getActiveTrip(String driverOrConductorId) async {
    try {
      final data = await client
          .from('trips')
          .select(_tripSelect)
          .or('driver_id.eq.$driverOrConductorId,conductor_id.eq.$driverOrConductorId')
          .inFilter('status', ['scheduled', 'in_progress'])
          .order('trip_date', ascending: true)
          .limit(1)
          .maybeSingle();
      if (data == null) return const Success(null);
      return Success(TripModel.fromMap(data));
    } catch (e) {
      return Failure('Failed to load active trip', error: e);
    }
  }

  Future<Result<TripModel>> getTripById(String tripId) async {
    try {
      final data = await client
          .from('trips')
          .select(_tripSelect)
          .eq('id', tripId)
          .single();
      return Success(TripModel.fromMap(data));
    } catch (e) {
      return Failure('Failed to load trip', error: e);
    }
  }

  Future<Result<void>> startTrip(String tripId) async {
    try {
      final now = DateTime.now().toIso8601String();
      await client
          .from('trips')
          .update({
            'status': 'in_progress',
            'departed_at': now,
          })
          .eq('id', tripId);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to start trip', error: e);
    }
  }

  Future<Result<void>> endTrip(String tripId) async {
    try {
      final now = DateTime.now().toIso8601String();
      await client
          .from('trips')
          .update({
            'status': 'completed',
            'arrived_at': now,
          })
          .eq('id', tripId);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to end trip', error: e);
    }
  }

  Future<Result<void>> updateLocation({
    required String tripId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await client
          .from('trips')
          .update({'latitude': latitude, 'longitude': longitude})
          .eq('id', tripId);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to update location', error: e);
    }
  }

  Future<Result<void>> allowConductorStart(String tripId) async {
    try {
      await client
          .from('trips')
          .update({'conductor_allowed_start': true})
          .eq('id', tripId);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to allow conductor start', error: e);
    }
  }

  Future<Result<void>> reportIncident({
    required String tripId,
    required String reportedBy,
    required String type,
    required String description,
  }) async {
    try {
      await client.from('incidents').insert({
        'trip_id': tripId,
        'reported_by': reportedBy,
        'type': type,
        'description': description,
      });
      return const Success(null);
    } catch (e) {
      return Failure('Failed to report incident', error: e);
    }
  }

  Future<Result<IncidentModel?>> getLatestIncident(String tripId) async {
    try {
      final data = await client
          .from('incidents')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return const Success(null);
      return Success(IncidentModel.fromMap(data));
    } catch (e) {
      return Failure('Failed to get incident', error: e);
    }
  }

  Future<Result<void>> syncOverdueTrips() async {
    try {
      final today = DateTime.now().toLocal().toIso8601String().split('T')[0];
      final now = DateTime.now();

      final trips = await client
          .from('trips')
          .select('''
            id, trip_date, status, departed_at, arrived_at,
            schedules ( departure_time, arrival_time )
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
            final plannedDeparture = DateTime(
              tripDate.year, tripDate.month, tripDate.day,
              int.parse(depParts[0]), int.parse(depParts[1]),
            );
            if (now.isAfter(plannedDeparture)) {
              final nowIso = now.toIso8601String();
              await client
                  .from('trips')
                  .update({'status': 'completed', 'arrived_at': nowIso})
                  .eq('id', trip['id'] as String);
              log('Scheduled trip ${trip['id']} auto-completed');
            }
          } else if (status == 'in_progress') {
            final arrivalParts = arrivalTimeStr.split(':');
            var plannedArrival = DateTime(
              tripDate.year, tripDate.month, tripDate.day,
              int.parse(arrivalParts[0]), int.parse(arrivalParts[1]),
            );
            final depTotal = int.parse(depParts[0]) * 60 + int.parse(depParts[1]);
            final arrTotal = int.parse(arrivalParts[0]) * 60 + int.parse(arrivalParts[1]);
            if (arrTotal < depTotal) {
              plannedArrival = plannedArrival.add(const Duration(days: 1));
            }
            if (now.isAfter(plannedArrival)) {
              final nowIso = now.toIso8601String();
              await client
                  .from('trips')
                  .update({'status': 'completed', 'arrived_at': nowIso})
                  .eq('id', trip['id'] as String);
              log('Trip ${trip['id']} auto-completed');
            }
          }
        } catch (e) {
          log('Error processing trip ${trip['id']}: $e');
        }
      }
      return const Success(null);
    } catch (e) {
      return Failure('Failed to sync overdue trips', error: e);
    }
  }

  Future<Result<TripModel?>> getBusyTripByScheduleAndDate({
    required String scheduleId,
    required String tripDate,
  }) async {
    try {
      final data = await client
          .from('trips')
          .select('id, status')
          .eq('schedule_id', scheduleId)
          .eq('trip_date', tripDate)
          .inFilter('status', ['scheduled', 'in_progress'])
          .limit(1)
          .maybeSingle();
      if (data == null) return const Success(null);
      return Success(TripModel.fromMap(data));
    } catch (e) {
      return Failure('Failed to check busy trip', error: e);
    }
  }
}
