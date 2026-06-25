import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../l10n/tr_extension.dart';
import '../../../services/notification_service.dart';
import '../../../supabase_config.dart';
import 'driver_incident_screen.dart';
import 'trip_punctuality.dart';

class DriverTripScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  const DriverTripScreen({super.key, required this.trip});

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  late Map<String, dynamic> _trip;
  List<Map<String, dynamic>> _passengers = [];
  bool _isLoading = false;
  bool _isTrackingGPS = false;
  Timer? _gpsTimer;
  Position? _currentPosition;
  int _boardedCount = 0;

  // End-trip validation
  List<Map<String, dynamic>> _incidents = [];
  Timer? _endTripTimer;
  bool _canEndTrip = false;
  DateTime? _scheduledArrival;
  DateTime? _adjustedArrival;

  static const Map<String, int> _incidentDelays = {
    'delay': 20,
    'breakdown': 30,
    'accident': 45,
    'other': 15,
  };

  @override
  void initState() {
    super.initState();
    _trip = Map<String, dynamic>.from(widget.trip);
    _refreshTrip();
    _loadPassengers();
    _computeSchedule();
    _loadIncidents();
    _startEndTripCheck();
  }

  Future<void> _refreshTrip() async {
    try {
      final data = await SupabaseConfig.client
          .from('trips')
          .select('''
            id, trip_date, status, departed_at, arrived_at,
            schedules (
              departure_time, arrival_time, price,
              routes ( name, origin, destination, distance_km, duration_min ),
              buses ( model, plate_number, capacity )
            )
          ''')
          .eq('id', _trip['id'])
          .single();
      if (mounted) setState(() => _trip = Map<String, dynamic>.from(data));
    } catch (_) {}
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _endTripTimer?.cancel();
    super.dispose();
  }

  // ─── Time Helpers (shared, no duplication) ───────────────

  static String formatTime(String t) {
    if (t.isEmpty) return '';
    final p = t.split(':');
    final h = int.parse(p[0]);
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${p[1]} $period';
  }

  static String formatIsoTimestamp(String ts) {
    final dt = DateTime.parse(ts).toLocal();
    return formatTime('${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}');
  }

  static String formatDate(String d) {
    final dt = DateTime.parse(d);
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${w[dt.weekday - 1]}, ${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  static int _minuteOfDay(String timeStr) {
    final p = timeStr.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static DateTime _parseScheduleTime(String dateStr, String timeStr, {String? departureTimeStr}) {
    final parts = timeStr.split(':');
    final date = DateTime.parse(dateStr);
    var dt = DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
    if (departureTimeStr != null && _minuteOfDay(timeStr) < _minuteOfDay(departureTimeStr)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  // ─── Schedule & Incident Logic ──────────────────────────

  void _computeSchedule() {
    final schedule = _trip['schedules'] as Map<String, dynamic>?;
    if (schedule == null) return;
    final arrivalStr = schedule['arrival_time'] as String?;
    final depStr = schedule['departure_time'] as String?;
    final dateStr = _trip['trip_date'] as String?;
    if (arrivalStr == null || dateStr == null) return;
    _scheduledArrival = _parseScheduleTime(dateStr, arrivalStr, departureTimeStr: depStr);
    _updateAdjustedArrival();
  }

  void _updateAdjustedArrival() {
    if (_scheduledArrival == null) return;
    _adjustedArrival = _scheduledArrival!.add(Duration(minutes: _totalDelay));
  }

  int get _totalDelay {
    int total = 0;
    for (final inc in _incidents) {
      final type = inc['type'] as String? ?? 'other';
      total += _incidentDelays[type] ?? 15;
    }
    return total;
  }

  Future<void> _loadIncidents() async {
    try {
      final data = await SupabaseConfig.client
          .from('incidents')
          .select('type, created_at')
          .eq('trip_id', _trip['id'])
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _incidents = List<Map<String, dynamic>>.from(data);
          _updateAdjustedArrival();
        });
      }
    } catch (_) {}
  }

  void _startEndTripCheck() {
    _checkEndTrip();
    _endTripTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkEndTrip());
  }

  void _checkEndTrip() {
    if (_status != 'in_progress' || _adjustedArrival == null) {
      if (_canEndTrip && mounted) setState(() => _canEndTrip = false);
      return;
    }
    final canEnd = DateTime.now().isAfter(_adjustedArrival!);
    if (canEnd != _canEndTrip && mounted) {
      setState(() => _canEndTrip = canEnd);
    }
  }

  String get _endTripCountdown {
    if (_adjustedArrival == null || _canEndTrip) return '';
    final remaining = _adjustedArrival!.difference(DateTime.now());
    if (remaining.isNegative) return '';
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String get _status => _trip['status'] as String? ?? 'scheduled';
  bool get _isInProgress => _status == 'in_progress';
  bool get _isScheduled => _status == 'scheduled';

  // ─── Passengers ─────────────────────────────────────────

  Future<void> _loadPassengers() async {
    try {
      final data = await SupabaseConfig.client
          .from('bookings')
          .select('''
            id, seat_number, status,
            users!bookings_passenger_id_fkey ( name, phone ),
            tickets ( qr_code, status )
          ''')
          .eq('trip_id', _trip['id'])
          .inFilter('status', ['confirmed', 'boarded', 'pending']);

      if (mounted) {
        setState(() {
          _passengers = List<Map<String, dynamic>>.from(data);
          _boardedCount = _passengers
              .where((p) => p['status'] == 'boarded')
              .length;
        });
      }
    } catch (e) {
      debugPrint('Error loading passengers: $e');
    }
  }

  // ─── Trip Actions ───────────────────────────────────────

  Future<void> _startTrip() async {
    final confirm = await _showConfirmDialog(
      title: context.tr.driverTripStartDialogTitle,
      message: context.tr.driverTripStartDialogMessage,
      confirmLabel: context.tr.driverTripStartNowLabel,
      confirmColor: const Color(0xFF10B981),
    );
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      final tripData = await SupabaseConfig.client
          .from('trips')
          .select('conductor_allowed_start')
          .eq('id', _trip['id'] as String)
          .single();

      final allowedByConductor = tripData['conductor_allowed_start'] == true;

      final scheduleInfo = _trip['schedules'] as Map<String, dynamic>?;
      final busInfo = scheduleInfo?['buses'] as Map<String, dynamic>?;

      int capacity = 0;
      final rawCap = busInfo?['capacity'];
      if (rawCap is int) capacity = rawCap;
      else if (rawCap is num) capacity = rawCap.toInt();
      else if (rawCap is String) capacity = int.tryParse(rawCap) ?? 0;

      final isFull = capacity > 0 && _boardedCount >= capacity;

      if (!isFull && !allowedByConductor) {
        _showSnackBar(context.tr.driverTripBusNotFull(_boardedCount, capacity), Colors.red);
        return;
      }

      double? initialLat;
      double? initialLng;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        initialLat = position.latitude;
        initialLng = position.longitude;
        if (mounted) setState(() => _currentPosition = position);
      } catch (e) {
        debugPrint('GPS initial fix error: $e');
      }

      final updatePayload = <String, dynamic>{
        'status': 'in_progress',
        'departed_at': DateTime.now().toIso8601String(),
      };
      if (initialLat != null && initialLng != null) {
        updatePayload['latitude'] = initialLat;
        updatePayload['longitude'] = initialLng;
      }
      await SupabaseConfig.client
          .from('trips')
          .update(updatePayload)
          .eq('id', _trip['id']);

      if (initialLat != null && initialLng != null) {
        final driverId = SupabaseConfig.client.auth.currentUser?.id;
        if (driverId != null) {
          await SupabaseConfig.client.from('driver_locations').upsert({
            'driver_id': driverId,
            'latitude': initialLat,
            'longitude': initialLng,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'trip_id': _trip['id'],
            'heading': _currentPosition?.heading ?? 0.0,
            'speed': _currentPosition?.speed ?? 0.0,
          });

          try {
            final profile = await SupabaseConfig.client
                .from('users')
                .select('operator_id, name')
                .eq('id', driverId)
                .single();
            final operatorId = profile['operator_id'];
            final driverName = profile['name'] ?? 'Driver';

            if (operatorId != null) {
              final admins = await SupabaseConfig.client
                  .from('users')
                  .select('id')
                  .eq('operator_id', operatorId)
                  .eq('role', 'operator_admin');

              for (final admin in admins) {
                final adminId = admin['id'] as String?;
                if (adminId != null) {
                  await SupabaseConfig.client.from('notifications').insert({
                    'user_id': adminId,
                    'title': 'Trip Started',
                    'body': '$driverName has started their scheduled trip.',
                    'type': 'trip_started',
                    'reference_type': 'trip',
                    'reference_id': _trip['id'],
                    'created_at': DateTime.now().toIso8601String(),
                  });
                }
              }
            }
          } catch (e) {
            debugPrint('Failed to insert operator notification: $e');
          }
        }
      }

      setState(() {
        _trip['status'] = 'in_progress';
        _trip['departed_at'] = DateTime.now().toIso8601String();
      });

      _startGPSTracking();
      _showSnackBar(context.tr.driverTripStartedSnack, Colors.green);

      unawaited(_notifyPassengersTripStarted());
    } catch (e) {
      _showSnackBar(context.tr.driverTripFailedStart(e.toString()), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _endTrip() async {
    if (!_canEndTrip && _adjustedArrival != null) {
      _showSnackBar(
        context.tr.driverTripWaitCountdown(
          formatIsoTimestamp(_adjustedArrival!.toIso8601String()),
          _endTripCountdown,
        ),
        Colors.orange,
      );
      return;
    }

    final message = _totalDelay > 0
        ? context.tr.driverTripEndDialogMessageDelay(_totalDelay)
        : context.tr.driverTripEndDialogMessageNormal;

    final confirm = await _showConfirmDialog(
      title: context.tr.driverTripEndDialogTitle,
      message: message,
      confirmLabel: context.tr.driverTripEndTripLabel,
      confirmColor: const Color(0xFF1A73E8),
    );
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseConfig.client
          .from('trips')
          .update({
            'status': 'completed',
            'arrived_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _trip['id']);

      final driverId = SupabaseConfig.client.auth.currentUser?.id;
      if (driverId != null) {
        try {
          final profile = await SupabaseConfig.client
              .from('users')
              .select('operator_id, name')
              .eq('id', driverId)
              .single();
          final operatorId = profile['operator_id'];
          final driverName = profile['name'] ?? 'Driver';

          if (operatorId != null) {
            final admins = await SupabaseConfig.client
                .from('users')
                .select('id')
                .eq('operator_id', operatorId)
                .eq('role', 'operator_admin');

            for (final admin in admins) {
              final adminId = admin['id'] as String?;
              if (adminId != null) {
                await SupabaseConfig.client.from('notifications').insert({
                  'user_id': adminId,
                  'title': 'Trip Completed',
                  'body': '$driverName has successfully completed their trip.',
                  'type': 'trip_completed',
                  'reference_type': 'trip',
                  'reference_id': _trip['id'],
                  'created_at': DateTime.now().toIso8601String(),
                });
              }
            }
          }
        } catch (e) {
          debugPrint('Failed to insert operator notification: $e');
        }
      }

      _stopGPSTracking();

      setState(() {
        _trip['status'] = 'completed';
        _trip['arrived_at'] = DateTime.now().toIso8601String();
      });

      _showSnackBar(context.tr.driverTripCompletedSnack, Colors.green);
    } catch (e) {
      _showSnackBar(context.tr.driverTripFailedEnd(e.toString()), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── GPS ────────────────────────────────────────────────

  void _startGPSTracking() {
    setState(() => _isTrackingGPS = true);
    _gpsTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await SupabaseConfig.client
            .from('trips')
            .update({
              'latitude': position.latitude,
              'longitude': position.longitude,
            })
            .eq('id', _trip['id']);

        final driverId = SupabaseConfig.client.auth.currentUser?.id;
        if (driverId != null) {
          await SupabaseConfig.client.from('driver_locations').upsert({
            'driver_id': driverId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'trip_id': _trip['id'],
            'heading': position.heading,
            'speed': position.speed,
          });
        }

        if (mounted) setState(() => _currentPosition = position);
      } catch (e) {
        debugPrint('GPS error: $e');
      }
    });
  }

  void _stopGPSTracking() {
    _gpsTimer?.cancel();
    setState(() => _isTrackingGPS = false);
  }

  Future<void> _notifyPassengersTripStarted() async {
    try {
      final bookings = await SupabaseConfig.client
          .from('bookings')
          .select('passenger_id')
          .eq('trip_id', _trip['id'])
          .eq('status', 'confirmed');

      final schedule = _trip['schedules'] as Map<String, dynamic>?;
      final route = schedule?['routes'] as Map<String, dynamic>?;
      final origin = route?['origin'] as String? ?? context.tr.driverTripNA;
      final destination = route?['destination'] as String? ?? context.tr.driverTripNA;

      final passengerIds = <String>{};
      for (final b in bookings) {
        final pid = b['passenger_id'] as String?;
        if (pid != null) passengerIds.add(pid);
      }

      for (final uid in passengerIds) {
        await NotificationService.instance.insertNotification(
          userId: uid,
          title: context.tr.driverTripNotificationTitle,
          body: context.tr.driverTripNotificationBody(origin, destination),
          type: 'trip_started',
          referenceType: 'trip',
          referenceId: _trip['id'] as String?,
        );
      }
    } catch (e) {
      debugPrint('[Notify] Failed to notify passengers: $e');
    }
  }

  // ─── UI Helpers ─────────────────────────────────────────

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr.driverTripCancel, style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final schedule = _trip['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;
    final bus = schedule?['buses'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(context.tr.driverTripAppBarTitle, style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded),
            tooltip: context.tr.driverTripReportIncident,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverIncidentScreen(tripId: _trip['id'] as String),
                ),
              );
              _loadIncidents();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPassengers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TripStatusCard(
                trip: _trip,
                isTrackingGPS: _isTrackingGPS,
                currentPosition: _currentPosition,
              ),
              const SizedBox(height: 10),
              _ScheduleAdherenceCard(trip: _trip),
              const SizedBox(height: 16),
              _InfoCard(
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.route_rounded,
                      label: context.tr.driverTripRouteLabel,
                      value: '${route?['origin']} → ${route?['destination']}',
                    ),
                    const Divider(height: 20, color: Color(0xFFF3F4F6)),
                    _InfoRow(
                      icon: Icons.access_time_rounded,
                      label: context.tr.departureLabel,
                      value: formatTime(schedule?['departure_time'] ?? ''),
                    ),
                    const Divider(height: 20, color: Color(0xFFF3F4F6)),
                    _InfoRow(
                      icon: Icons.directions_bus_outlined,
                      label: context.tr.driverTripBusLabel,
                      value: '${bus?['model']} • ${bus?['plate_number']}',
                    ),
                    const Divider(height: 20, color: Color(0xFFF3F4F6)),
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: context.tr.driverTripDateLabel,
                      value: formatDate(_trip['trip_date'] as String),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Incident delay info
              if (_isInProgress && _totalDelay > 0)
                _DelayInfoCard(
                  totalDelay: _totalDelay,
                  incidentCount: _incidents.length,
                  adjustedArrival: _adjustedArrival,
                ),
              if (_isInProgress && _totalDelay > 0) const SizedBox(height: 16),

              // GPS Status
              if (_isTrackingGPS)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Text(context.tr.driverTripGpsActive, style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      if (_currentPosition != null)
                        Text(
                          '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(color: Color(0xFF059669), fontSize: 11),
                        ),
                    ],
                  ),
                ),

              // Passenger Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr.driverTripPassengersTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                    child: Text(context.tr.driverTripPassengerCount(_boardedCount, _passengers.length),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1A73E8), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _passengers.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Center(child: Text(context.tr.driverTripNoPassengers, style: const TextStyle(color: Color(0xFF9CA3AF)))),
                    )
                  : Column(children: _passengers.map((p) => _PassengerTile(passenger: p)).toList()),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      bottomNavigationBar: _status == 'completed' || _status == 'cancelled'
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3))],
              ),
              child: _isScheduled
                  ? _ActionButton(
                      label: context.tr.driverTripStartTripBtn,
                      icon: Icons.play_arrow_rounded,
                      color: const Color(0xFF10B981),
                      isLoading: _isLoading,
                      onPressed: _startTrip,
                    )
                  : _buildEndTripButton(),
            ),
    );
  }

  Widget _buildEndTripButton() {
    if (_adjustedArrival == null) {
      return _ActionButton(
        label: context.tr.driverTripEndTripArrivedBtn,
        icon: Icons.flag_rounded,
        color: const Color(0xFF1A73E8),
        isLoading: _isLoading,
        onPressed: _endTrip,
      );
    }

    final label = _canEndTrip
        ? context.tr.driverTripEndTripArrivedBtn
        : context.tr.driverTripEndTripCountdown(_endTripCountdown);

    return _ActionButton(
      label: label,
      icon: Icons.flag_rounded,
      color: _canEndTrip ? const Color(0xFF1A73E8) : const Color(0xFF9CA3AF),
      isLoading: _isLoading,
      onPressed: _canEndTrip ? _endTrip : null,
    );
  }
}

