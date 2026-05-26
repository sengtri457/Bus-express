import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../supabase_config.dart';
import 'passenger_main_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;
  final DateTime date;
  final List<String> seatNumbers;

  const BookingConfirmationScreen({
    super.key,
    required this.schedule,
    required this.date,
    required this.seatNumbers,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _isLoading = false;
  String? _userName;
  String? _userPhone;
  String? _userEmail;

  double get _pricePerSeat => (widget.schedule['price'] as num).toDouble();
  double get _totalPrice => _pricePerSeat * widget.seatNumbers.length;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      final data = await SupabaseConfig.client
          .from('users')
          .select('name, phone, email')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _userName = data['name'];
          _userPhone = data['phone'];
          _userEmail = data['email'];
        });
      }
    } catch (_) {}
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final scheduleId = widget.schedule['id'] as String;
      final tripDate = widget.date.toIso8601String().split('T')[0];

      // Step 1: Get or create trip
      String tripId;
      final existingTrip = await SupabaseConfig.client
          .from('trips')
          .select('id, status')
          .eq('schedule_id', scheduleId)
          .eq('trip_date', tripDate)
          .maybeSingle();

      if (existingTrip != null) {
        tripId = existingTrip['id'] as String;

        // Safety check: ensure the existing trip is not already completed or cancelled
        final tripStatus = existingTrip['status'] as String?;
        if (tripStatus == 'completed' || tripStatus == 'cancelled') {
          throw Exception(
            'This trip has already ${tripStatus == 'completed' ? 'ended' : 'been cancelled'} and cannot be booked.',
          );
        }
      } else {
        // FIX 1: was .single() — crashes if RLS blocks the insert or
        // the DB returns 0 rows. Use .maybeSingle() and check for null.
        final newTrip = await SupabaseConfig.client
            .from('trips')
            .insert({
              'schedule_id': scheduleId,
              'trip_date': tripDate,
              'bus_id': widget.schedule['buses']?['id'],
              'driver_id': widget.schedule['driver_id'],
              'conductor_id': widget.schedule['conductor_id'],
              'status': 'scheduled',
            })
            .select('id')
            .maybeSingle();

        if (newTrip == null) {
          throw Exception(
            'Failed to create trip. Check RLS policies on trips table.',
          );
        }
        tripId = newTrip['id'] as String;
      }

      // Step 2: Create one booking per seat
      String firstBookingId = '';
      for (final seat in widget.seatNumbers) {
        // FIX 2: was .single() — same issue. If the booking insert is
        // blocked or returns nothing, this would crash.
        final booking = await SupabaseConfig.client
            .from('bookings')
            .insert({
              'trip_id': tripId,
              'passenger_id': user.id,
              'seat_number': seat,
              'status': 'confirmed',
              'total_price': _pricePerSeat,
              'booked_at': DateTime.now().toIso8601String(),
              'booking_channel': 'online',
            })
            .select('id')
            .maybeSingle();

        if (booking == null) {
          throw Exception(
            'Failed to create booking for seat $seat. Check RLS policies on bookings table.',
          );
        }

        final bookingId = booking['id'] as String;
        if (firstBookingId.isEmpty) firstBookingId = bookingId;

        // Step 3: Payment per seat (cash)
        await SupabaseConfig.client.from('payments').insert({
          'booking_id': bookingId,
          'amount': _pricePerSeat,
          'method': 'cash',
          'status': 'pending',
        });

        // Step 4: Ticket with QR per seat
        final qrCode =
            'BUS-$bookingId-${DateTime.now().millisecondsSinceEpoch}';
        await SupabaseConfig.client.from('tickets').insert({
          'booking_id': bookingId,
          'qr_code': qrCode,
          'status': 'valid',
        });
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PassengerMainScreen(
            initialIndex: 1,
            newBookingId: firstBookingId,
            newSeatCount: widget.seatNumbers.length,
          ),
        ),
        (route) => route.isFirst,
      );
    } on PostgrestException catch (e) {
      _showError('Booking failed: ${e.message}');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.schedule['routes'] as Map<String, dynamic>;
    final bus = widget.schedule['buses'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Confirm Booking',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Trip Details
            _SectionCard(
              title: 'Trip Details',
              icon: Icons.directions_bus_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTime(widget.schedule['departure_time']),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            route['origin'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${route['duration_min']} min',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 1.5,
                                  color: const Color(0xFFE5E7EB),
                                ),
                                const Icon(
                                  Icons.directions_bus_rounded,
                                  size: 16,
                                  color: Color(0xFF1A73E8),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(widget.schedule['arrival_time']),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            route['destination'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _formatDate(widget.date),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.event_seat_rounded,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Seats',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          children: widget.seatNumbers.map((seat) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Text(
                                seat,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A73E8),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  if (bus != null) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.directions_bus_outlined,
                      label: 'Bus',
                      value: '${bus['model']} • ${bus['plate_number']}',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Passenger Info
            _SectionCard(
              title: 'Passenger',
              icon: Icons.person_outline_rounded,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'Name',
                    value: _userName ?? '—',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _userEmail ?? '—',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: _userPhone ?? '—',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment
            _SectionCard(
              title: 'Payment',
              icon: Icons.payment_rounded,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          color: Color(0xFF10B981),
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cash on Board',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF065F46),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Pay the conductor when boarding',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Price per seat',
                    value: '\$${_pricePerSeat.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.event_seat_rounded,
                    label: 'Number of seats',
                    value: '${widget.seatNumbers.length}',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFFE5E7EB)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${_totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A73E8),
                            ),
                          ),
                          if (widget.seatNumbers.length > 1)
                            Text(
                              '\$${_pricePerSeat.toStringAsFixed(2)} × ${widget.seatNumbers.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Arrive 15 minutes before departure. Show your QR ticket to the conductor when boarding.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF92400E),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF93C5FD),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Confirm ${widget.seatNumbers.length > 1 ? '${widget.seatNumbers.length} Seats' : 'Booking'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDate(DateTime date) {
    const months = [
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
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            children: [
              Icon(icon, color: const Color(0xFF1A73E8), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
