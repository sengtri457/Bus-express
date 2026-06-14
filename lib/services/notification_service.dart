import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  factory NotificationService() => _instance;

  FlutterLocalNotificationsPlugin? _plugin;
  RealtimeChannel? _channel;
  bool _initialized = false;
  String? _currentUserId;
  Timer? _departureTimer;
  final Set<String> _notifiedDepartureIds = {};

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  void Function(String? type, String? referenceType, String? referenceId)?
      onNotificationTap;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _plugin = FlutterLocalNotificationsPlugin();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin!.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidPlugin = _plugin!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'bus_express_channel',
        'Trip Updates',
        description: 'Booking confirmations, trip alerts, and updates',
        importance: Importance.high,
        playSound: true,
      ),
    );

    await androidPlugin?.requestNotificationsPermission();

    Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      final user = authState.session?.user;
      if (user != null) {
        _subscribe(user.id);
      } else {
        _unsubscribe();
      }
    });

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      _subscribe(currentUser.id);
    }
  }

  /// Call this from screens that want fresh data on mount or page focus.
  Future<void> refreshUnreadCount() => _fetchUnreadCount();

  Future<void> refreshUpcomingDepartures() => checkUpcomingDepartures();

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      onNotificationTap?.call(
        data['type'] as String?,
        data['reference_type'] as String?,
        data['reference_id'] as String?,
      );
    } catch (_) {}
  }

  void _subscribe(String userId) {
    _unsubscribe();
    _currentUserId = userId;
    _fetchUnreadCount();
    checkUpcomingDepartures();

    // Check for upcoming departures every 60 seconds while app is alive
    _departureTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      checkUpcomingDepartures();
    });

    _channel = Supabase.instance.client.channel('notifications:$userId');

    _channel!
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          final record = payload.newRecord;
          final recordUserId = record['user_id'] as String?;
          if (recordUserId != userId) return;

          unreadCount.value++;

          _showLocalNotification(
            id: record['id'] as String,
            title: record['title'] as String,
            body: record['body'] as String,
            type: (record['type'] as String?) ?? 'general',
            referenceType: record['reference_type'] as String?,
            referenceId: record['reference_id'] as String?,
          );
        },
      )
      .subscribe();
  }

  void _unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
    _departureTimer?.cancel();
    _departureTimer = null;
    _currentUserId = null;
    unreadCount.value = 0;
  }

  Future<void> _fetchUnreadCount() async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      final count = await Supabase.instance.client
          .from('notifications')
          .count(CountOption.exact)
          .eq('user_id', uid)
          .eq('is_read', false);
      unreadCount.value = count;
    } catch (_) {}
  }

  /// Check confirmed bookings and notify if departure is within 30 minutes.
  @visibleForTesting
  Future<void> checkUpcomingDepartures() async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];

      final bookings = await Supabase.instance.client
          .from('bookings')
          .select('''
            id, seat_number,
            trips ( trip_date, schedules ( departure_time ) )
          ''')
          .eq('passenger_id', uid)
          .eq('status', 'confirmed')
          .gte('trips.trip_date', today);

      for (final booking in bookings) {
        final bookingId = booking['id'] as String?;
        if (bookingId == null || _notifiedDepartureIds.contains(bookingId)) {
          continue;
        }

        final trip = booking['trips'] as Map<String, dynamic>?;
        if (trip == null) continue;

        final tripDate = trip['trip_date'] as String?;
        final schedule = trip['schedules'] as Map<String, dynamic>?;
        final depTime = schedule?['departure_time'] as String?;
        if (tripDate == null || depTime == null) continue;

        final dateParts = tripDate.split('-');
        final timeParts = depTime.split(':');
        if (dateParts.length < 3 || timeParts.length < 2) continue;

        final departure = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        if (departure.isBefore(now)) continue;

        final diff = departure.difference(now);
        if (diff.inMinutes > 30) continue;

        _notifiedDepartureIds.add(bookingId);

        final depDisplay =
            '${int.parse(timeParts[0]) > 12 ? int.parse(timeParts[0]) - 12 : (int.parse(timeParts[0]) == 0 ? 12 : int.parse(timeParts[0]))}:${timeParts[1]} ${int.parse(timeParts[0]) >= 12 ? 'PM' : 'AM'}';

        await insertNotification(
          userId: uid,
          title: 'Departure Soon',
          body:
              'Your bus departs in ${diff.inMinutes} min at $depDisplay. Please be at the terminal.',
          type: 'departure_reminder',
          referenceType: 'booking',
          referenceId: bookingId,
        );
      }
    } catch (_) {}
  }

  Future<void> _showLocalNotification({
    required String id,
    required String title,
    required String body,
    String type = 'general',
    String? referenceType,
    String? referenceId,
  }) async {
    if (_plugin == null) return;

    final payload = jsonEncode({
      'type': type,
      'reference_type': referenceType,
      'reference_id': referenceId,
    });

    final androidDetails = AndroidNotificationDetails(
      'bus_express_channel',
      'Trip Updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    try {
      await _plugin!.show(
        id.hashCode,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );
    } catch (_) {}
  }

  Future<void> insertNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? referenceType,
    String? referenceId,
  }) async {
    await Supabase.instance.client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'reference_type': referenceType,
      'reference_id': referenceId,
    });
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final uid = _currentUserId;
    if (uid == null) return [];
    try {
      final data = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
    if (unreadCount.value > 0) unreadCount.value--;
  }

  void dispose() {
    _unsubscribe();
  }
}
