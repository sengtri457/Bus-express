import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bus_express/core/error/result.dart';
import 'package:bus_express/repositories/trip_repository.dart';
import 'package:bus_express/supabase_config.dart';
import '../helpers/mock_supabase.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSupabaseClient mockClient;
  late TripRepository repo;

  setUp(() {
    mockClient = MockSupabaseClient();
    SupabaseConfig.setTestClient(mockClient);
    repo = TripRepository();
  });

  tearDown(() {
    SupabaseConfig.clearTestClient();
  });

  group('error handling', () {
    test('getDriverTrips returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getDriverTrips('d1'), isA<Failure>());
    });

    test('getConductorTrips returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getConductorTrips('c1'), isA<Failure>());
    });

    test('getActiveTrip returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getActiveTrip('d1'), isA<Failure>());
    });

    test('getTripById returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getTripById('t1'), isA<Failure>());
    });

    test('startTrip returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.startTrip('t1'), isA<Failure>());
    });

    test('endTrip returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.endTrip('t1'), isA<Failure>());
    });

    test('updateLocation returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(
        await repo.updateLocation(tripId: 't1', latitude: 0, longitude: 0),
        isA<Failure>(),
      );
    });

    test('allowConductorStart returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.allowConductorStart('t1'), isA<Failure>());
    });

    test('reportIncident returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(
        await repo.reportIncident(
          tripId: 't1', reportedBy: 'u1',
          type: 'delay', description: 'Traffic',
        ),
        isA<Failure>(),
      );
    });

    test('getLatestIncident returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getLatestIncident('t1'), isA<Failure>());
    });

    test('getBusyTripByScheduleAndDate returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(
        await repo.getBusyTripByScheduleAndDate(
          scheduleId: 's1', tripDate: '2025-01-01',
        ),
        isA<Failure>(),
      );
    });
  });
}