// ─── Trip Status Card ─────────────────────────────────────────────────────────

class _TripStatusCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool isTrackingGPS;
  final Position? currentPosition;

  const _TripStatusCard({required this.trip, required this.isTrackingGPS, required this.currentPosition});

  @override
  Widget build(BuildContext context) {
    final status = trip['status'] as String;
    final configs = {
      'scheduled': [const Color(0xFF1A73E8), Icons.schedule_rounded, context.tr.driverTripStatusReady],
      'in_progress': [const Color(0xFF10B981), Icons.play_circle_rounded, context.tr.driverTripStatusInProgress],
      'completed': [const Color(0xFF6B7280), Icons.check_circle_rounded, context.tr.driverTripStatusCompleted],
      'cancelled': [const Color(0xFFEF4444), Icons.cancel_rounded, context.tr.driverTripStatusCancelled],
    };
    final cfg = configs[status] ?? [const Color(0xFFF59E0B), Icons.pending_rounded, context.tr.driverTripStatusUnknown];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (cfg[0] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (cfg[0] as Color).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (cfg[0] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(cfg[1] as IconData, color: cfg[0] as Color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cfg[2] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cfg[0] as Color)),
                const SizedBox(height: 4),
                Text(
                  status == 'in_progress' && trip['departed_at'] != null
                      ? context.tr.driverTripDepartedAt(formatTimestamp(trip['departed_at']))
                      : status == 'completed' && trip['arrived_at'] != null
                      ? context.tr.driverTripArrivedAt(formatTimestamp(trip['arrived_at']))
                      : context.tr.driverTripTapStart,
                  style: TextStyle(fontSize: 12, color: (cfg[0] as Color).withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String formatTimestamp(String ts) {
    final dt = DateTime.parse(ts).toLocal();
    final h = dt.hour;
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}

// ─── Delay Info Card ──────────────────────────────────────────────────────────

class _DelayInfoCard extends StatelessWidget {
  final int totalDelay;
  final int incidentCount;
  final DateTime? adjustedArrival;

  const _DelayInfoCard({required this.totalDelay, required this.incidentCount, this.adjustedArrival});

  @override
  Widget build(BuildContext context) {
    final arrivalStr = adjustedArrival != null
        ? _DriverTripScreenState.formatIsoTimestamp(adjustedArrival!.toIso8601String())
        : '—';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.timer_off_rounded, color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr.driverTripDelayInfo(totalDelay, incidentCount),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                Text(context.tr.driverTripAdjustedEta(arrivalStr),
                  style: const TextStyle(fontSize: 12, color: Color(0xFFA16207))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Passenger Tile ───────────────────────────────────────────────────────────

class _PassengerTile extends StatelessWidget {
  final Map<String, dynamic> passenger;
  const _PassengerTile({required this.passenger});

  @override
  Widget build(BuildContext context) {
    final user = passenger['users'] as Map<String, dynamic>?;
    final status = passenger['status'] as String;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'boarded':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'confirmed':
        statusColor = const Color(0xFF1A73E8);
        statusIcon = Icons.confirmation_number_rounded;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pending_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: statusColor.withOpacity(0.1),
            child: Text(
              (user?['name'] as String? ?? 'P')[0].toUpperCase(),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?['name'] ?? context.tr.driverTripUnknownPassenger,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                Text(context.tr.driverTripSeatInfo('${passenger['seat_number']}', user?['phone'] ?? ''),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(height: 2),
              Text('${status[0].toUpperCase()}${status.substring(1)}',
                style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? const Color(0xFFD1D5DB) : color,
          foregroundColor: disabled ? const Color(0xFF9CA3AF) : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ─── Schedule Adherence Card ──────────────────────────────────────────────────

class _ScheduleAdherenceCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _ScheduleAdherenceCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final punctuality = TripPunctuality.calculate(trip, context);
    final schedule = trip['schedules'] as Map<String, dynamic>?;
    final departureTimeStr = schedule?['departure_time'] as String? ?? '--:--';
    final arrivalTimeStr = schedule?['arrival_time'] as String? ?? '--:--';
    final departedAt = trip['departed_at'] as String?;
    final arrivedAt = trip['arrived_at'] as String?;
    final status = trip['status'] as String? ?? 'scheduled';

    return Container(
      decoration: BoxDecoration(
        color: punctuality.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: punctuality.color.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: punctuality.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(punctuality.icon, color: punctuality.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(punctuality.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: punctuality.color)),
                    Text(punctuality.message, style: TextStyle(fontSize: 12, color: punctuality.color.withOpacity(0.8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _TimelineCompare(
                label: context.tr.departureLabel,
                scheduled: _fmtScheduleTime(departureTimeStr),
                actual: departedAt != null ? _fmtIso(departedAt) : null,
                isMissed: status == 'scheduled' && _isOverdue(trip['trip_date'] as String? ?? '', departureTimeStr),
              )),
              Container(width: 1, height: 50, color: const Color(0xFFE5E7EB), margin: const EdgeInsets.symmetric(horizontal: 14)),
              Expanded(child: _TimelineCompare(
                label: context.tr.arrivalLabel,
                scheduled: _fmtScheduleTime(arrivalTimeStr),
                actual: arrivedAt != null ? _fmtIso(arrivedAt) : null,
                isMissed: status == 'in_progress' &&
                    _isOverdue(trip['trip_date'] as String? ?? '', arrivalTimeStr, departureTimeStr: departureTimeStr),
              )),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtScheduleTime(String t) {
    if (t.isEmpty) return '--:--';
    return _DriverTripScreenState.formatTime(t);
  }

  static String _fmtIso(String iso) {
    return _DriverTripScreenState.formatIsoTimestamp(iso);
  }

  static bool _isOverdue(String dateStr, String timeStr, {String? departureTimeStr}) {
    try {
      final planned = _DriverTripScreenState._parseScheduleTime(dateStr, timeStr, departureTimeStr: departureTimeStr);
      return DateTime.now().isAfter(planned.add(const Duration(minutes: 5)));
    } catch (_) {
      return false;
    }
  }
}

class _TimelineCompare extends StatelessWidget {
  final String label;
  final String scheduled;
  final String? actual;
  final bool isMissed;

  const _TimelineCompare({required this.label, required this.scheduled, this.actual, this.isMissed = false});

  @override
  Widget build(BuildContext context) {
    final hasActual = actual != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Text(scheduled,
              style: TextStyle(fontSize: 12,
                color: isMissed ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
                decoration: hasActual ? TextDecoration.lineThrough : null,
                decorationColor: const Color(0xFF9CA3AF),
              )),
          ],
        ),
        if (hasActual) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF16A34A)),
              const SizedBox(width: 4),
              Text(actual!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
            ],
          ),
        ] else if (isMissed) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 12, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Text(context.tr.driverTripOverdue, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
            ],
          ),
        ],
      ],
    );
  }
}
