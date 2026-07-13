import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../l10n/tr_extension.dart';
import '../../../repositories/trip_repository.dart';
import '../../../supabase_config.dart';
import '../../../repositories/booking_repository.dart';
import '../../auth/login_screen.dart';
import '../../widgets/animations.dart';
import 'booking_confirmation_screen.dart';

class ScheduleSeatScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;
  final DateTime date;

  const ScheduleSeatScreen({
    super.key,
    required this.schedule,
    required this.date,
  });

  @override
  State<ScheduleSeatScreen> createState() => _ScheduleSeatScreenState();
}

class _ScheduleSeatScreenState extends State<ScheduleSeatScreen> {
  final _tripRepo = TripRepository();
  final _bookingRepo = BookingRepository();
  RealtimeChannel? _realtimeChannel;
  bool _isLockingSeats = false;

  List<String> _bookedSeats = [];
  final List<String> _selectedSeats = [];
  bool _isLoading = true;
  int _capacity = 30;
  Timer? _timer;
  String? _tripStatus;

  bool get _isExpired {
    if (_tripStatus == 'in_progress' ||
        _tripStatus == 'completed' ||
        _tripStatus == 'cancelled') return true;

    try {
      final arrivalParts =
          (widget.schedule['arrival_time'] as String).split(':');
      final departureParts =
          (widget.schedule['departure_time'] as String).split(':');

      var arrival = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        int.parse(arrivalParts[0]),
        int.parse(arrivalParts[1]),
      );

      final depHours = int.parse(departureParts[0]);
      final depMins = int.parse(departureParts[1]);
      final arrHours = int.parse(arrivalParts[0]);
      final arrMins = int.parse(arrivalParts[1]);

      if (arrHours * 60 + arrMins < depHours * 60 + depMins) {
        arrival = arrival.add(const Duration(days: 1));
      }

      if (DateTime.now().isAfter(arrival)) return true;
    } catch (_) {}

    try {
      final parts =
          (widget.schedule['departure_time'] as String).split(':');
      final departure = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (DateTime.now().isAfter(departure)) return true;
    } catch (_) {}

