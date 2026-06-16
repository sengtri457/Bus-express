import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error/result.dart';
import '../models/notification_model.dart';
import 'base_repository.dart';

class NotificationRepository extends BaseRepository {
  NotificationRepository() : super('notifications');

  Future<Result<List<NotificationItem>>> getNotifications(String userId) async {
    try {
      final data = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return Success(
        data.map((e) => NotificationItem.fromMap(e)).toList(),
      );
    } catch (e) {
      return Failure('Failed to load notifications', error: e);
    }
  }

  Future<Result<int>> getUnreadCount(String userId) async {
    try {
      final count = await client
          .from('notifications')
          .count(CountOption.exact)
          .eq('user_id', userId)
          .eq('is_read', false);
      return Success(count);
    } catch (e) {
      return Failure('Failed to get unread count', error: e);
    }
  }

  Future<Result<void>> markAsRead(String notificationId, String userId) async {
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to mark as read', error: e);
    }
  }

  Future<Result<void>> insertNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? referenceType,
    String? referenceId,
  }) async {
    try {
      await client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'reference_type': referenceType,
        'reference_id': referenceId,
      });
      return const Success(null);
    } catch (e) {
      return Failure('Failed to insert notification', error: e);
    }
  }
}
