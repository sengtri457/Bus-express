import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bus_express/core/error/result.dart';
import 'package:bus_express/repositories/schedule_repository.dart';
import 'package:bus_express/supabase_config.dart';
import '../helpers/mock_supabase.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSupabaseClient mockClient;
  late ScheduleRepository repo;

  setUp(() {
    mockClient = MockSupabaseClient();
    SupabaseConfig.setTestClient(mockClient);
    repo = ScheduleRepository();
  });

  tearDown(() {
    SupabaseConfig.clearTestClient();
  });

  group('error handling', () {
    test('getSchedulesByRoute returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getSchedulesByRoute('r1'), isA<Failure>());
    });

    test('getActiveSchedules returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getActiveSchedules(), isA<Failure>());
    });

    test('getOperatorSchedules returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getOperatorSchedules('r1'), isA<Failure>());
    });

    test('getDriverSchedules returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getDriverSchedules('d1'), isA<Failure>());
    });
  });
}
