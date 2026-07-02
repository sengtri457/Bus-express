import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bus_express/core/error/result.dart';
import 'package:bus_express/repositories/notification_repository.dart';
import 'package:bus_express/supabase_config.dart';
import '../helpers/mock_supabase.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSupabaseClient mockClient;
  late NotificationRepository repo;

  setUp(() {
    mockClient = MockSupabaseClient();
    SupabaseConfig.setTestClient(mockClient);
    repo = NotificationRepository();
  });

  tearDown(() {
    SupabaseConfig.clearTestClient();
  });

  group('error handling', () {
    test('getNotifications returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getNotifications('u1'), isA<Failure>());
    });

    test('getUnreadCount returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.getUnreadCount('u1'), isA<Failure>());
    });

    test('markAsRead returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(await repo.markAsRead('n1', 'u1'), isA<Failure>());
    });

    test('insertNotification returns Failure on error', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('err'));
      expect(
        await repo.insertNotification(
          userId: 'u1', title: 'T', body: 'B',
        ),
        isA<Failure>(),
      );
    });
  });
}
