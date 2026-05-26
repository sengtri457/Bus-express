import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  void initState() {
    super.initState();
    _trip = Map<String, dynamic>.from(widget.trip);
    _loadPassengers();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

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

  Future<void> _startTrip() async {
    final confirm = await _showConfirmDialog(
      title: 'Start Trip',
      message: 'Are you ready to depart? This will notify all passengers.',
      confirmLabel: 'Start Now',
      confirmColor: const Color(0xFF10B981),
    );
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      // 1. Fetch conductor permission
      final tripData = await SupabaseConfig.client
          .from('trips')
          .select('conductor_allowed_start')
          .eq('id', _trip['id'] as String)
          .single();

      final allowedByConductor = tripData['conductor_allowed_start'] == true;
      
      // 2. Get capacity from the already loaded _trip data
      final scheduleInfo = _trip['schedules'] as Map<String, dynamic>?;
      final busInfo = scheduleInfo?['buses'] as Map<String, dynamic>?;
      
      int capacity = 0;
      final rawCap = busInfo?['capacity'];
      if (rawCap is int) capacity = rawCap;
      else if (rawCap is num) capacity = rawCap.toInt();
      else if (rawCap is String) capacity = int.tryParse(rawCap) ?? 0;

      // 3. Validation logic
      final isFull = capacity > 0 && _boardedCount >= capacity;
      
      if (!isFull && !allowedByConductor) {
        _showSnackBar('Bus is not full ($_boardedCount/$capacity). Waiting for Conductor permission.', Colors.red);
        return; // Early return, loading state will be reset in finally block
      }

      await SupabaseConfig.client
          .from('trips')
          .update({
            'status': 'in_progress',
            'departed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _trip['id']);

      setState(() {
        _trip['status'] = 'in_progress';
        _trip['departed_at'] = DateTime.now().toIso8601String();
      });

      _startGPSTracking();
      _showSnackBar('Trip started! GPS tracking active.', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to start trip: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _endTrip() async {
    final confirm = await _showConfirmDialog(
      title: 'End Trip',
      message: 'Confirm you have arrived at the destination?',
      confirmLabel: 'End Trip',
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

      _stopGPSTracking();

      setState(() {
        _trip['status'] = 'completed';
        _trip['arrived_at'] = DateTime.now().toIso8601String();
      });

      _showSnackBar('Trip completed successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to end trip: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _trip['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;
    final bus = schedule?['buses'] as Map<String, dynamic>?;
    final status = _trip['status'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Trip Management',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded),
            tooltip: 'Report Incident',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DriverIncidentScreen(tripId: _trip['id'] as String),
              ),
            ),
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
              // Trip Status Card
              _TripStatusCard(
                trip: _trip,
                isTrackingGPS: _isTrackingGPS,
                currentPosition: _currentPosition,
              ),
              const SizedBox(height: 10),

              // Schedule Adherence Card
              _ScheduleAdherenceCard(trip: _trip),
              const SizedBox(height: 16),

              // Route Info
              _InfoCard(
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.route_rounded,
                      label: 'Route',
                      value: '${route?['origin']} → ${route?['destination']}',
                    ),
                    const Divider(height: 20, color: Color(0xFFF3F4F6)),
                    _InfoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Departure',
                      value: _formatTime(schedule?['departure_time'] ?? ''),
                    ),
                    const Divider(height: 20, color: Color(0xFFF3F4F6)),
                    _InfoRow(
                      icon: Icons.directions_bus_outlined,
                      label: 'Bus',
                      value: '${bus?['model']} • ${bus?['plate_number']}',
                    ),
                    const Divider(height: 20, color: Color(0xFFF3F4F6)),
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: _formatDate(_trip['trip_date'] as String),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'GPS Tracking Active',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (_currentPosition != null)
                        Text(
                          '${_currentPosition!.latitude.toStringAsFixed(4)}, '
                          '${_currentPosition!.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),

              // Passenger Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Passengers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_boardedCount/${_passengers.length} boarded',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A73E8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Passenger List
              _passengers.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'No passengers booked yet',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                      ),
                    )
                  : Column(
                      children: _passengers
                          .map((p) => _PassengerTile(passenger: p))
                          .toList(),
                    ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // Bottom Action Button
      bottomNavigationBar: status == 'completed' || status == 'cancelled'
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: status == 'scheduled'
                  ? _ActionButton(
                      label: 'Start Trip',
                      icon: Icons.play_arrow_rounded,
                      color: const Color(0xFF10B981),
                      isLoading: _isLoading,
                      onPressed: _startTrip,
                    )
                  : _ActionButton(
                      label: 'End Trip (Arrived)',
                      icon: Icons.flag_rounded,
                      color: const Color(0xFF1A73E8),
                      isLoading: _isLoading,
                      onPressed: _endTrip,
                    ),
            ),
    );
  }

  String _formatTime(String t) {
    if (t.isEmpty) return '';
    final p = t.split(':');
    final h = int.parse(p[0]);
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${p[1]} $period';
  }

  String _formatDate(String d) {
    final dt = DateTime.parse(d);
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${w[dt.weekday - 1]}, ${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }
}

// ─── Trip Status Card ─────────────────────────────────────────────────────────

class _TripStatusCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool isTrackingGPS;
  final Position? currentPosition;

  const _TripStatusCard({
    required this.trip,
    required this.isTrackingGPS,
    required this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    final status = trip['status'] as String;
    final configs = {
      'scheduled': [
        const Color(0xFF1A73E8),
        Icons.schedule_rounded,
        'Ready to Depart',
      ],
      'in_progress': [
        const Color(0xFF10B981),
        Icons.play_circle_rounded,
        'Trip In Progress',
      ],
      'completed': [
        const Color(0xFF6B7280),
        Icons.check_circle_rounded,
        'Trip Completed',
      ],
      'cancelled': [
        const Color(0xFFEF4444),
        Icons.cancel_rounded,
        'Trip Cancelled',
      ],
    };
    final cfg =
        configs[status] ??
        [const Color(0xFFF59E0B), Icons.pending_rounded, 'Unknown'];

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
            decoration: BoxDecoration(
              color: (cfg[0] as Color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(cfg[1] as IconData, color: cfg[0] as Color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cfg[2] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cfg[0] as Color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status == 'in_progress' && trip['departed_at'] != null
                      ? 'Departed at ${_formatTimestamp(trip['departed_at'])}'
                      : status == 'completed' && trip['arrived_at'] != null
                      ? 'Arrived at ${_formatTimestamp(trip['arrived_at'])}'
                      : 'Tap "Start Trip" when ready',
                  style: TextStyle(
                    fontSize: 12,
                    color: (cfg[0] as Color).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String ts) {
    final dt = DateTime.parse(ts).toLocal();
    final h = dt.hour;
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${dt.minute.toString().padLeft(2, '0')} $period';
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
    final ticketList = passenger['tickets'] as List?;
    final ticketStatus = ticketList != null && ticketList.isNotEmpty
        ? ticketList.first['status'] as String
        : 'unknown';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'boarded':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
      case 'confirmed':
        statusColor = const Color(0xFF1A73E8);
        statusIcon = Icons.confirmation_number_rounded;
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: statusColor.withOpacity(0.1),
            child: Text(
              (user?['name'] as String? ?? 'P')[0].toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?['name'] ?? 'Unknown Passenger',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Seat ${passenger['seat_number']} • ${user?['phone'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(height: 2),
              Text(
                status[0].toUpperCase() + status.substring(1),
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
    final punctuality = TripPunctuality.calculate(trip);
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
        border: Border.all(
          color: punctuality.color.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: punctuality.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(punctuality.icon, color: punctuality.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      punctuality.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: punctuality.color,
                      ),
                    ),
                    Text(
                      punctuality.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: punctuality.color.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 14),

          // Timeline comparison: Scheduled vs Actual
          Row(
            children: [
              Expanded(
                child: _TimelineCompare(
                  label: 'Departure',
                  scheduled: _fmtScheduleTime(departureTimeStr),
                  actual: departedAt != null ? _fmtIso(departedAt) : null,
                  isMissed: status == 'scheduled' &&
                      _isOverdue(trip['trip_date'] as String? ?? '', departureTimeStr),
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: const Color(0xFFE5E7EB),
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              Expanded(
                child: _TimelineCompare(
                  label: 'Arrival',
                  scheduled: _fmtScheduleTime(arrivalTimeStr),
                  actual: arrivedAt != null ? _fmtIso(arrivedAt) : null,
                  isMissed: status == 'in_progress' &&
                      _isOverdue(trip['trip_date'] as String? ?? '', arrivalTimeStr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtScheduleTime(String t) {
    try {
      final p = t.split(':');
      final h = int.parse(p[0]);
      final m = p[1];
      final period = h >= 12 ? 'PM' : 'AM';
      final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$dh:$m $period';
    } catch (_) {
      return t;
    }
  }

  static String _fmtIso(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour;
      final period = h >= 12 ? 'PM' : 'AM';
      final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$dh:${dt.minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return iso;
    }
  }

  static bool _isOverdue(String dateStr, String timeStr) {
    try {
      final parts = timeStr.split(':');
      final d = DateTime.parse(dateStr);
      final planned = DateTime(d.year, d.month, d.day,
          int.parse(parts[0]), int.parse(parts[1]));
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

  const _TimelineCompare({
    required this.label,
    required this.scheduled,
    this.actual,
    this.isMissed = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasActual = actual != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 12,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 4),
            Text(
              scheduled,
              style: TextStyle(
                fontSize: 12,
                color: isMissed
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF6B7280),
                decoration: hasActual ? TextDecoration.lineThrough : null,
                decorationColor: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        if (hasActual) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 12,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 4),
              Text(
                actual!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ] else if (isMissed) ...[
          const SizedBox(height: 3),
          const Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 12,
                color: Color(0xFFEF4444),
              ),
              SizedBox(width: 4),
              Text(
                'Overdue',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
