import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bus_express/core/error/result.dart';
import 'package:bus_express/repositories/user_repository.dart';
import 'package:bus_express/supabase_config.dart';
import '../helpers/mock_supabase.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSupabaseClient mockClient;
  late UserRepository repo;

  setUp(() {
    mockClient = MockSupabaseClient();
    SupabaseConfig.setTestClient(mockClient);
    repo = UserRepository();
  });

  tearDown(() {
    SupabaseConfig.clearTestClient();
  });

  group('error handling', () {
    test('getCurrentUser returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getCurrentUser('u1'), isA<Failure>());
    });

    test('updateProfile returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(
        await repo.updateProfile(userId: 'u1', name: 'N'),
        isA<Failure>(),
      );
    });

    test('getStaffByOperator returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getStaffByOperator('op1'), isA<Failure>());
    });

    test('getAllUsers returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getAllUsers(), isA<Failure>());
    });

    test('updateUserStatus returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.updateUserStatus('u1', 'suspended'), isA<Failure>());
    });
  });
}
