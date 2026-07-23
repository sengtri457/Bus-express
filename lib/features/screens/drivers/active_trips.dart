import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../l10n/tr_extension.dart';
import '../../../supabase_config.dart';

class ActiveTripScreen extends StatefulWidget {
  final Map<String, dynamic> trip;

  const ActiveTripScreen({super.key, required this.trip});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late Map<String, dynamic> _trip;

  // GPS
  StreamSubscription<Position>? _posStream;
  Position? _currentPosition;
  _GpsState _gpsState = _GpsState.idle;
  String _gpsMessage = '';
  DateTime? _lastGpsSync;
  static const Duration _gpsThrottle = Duration(seconds: 5);

  // UI
  bool _startLoading = false;
  bool _endLoading = false;
  late final Timer _clockTimer;
  Duration _elapsed = Duration.zero;

  // Derived
  String get _status => _trip['status'] as String? ?? 'scheduled';
  bool get _isScheduled => _status == 'scheduled';
  bool get _isInProgress => _status == 'in_progress';

  String get _origin =>
      _trip['schedules']?['routes']?['origin'] as String? ?? '–';
  String get _destination =>
      _trip['schedules']?['routes']?['destination'] as String? ?? '–';
  String get _departureTime =>
      _trip['schedules']?['departure_time'] as String? ?? '–';
  String get _arrivalTime =>
      _trip['schedules']?['arrival_time'] as String? ?? '–';
  String get _plate => _trip['buses']?['plate_number'] as String? ?? '–';

  @override
  void initState() {
    super.initState();
    _trip = Map<String, dynamic>.from(widget.trip);

    // If already in progress, start GPS and elapsed timer immediately
    if (_isInProgress) {
      _startGps();
      _startElapsedTimer();
    }
  }

  // ─── GPS ─────────────────────────────────────────────────