    return false;
  }

  double get _totalPrice {
    final price = (widget.schedule['price'] as num).toDouble();
    return price * _selectedSeats.length;
  }

  @override
  void initState() {
    super.initState();
    _capacity = widget.schedule['buses']?['capacity'] ?? 30;
    _loadBookedSeats();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadBookedSeats();
    });
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _timer?.cancel();
    super.dispose();
  }

  void _subscribeRealtime(String tripId) {
    _realtimeChannel?.unsubscribe();
    
    _realtimeChannel = _tripRepo.client
        .channel('trip_seats_$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'seat_holds',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
          ),
          callback: (payload) {
            _loadBookedSeatsSilent(tripId);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
          ),
          callback: (payload) {
            _loadBookedSeatsSilent(tripId);
          },
        );
    _realtimeChannel?.subscribe();
  }

  Future<void> _loadBookedSeatsSilent(String tripId) async {
    try {
      final currentUserId = _tripRepo.client.auth.currentUser?.id;

      final bookings = await _tripRepo.client
          .from('bookings')
          .select('seat_number')
          .eq('trip_id', tripId)
          .inFilter('status', ['confirmed', 'pending', 'boarded']);

      final holds = await _tripRepo.client
          .from('seat_holds')
          .select('seat_number, passenger_id')
          .eq('trip_id', tripId)
          .gt('expires_at', DateTime.now().toIso8601String());

      if (mounted) {
        final bookedList = (bookings as List)
            .map((b) => b['seat_number'] as String)
            .toList();

        final heldList = (holds as List)
            .where((h) => h['passenger_id'] != currentUserId)
            .map((h) => h['seat_number'] as String)
            .toList();

        setState(() {
          _bookedSeats = {...bookedList, ...heldList}.toList();
        });
      }
    } catch (e) {
      debugPrint('Error silent loading seats: $e');
    }
  }

  Future<void> _loadBookedSeats() async {
    setState(() => _isLoading = true);
    try {
      final tripData = await _tripRepo.client
          .from('trips')
          .select('id, status')
          .eq('schedule_id', widget.schedule['id'])
          .eq('trip_date', widget.date.toIso8601String().split('T')[0])
          .maybeSingle();

      if (tripData != null) {
        final tripId = tripData['id'] as String;
        _tripStatus = tripData['status'] as String?;
        
        _subscribeRealtime(tripId);
        await _loadBookedSeatsSilent(tripId);
      } else {
        if (mounted) {
          setState(() {
            _tripStatus = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading seats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSeat(String seat) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else {
        _selectedSeats.add(seat);
      }
    });
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign In Required', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Please sign in to continue booking your tickets.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Not Now', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToBooking() async {
    if (_isLockingSeats) return;
    HapticFeedback.mediumImpact();
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.schedulePleaseSelectSeat),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() => _isLockingSeats = true);

    try {
      final tripDateStr = widget.date.toIso8601String().split('T')[0];
      final tripData = await _tripRepo.client
          .from('trips')
          .select('id')
          .eq('schedule_id', widget.schedule['id'])
          .eq('trip_date', tripDateStr)
          .maybeSingle();

      String tripId;
      if (tripData == null) {
        final newTrip = await _tripRepo.client
            .from('trips')
            .insert({
              'schedule_id': widget.schedule['id'],
              'trip_date': tripDateStr,
              'bus_id': widget.schedule['buses']?['id'],
              'driver_id': widget.schedule['driver_id'],
              'conductor_id': widget.schedule['conductor_id'],
              'status': 'scheduled',
            })
            .select('id')
            .single();
        tripId = newTrip['id'] as String;
      } else {
        tripId = tripData['id'] as String;
      }
      final passengerId = _tripRepo.client.auth.currentUser?.id;

      if (passengerId == null) {
        throw Exception('User session not found. Please log in again.');
      }

      final holdResult = await _bookingRepo.holdSeats(
        tripId: tripId,
        seatNumbers: _selectedSeats,
        passengerId: passengerId,
      );

      if (holdResult is Failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(holdResult.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          await _loadBookedSeatsSilent(tripId);
        }
        return;
      }

      if (mounted) {
        final bookingFinished = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(
              schedule: widget.schedule,
              date: widget.date,
              seatNumbers: _selectedSeats,
            ),
          ),
        );

        if (bookingFinished != true) {
          await _bookingRepo.releaseSeatsHold(
            tripId: tripId,
            seatNumbers: _selectedSeats,
            passengerId: passengerId,
          );
          await _loadBookedSeatsSilent(tripId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reserving seats: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLockingSeats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.schedule['routes'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.primaryBlue),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          context.tr.scheduleSelectSeat,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.primaryBlue),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateHelpers.formatTime(
                          widget.schedule['departure_time'],
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        route['origin'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      Text(
                        '${route['duration_min']} min',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateHelpers.formatTime(
                          widget.schedule['arrival_time'],
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        route['destination'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: const Column(
                      children: [
                        SkeletonCard(height: 80),
                        SizedBox(height: 16),
                        SkeletonBlock(rows: 2),
                        SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: SkeletonSeatGrid(rows: 6),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LegendItem(
                              color: AppColors.border,
                              label: context.tr.scheduleAvailable,
                            ),
                            const SizedBox(width: 20),
                            _LegendItem(
                              color: AppColors.primaryBlue,
                              label: context.tr.scheduleSelected,
                            ),
                            const SizedBox(width: 20),
                            _LegendItem(
                              color:
                                  AppColors.error.withValues(alpha: 0.15),
                              label: context.tr.scheduleBooked,
                              textColor: AppColors.error,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isExpired)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _tripStatus == 'completed'
                                      ? context.tr.scheduleTripEnded
                                      : _tripStatus == 'cancelled'
                                          ? context.tr.scheduleTripCancelled
                                          : context.tr.scheduleTripOver,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _FrontIndicator(
                                availableCount: _capacity - _bookedSeats.length,
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: AppColors.divider),
                              const SizedBox(height: 16),
                              _ColumnHeaders(capacity: _capacity),
                              const SizedBox(height: 8),
                              _SeatGrid(
                                capacity: _capacity,
                                bookedSeats: _bookedSeats,
                                selectedSeats: _selectedSeats,
                                isExpired: _isExpired,
                                onSeatTap: _toggleSeat,
                              ),
                              const SizedBox(height: 12),
                              const _BackIndicator(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSeats.isEmpty
                      ? context.tr.scheduleNoSeatSelected
                      : context.tr.scheduleSeatCount(_selectedSeats.length, _selectedSeats.join(', ')),
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedSeats.isNotEmpty
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '\$${_totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    if (_selectedSeats.length > 1) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(\$${widget.schedule['price']} x ${_selectedSeats.length})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isExpired ? null : _proceedToBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.tr.scheduleContinue,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SeatStatus { available, selected, booked }

class _SeatWidget extends StatelessWidget {
  final String label;
  final SeatStatus status;
  final VoidCallback? onTap;

  const _SeatWidget({
    required this.label,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (status) {
      case SeatStatus.available:
        bgColor = AppColors.background;
        textColor = const Color(0xFF374151);
        borderColor = AppColors.border;
      case SeatStatus.selected:
        bgColor = AppColors.primaryBlue;
        textColor = Colors.white;
        borderColor = AppColors.primaryBlue;
      case SeatStatus.booked:
        bgColor = const Color(0xFFFEF2F2);
        textColor = AppColors.error;
        borderColor = const Color(0xFFFECACA);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_seat_rounded,
              size: 18,
              color: status == SeatStatus.booked
                  ? AppColors.error.withValues(alpha: 0.5)
                  : status == SeatStatus.selected
                      ? Colors.white
                      : AppColors.textHint,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color? textColor;

  const _LegendItem({
    required this.color,
    required this.label,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BusLayout {
  static const double aisleWidth = 28;
}

class _FrontIndicator extends StatelessWidget {
  final int availableCount;
  const _FrontIndicator({required this.availableCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryBlueBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_bus_rounded,
                  size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Text(context.tr.scheduleFrontLabel,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue)),
              const SizedBox(width: 4),
              Container(
                width: 1,
                height: 12,
                color: AppColors.primaryBlueBorder,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.meeting_room_rounded,
                  size: 14, color: AppColors.primaryBlue),
              const SizedBox(width: 4),
              Text(context.tr.scheduleDoorLabel,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue)),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            context.tr.scheduleSeatsLeft(availableCount),
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ColumnHeaders extends StatelessWidget {
  final int capacity;
  const _ColumnHeaders({required this.capacity});

  @override
  Widget build(BuildContext context) {
    if (capacity == 14) {
      return Row(
        children: [
          Expanded(child: _headerLabel('A')),
          const SizedBox(width: 8),
          Expanded(child: _headerLabel('B')),
          const SizedBox(width: 8),
          Expanded(child: _headerLabel('C')),
          // Align with right column plus spacing
          const SizedBox(width: 44),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: _headerLabel('A')),
          _buildAisle(),
          Expanded(child: _headerLabel('B')),
          // Align with right column plus spacing
          const SizedBox(width: 44),
        ],
      );
    }
  }

  static Widget _headerLabel(String label) {
    return Center(
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint)),
    );
  }

  static Widget _buildAisle() {
    return const SizedBox(
      width: _BusLayout.aisleWidth,
      child: Center(
        child: SizedBox(),
      ),
    );
  }
}

class _SeatGrid extends StatelessWidget {
  final int capacity;
  final List<String> bookedSeats;
  final List<String> selectedSeats;
  final bool isExpired;
  final void Function(String seat) onSeatTap;

  const _SeatGrid({
    required this.capacity,
    required this.bookedSeats,
    required this.selectedSeats,
    required this.isExpired,
    required this.onSeatTap,
  });

  SeatStatus _status(String seat) {
    if (bookedSeats.contains(seat)) return SeatStatus.booked;
    if (selectedSeats.contains(seat)) return SeatStatus.selected;
    return SeatStatus.available;
  }

  @override
  Widget build(BuildContext context) {
    if (capacity == 14) {
      return _buildMinivanGrid(context);
    } else {
      return _buildLargeBusGrid(context);
    }
  }

  Widget _buildMinivanGrid(BuildContext context) {
    return Column(
      children: [
        _buildMinivanRow(
          context,
          col1: _buildDriverSeat(),
          col2: _buildSeatWidget('1B'),
          col3: _buildSeatWidget('1C'),
          col4: _buildDoor(),
        ),
        _buildMinivanRow(
          context,
          col1: _buildSeatWidget('2A'),
          col2: _buildSeatWidget('2B'),
          col3: _buildSeatWidget('2C'),
          col4: const SizedBox(width: 32),
        ),
        _buildMinivanRow(
          context,
          col1: _buildSeatWidget('3A'),
          col2: _buildSeatWidget('3B'),
          col3: _buildMinivanWalkway(),
          col4: _buildSlideDoor(),
        ),
        _buildMinivanRow(
          context,
          col1: _buildSeatWidget('4A'),
          col2: _buildSeatWidget('4B'),
          col3: _buildSeatWidget('4C'),
          col4: const SizedBox(width: 32),
        ),
        _buildMinivanRow(
          context,
          col1: _buildSeatWidget('5A'),
          col2: _buildSeatWidget('5B'),
          col3: _buildSeatWidget('5C'),
          col4: const SizedBox(width: 32),
        ),
      ],
    );
  }

  Widget _buildMinivanRow(
    BuildContext context, {
    required Widget col1,
    required Widget col2,
    required Widget col3,
    required Widget col4,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: col1),
          const SizedBox(width: 8),
          Expanded(child: col2),
          const SizedBox(width: 8),
          Expanded(child: col3),
          const SizedBox(width: 12),
          col4,
        ],
      ),
    );
  }

  Widget _buildLargeBusGrid(BuildContext context) {
    final totalRows = 1 + (capacity ~/ 2);
    return Column(
      children: List.generate(totalRows, (rowIndex) {
        final rowNum = rowIndex + 1;
        
        Widget leftCol;
        Widget rightCol;
        Widget farRightCol;

        if (rowNum == 1) {
          leftCol = _buildDriverSeat();
          rightCol = _buildSeatWidget('1B');
          farRightCol = _buildDoor();
        } else {
          final leftSeatIndex = (rowNum - 2) * 2 + 2;
          final rightSeatIndex = (rowNum - 2) * 2 + 3;

          if (leftSeatIndex <= capacity) {
            leftCol = _buildSeatWidget('${rowNum}A');
          } else {
            leftCol = const Expanded(child: SizedBox());
          }

          if (rightSeatIndex <= capacity) {
            rightCol = _buildSeatWidget('${rowNum}B');
          } else {
            rightCol = const Expanded(child: SizedBox());
          }

          farRightCol = const SizedBox(width: 32);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              leftCol is Expanded ? leftCol : Expanded(child: leftCol),
              _buildLargeBusWalkway(rowIndex),
              rightCol is Expanded ? rightCol : Expanded(child: rightCol),
              const SizedBox(width: 12),
              farRightCol,
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSeatWidget(String seat) {
    final status = _status(seat);
    return _SeatWidget(
      label: seat,
      status: status,
      onTap: (status == SeatStatus.booked || isExpired)
          ? null
          : () => onSeatTap(seat),
    );
  }

  Widget _buildDriverSeat() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.airline_seat_recline_normal_rounded,
            size: 18,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 2),
          Text(
            'Driver',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoor() {
    return Container(
      width: 32,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_rounded,
            size: 16,
            color: Color(0xFFD97706),
          ),
          SizedBox(height: 2),
          Text(
            'Door',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideDoor() {
    return Container(
      width: 32,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const RotatedBox(
        quarterTurns: 3,
        child: Center(
          child: Text(
            'Slide Door',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinivanWalkway() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'Walkway',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildLargeBusWalkway(int rowIndex) {
    final showLabel = rowIndex % 5 == 2;
    return SizedBox(
      width: _BusLayout.aisleWidth,
      height: 48,
      child: Center(
        child: showLabel
            ? const RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'WALKWAY',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 1.5,
                  ),
                ),
              )
            : Container(
                width: 1.5,
                height: 24,
                color: const Color(0xFFE5E7EB),
              ),
      ),
    );
  }
}

class _BackIndicator extends StatelessWidget {
  const _BackIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus_rounded,
                size: 14, color: AppColors.textHint),
            const SizedBox(width: 6),
            Text(context.tr.scheduleBackLabel,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}
