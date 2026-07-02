import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bus_express/core/error/result.dart';
import 'package:bus_express/repositories/review_repository.dart';
import 'package:bus_express/supabase_config.dart';
import '../helpers/mock_supabase.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSupabaseClient mockClient;
  late ReviewRepository repo;

  setUp(() {
    mockClient = MockSupabaseClient();
    SupabaseConfig.setTestClient(mockClient);
    repo = ReviewRepository();
  });

  tearDown(() {
    SupabaseConfig.clearTestClient();
  });

  group('error handling', () {
    test('createReview returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(
        await repo.createReview(
          bookingId: 'b1', tripId: 't1', userId: 'u1', rating: 5,
        ),
        isA<Failure>(),
      );
    });

    test('getBookingReview returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getBookingReview('b1'), isA<Failure>());
    });

    test('getTripReviewByUser returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(
        await repo.getTripReviewByUser(tripId: 't1', userId: 'u1'),
        isA<Failure>(),
      );
    });

    test('getDriverReviews returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getDriverReviews(driverId: 'd1'), isA<Failure>());
    });

    test('getDriverAverageRating returns Failure on rpc error', () async {
      when(() => mockClient.rpc(any(), params: any(named: 'params')))
          .thenThrow(Exception('err'));
      expect(await repo.getDriverAverageRating('d1'), isA<Failure>());
    });
  });
}