  Future<void> _startGps() async {
    setState(() {
      _gpsState = _GpsState.requesting;
      _gpsMessage = context.tr.activeTripRequestingPermission;
    });

    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        _setGpsError(context.tr.activeTripGpsDisabled);
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        _setGpsError(context.tr.activeTripPermissionDenied);
        return;
      }
    } catch (e) {
        _setGpsError(context.tr.activeTripPermissionFailed(e.toString()));
      return;
    }

    setState(() {
      _gpsState = _GpsState.active;
      _gpsMessage = context.tr.activeTripGpsActiveMessage;
    });

    // Get initial location immediately so we don't start with null coordinates!
    try {
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() => _currentPosition = initialPos);
      }
      await SupabaseConfig.client
          .from('trips')
          .update({
            'latitude': initialPos.latitude,
            'longitude': initialPos.longitude,
          })
          .eq('id', _trip['id'] as String);
      debugPrint(
        '[GPS Sync] Initial driver position synced: ${initialPos.latitude}, ${initialPos.longitude}',
      );
    } catch (e) {
      _setGpsError(context.tr.activeTripGpsPositionError(e.toString()));
    }

    _posStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          if (!mounted) return;
          setState(() => _currentPosition = pos);

          // Throttle writes to Supabase — the passenger tracking polls every 5s
          // so writing faster is wasteful and risks hitting rate limits.
          final now = DateTime.now();
          if (_lastGpsSync == null ||
              now.difference(_lastGpsSync!) >= _gpsThrottle) {
            _lastGpsSync = now;
            SupabaseConfig.client
                .from('trips')
                .update({
                  'latitude': pos.latitude,
                  'longitude': pos.longitude,
                })
                .eq('id', _trip['id'] as String)
                .catchError((err) => debugPrint('[GPS] Sync error: $err'));
          }
        }, onError: (_) => _setGpsError(context.tr.activeTripGpsSignalLost));
  }

  void _setGpsError(String msg) {
    if (!mounted) return;
    setState(() {
      _gpsState = _GpsState.error;
      _gpsMessage = msg;
    });
  }

  void _startElapsedTimer() {
    final departedAt = _trip['departed_at'];
    if (departedAt != null) {
      _elapsed = DateTime.now().difference(
        DateTime.parse(departedAt as String),
      );
    }
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  // ─── Actions ─────────────────────────────────────────────

  Future<void> _startTrip() async {
    setState(() => _startLoading = true);
    try {
      // 1. Fetch boarded count
      final bookings = await SupabaseConfig.client
          .from('bookings')
          .select('id, status')
          .eq('trip_id', _trip['id'])
          .eq('status', 'boarded');
      
      final boardedCount = (bookings as List).length;

      // 2. Fetch conductor permission
      final tripData = await SupabaseConfig.client
          .from('trips')
          .select('conductor_allowed_start')
          .eq('id', _trip['id'] as String)
          .single();

      final allowedByConductor = tripData['conductor_allowed_start'] == true;
      
      // Get capacity from the already loaded _trip data to ensure reliability
      final scheduleInfo = _trip['schedules'] as Map<String, dynamic>?;
      final busInfo = scheduleInfo?['buses'] as Map<String, dynamic>?;
      
      int capacity = 0;
      final rawCap = busInfo?['capacity'];
      if (rawCap is int) capacity = rawCap;
      else if (rawCap is num) capacity = rawCap.toInt();
      else if (rawCap is String) capacity = int.tryParse(rawCap) ?? 0;

      // 3. Validation logic
      // If capacity is 0, we can't know if it's full, so we default to needing permission
      final isFull = capacity > 0 && boardedCount >= capacity;
      
      if (!isFull && !allowedByConductor) {
        _showError(context.tr.driverTripBusNotFull(boardedCount, capacity));
        return; // Early return, loading state will be reset in finally block
      }

      final now = DateTime.now().toIso8601String();
      await SupabaseConfig.client
          .from('trips')
          .update({'status': 'in_progress', 'departed_at': now})
          .eq('id', _trip['id'] as String);

      setState(() {
        _trip['status'] = 'in_progress';
        _trip['departed_at'] = now;
      });

      await _startGps();
      _startElapsedTimer();
    } catch (e) {
      _showError(context.tr.activeTripCouldNotStart);
    } finally {
      if (mounted) setState(() => _startLoading = false);
    }
  }

  Future<void> _endTrip() async {
    final confirmed = await _showConfirmDialog(
      title: context.tr.activeTripEndDialogTitle,
      message: context.tr.activeTripEndDialogMessage,
      confirmLabel: context.tr.activeTripEndTripLabel,
      confirmColor: const Color(0xFFDC2626),
    );
    if (!confirmed) return;

    setState(() => _endLoading = true);
    try {
      final now = DateTime.now().toIso8601String();
      await SupabaseConfig.client
          .from('trips')
          .update({'status': 'completed', 'arrived_at': now})
          .eq('id', _trip['id'] as String);

      _posStream?.cancel();
      _clockTimer.cancel();

      setState(() {
        _trip['status'] = 'completed';
        _trip['arrived_at'] = now;
        _gpsState = _GpsState.idle;
        _gpsMessage = context.tr.activeTripGpsStopped;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.activeTripCompletedSnack),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );

      // Go back to home
      Navigator.of(context).pop();
    } catch (_) {
      _showError(context.tr.activeTripCouldNotEnd);
    } finally {
      if (mounted) setState(() => _endLoading = false);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444)),
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
            child: Text(
              context.tr.cancel,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatTime(String? iso) {
    if (iso == null) return '–';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  void dispose() {
    _posStream?.cancel();
    if (_isInProgress) _clockTimer.cancel();
    super.dispose();
  }

  // ─── UI ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          context.tr.activeTripAppBarTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Route banner
          _RouteBanner(
            origin: _origin,
            destination: _destination,
            departureTime: _departureTime,
            arrivalTime: _arrivalTime,
            plate: _plate,
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Status card
                  _StatusCard(
                    status: _status,
                    departedAt: _formatTime(_trip['departed_at'] as String?),
                    arrivedAt: _formatTime(_trip['arrived_at'] as String?),
                    elapsed: _isInProgress ? _formatElapsed(_elapsed) : null,
                  ),
                  const SizedBox(height: 12),

                  // GPS card
                  _GpsCard(
                    gpsState: _gpsState,
                    message: _gpsMessage,
                    position: _currentPosition,
                  ),
                  const SizedBox(height: 24),

                  // Action
                  if (_isScheduled)
                    _ActionButton(
                      label: context.tr.activeTripStartTrip,
                      icon: Icons.play_arrow_rounded,
                      color: const Color(0xFF1A73E8),
                      loading: _startLoading,
                      onPressed: _startTrip,
                    )
                  else if (_isInProgress)
                    _ActionButton(
                      label: context.tr.activeTripEndTripLabel,
                      icon: Icons.flag_rounded,
                      color: const Color(0xFFDC2626),
                      loading: _endLoading,
                      onPressed: _endTrip,
                    )
                  else
                    _CompletedBadge(
                      arrivedAt: _formatTime(_trip['arrived_at'] as String?),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────

class _RouteBanner extends StatelessWidget {
  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String plate;

  const _RouteBanner({
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.plate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A73E8),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          // Origin → Destination
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      origin,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      departureTime,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plate,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      destination,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      arrivalTime,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final String departedAt;
  final String arrivedAt;
  final String? elapsed;

  const _StatusCard({
    required this.status,
    required this.departedAt,
    required this.arrivedAt,
    this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr.activeTripTripStatus,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              if (elapsed != null)
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Color(0xFF1A73E8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      elapsed!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A73E8),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          _TimelineRow(
            icon: Icons.play_circle_outline_rounded,
            label: context.tr.activeTripDepartedLabel,
            value: departedAt,
            done: departedAt != '–',
            activeColor: const Color(0xFF16A34A),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 11),
            child: SizedBox(
              height: 20,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFE5E7EB),
              ),
            ),
          ),
          _TimelineRow(
            icon: Icons.flag_rounded,
            label: context.tr.activeTripArrivedLabel,
            value: arrivedAt,
            done: arrivedAt != '–',
            activeColor: const Color(0xFF1A73E8),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool done;
  final Color activeColor;

  const _TimelineRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.done,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: done ? activeColor : const Color(0xFFD1D5DB),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: done ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: done ? activeColor : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

enum _GpsState { idle, requesting, active, error }

class _GpsCard extends StatelessWidget {
  final _GpsState gpsState;
  final String message;
  final Position? position;

  const _GpsCard({
    required this.gpsState,
    required this.message,
    this.position,
  });

  Color get _borderColor {
    switch (gpsState) {
      case _GpsState.active:
        return const Color(0xFF16A34A);
      case _GpsState.error:
        return const Color(0xFFEF4444);
      case _GpsState.requesting:
        return const Color(0xFFD97706);
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Color get _iconColor {
    switch (gpsState) {
      case _GpsState.active:
        return const Color(0xFF16A34A);
      case _GpsState.error:
        return const Color(0xFFEF4444);
      case _GpsState.requesting:
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData get _icon {
    switch (gpsState) {
      case _GpsState.active:
        return Icons.gps_fixed_rounded;
      case _GpsState.error:
        return Icons.gps_off_rounded;
      case _GpsState.requesting:
        return Icons.gps_not_fixed_rounded;
      default:
        return Icons.gps_not_fixed_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: gpsState == _GpsState.requesting
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _iconColor,
                        ),
                      )
                    : Icon(_icon, color: _iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.activeTripGpsTracking,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(fontSize: 12, color: _iconColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Coordinates
          if (position != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            Row(
              children: [
                _CoordChip(
                  label: context.tr.activeTripCoordLat,
                  value: position!.latitude.toStringAsFixed(6),
                ),
                const SizedBox(width: 8),
                _CoordChip(
                  label: context.tr.activeTripCoordLng,
                  value: position!.longitude.toStringAsFixed(6),
                ),
                const SizedBox(width: 8),
                _CoordChip(
                  label: context.tr.activeTripCoordAcc,
                  value: '${position!.accuracy.toStringAsFixed(0)}m',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CoordChip extends StatelessWidget {
  final String label;
  final String value;

  const _CoordChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 22),
        label: Text(
          loading ? context.tr.activeTripPleaseWait : label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  final String arrivedAt;
  const _CompletedBadge({required this.arrivedAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.activeTripCompletedBadge,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
              Text(
                context.tr.activeTripArrivedAt(arrivedAt),
                style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
