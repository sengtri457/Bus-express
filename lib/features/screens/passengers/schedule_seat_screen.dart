import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../repositories/trip_repository.dart';
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
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
        final bookings = await _tripRepo.client
            .from('bookings')
            .select('seat_number')
            .eq('trip_id', tripData['id'])
            .inFilter('status', ['confirmed', 'pending', 'boarded']);

        if (mounted) {
          setState(() {
            _tripStatus = tripData['status'] as String?;
            _bookedSeats = (bookings as List)
                .map((b) => b['seat_number'] as String)
                .toList();
          });
        }
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
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else {
        _selectedSeats.add(seat);
      }
    });
  }

  void _proceedToBooking() {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one seat'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          schedule: widget.schedule,
          date: widget.date,
          seatNumbers: _selectedSeats,
        ),
      ),
    );
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
        title: const Text(
          'Select Seat',
          style: TextStyle(fontWeight: FontWeight.w700),
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
                              color: const Color(0xFFE5E7EB),
                              label: 'Available',
                            ),
                            const SizedBox(width: 20),
                            _LegendItem(
                              color: const Color(0xFF2563EB),
                              label: 'Selected',
                            ),
                            const SizedBox(width: 20),
                            _LegendItem(
                              color:
                                  const Color(0xFFEF4444).withValues(alpha: 0.15),
                              label: 'Booked',
                              textColor: const Color(0xFFEF4444),
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
                                      ? 'This trip has ended / is completed.'
                                      : _tripStatus == 'cancelled'
                                          ? 'This trip has been cancelled.'
                                          : 'This trip is over / has departed (Time over).',
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
                              const Divider(color: Color(0xFFF3F4F6)),
                              const SizedBox(height: 16),
                              const _ColumnHeaders(),
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
                      ? 'No seat selected'
                      : '${_selectedSeats.length} seat${_selectedSeats.length > 1 ? 's' : ''}: ${_selectedSeats.join(', ')}',
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
                        color: Color(0xFF2563EB),
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
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
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
        bgColor = const Color(0xFFF9FAFB);
        textColor = const Color(0xFF374151);
        borderColor = const Color(0xFFE5E7EB);
      case SeatStatus.selected:
        bgColor = const Color(0xFF2563EB);
        textColor = Colors.white;
        borderColor = const Color(0xFF2563EB);
      case SeatStatus.booked:
        bgColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFEF4444);
        borderColor = const Color(0xFFFECACA);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                  : status == SeatStatus.selected
                      ? Colors.white
                      : const Color(0xFF9CA3AF),
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
  static const int seatsPerRow = 4;
  static const List<String> colLetters = ['A', 'B', 'C', 'D'];
  static const double aisleWidth = 28;

  static int rowsFromCapacity(int capacity) =>
      (capacity + seatsPerRow - 1) ~/ seatsPerRow;

  static String seatLabel(int index) {
    final row = (index ~/ seatsPerRow) + 1;
    final col = index % seatsPerRow;
    return '$row${colLetters[col]}';
  }

  static bool isEmptySlot(int index, int capacity) => index >= capacity;
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
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFBFDBFE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_bus_rounded,
                  size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              const Text('FRONT',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB))),
              const SizedBox(width: 4),
              Container(
                width: 1,
                height: 12,
                color: const Color(0xFFBFDBFE),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.meeting_room_rounded,
                  size: 14, color: Color(0xFF2563EB)),
              const SizedBox(width: 4),
              const Text('DOOR',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB))),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$availableCount seats left',
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _headerLabel('A')),
        Expanded(child: _headerLabel('B')),
        _buildAisle(),
        Expanded(child: _headerLabel('C')),
        Expanded(child: _headerLabel('D')),
      ],
    );
  }

  static Widget _headerLabel(String label) {
    return Center(
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF))),
    );
  }

  static Widget _buildAisle() {
    return SizedBox(
      width: _BusLayout.aisleWidth,
      child: Center(
        child: Container(
          width: 2,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
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
    final rows = _BusLayout.rowsFromCapacity(capacity);
    return Column(
        children: List.generate(rows, (i) => _buildRow(i)));
  }

  Widget _buildRow(int rowIndex) {
    final rowNum = rowIndex + 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _buildSeat(rowNum, 0),
          _buildSeat(rowNum, 1),
          _buildAisleGap(),
          _buildSeat(rowNum, 2),
          _buildSeat(rowNum, 3),
        ],
      ),
    );
  }

  Widget _buildSeat(int row, int col) {
    final index = (row - 1) * _BusLayout.seatsPerRow + col;
    if (_BusLayout.isEmptySlot(index, capacity)) {
      return const Expanded(child: SizedBox());
    }
    final seat = _BusLayout.seatLabel(index);
    final status = _status(seat);
    return Expanded(
      child: _SeatWidget(
        label: seat,
        status: status,
        onTap: (status == SeatStatus.booked || isExpired)
            ? null
            : () => onSeatTap(seat),
      ),
    );
  }

  static Widget _buildAisleGap() {
    return SizedBox(
      width: _BusLayout.aisleWidth,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Center(
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
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
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus_rounded,
                size: 14, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 6),
            const Text('BACK',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}
