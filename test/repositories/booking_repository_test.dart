import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bus_express/core/error/result.dart';
import 'package:bus_express/repositories/booking_repository.dart';
import 'package:bus_express/supabase_config.dart';
import '../helpers/mock_supabase.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSupabaseClient mockClient;
  late BookingRepository repo;

  setUp(() {
    mockClient = MockSupabaseClient();
    SupabaseConfig.setTestClient(mockClient);
    repo = BookingRepository();
  });

  tearDown(() {
    SupabaseConfig.clearTestClient();
  });

  group('getPassengerBookings', () {
    test('returns Failure on query error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('DB error'));

      final result = await repo.getPassengerBookings('u1');
      expect(result, isA<Failure>());
    });
  });

  group('getTripBookings', () {
    test('returns Failure on query error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getTripBookings('t1'), isA<Failure>());
    });
  });

  group('getBookedSeats', () {
    test('returns Failure on query error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getBookedSeats('t1'), isA<Failure>());
    });
  });

  group('createBooking', () {
    test('returns Failure on query error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      final r = await repo.createBooking(
        tripId: 't1', passengerId: 'u1',
        seatNumber: 'A1', totalPrice: 25.0,
      );
      expect(r, isA<Failure>());
    });
  });

  group('cancelBooking', () {
    test('returns Failure on query error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.cancelBooking('b1'), isA<Failure>());
    });
  });

  group('validateBookingCanCancel', () {
    test('returns Failure on query error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.validateBookingCanCancel('b1'), isA<Failure>());
    });
  });
}
