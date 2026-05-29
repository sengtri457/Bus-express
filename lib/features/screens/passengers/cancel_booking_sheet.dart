import 'package:flutter/material.dart';
import 'services/booking_cancellation_service.dart';

/// Call this from any screen:
/// CancelBookingSheet.show(context, bookingId: '...', onCancelled: () { ... });
class CancelBookingSheet extends StatefulWidget {
  final String bookingId;
  final String origin;
  final String destination;
  final String tripDate;
  final String seatNumber;
  final double totalPrice;
  final VoidCallback onCancelled;

  const CancelBookingSheet({
    super.key,
    required this.bookingId,
    required this.origin,
    required this.destination,
    required this.tripDate,
    required this.seatNumber,
    required this.totalPrice,
    required this.onCancelled,
  });

  static Future<void> show(
    BuildContext context, {
    required String bookingId,
    required String origin,
    required String destination,
    required String tripDate,
    required String seatNumber,
    required double totalPrice,
    required VoidCallback onCancelled,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelBookingSheet(
        bookingId: bookingId,
        origin: origin,
        destination: destination,
        tripDate: tripDate,
        seatNumber: seatNumber,
        totalPrice: totalPrice,
        onCancelled: onCancelled,
      ),
    );
  }

  @override
  State<CancelBookingSheet> createState() => _CancelBookingSheetState();
}

class _CancelBookingSheetState extends State<CancelBookingSheet> {
  bool _isLoading = false;
  bool _confirmed = false; // shows confirmation step first

  Future<void> _performCancellation() async {
    setState(() => _isLoading = true);

    final result = await CancellationService.cancelBooking(widget.bookingId);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == CancelResult.success) {
      Navigator.pop(context); // close sheet
      _showSuccessDialog();
    } else {
      Navigator.pop(context); // close sheet
      _showErrorSnack(CancellationService.messageFor(result), result);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFFEF4444),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Booking Cancelled',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your booking for ${widget.origin} → ${widget.destination} (Seat ${widget.seatNumber}) has been cancelled.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF059669),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cash bookings are cancelled instantly. No refund is required since payment was on board.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF065F46),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onCancelled();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnack(String message, CancelResult result) {
    final color =
        result == CancelResult.tooLate ||
            result == CancelResult.alreadyBoarded ||
            result == CancelResult.tripStarted
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Warning icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B),
              size: 34,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Cancel Booking?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Are you sure you want to cancel your trip?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),

          // Booking summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.route_rounded,
                  label: 'Route',
                  value: '${widget.origin} → ${widget.destination}',
                ),
                const Divider(height: 16, color: Color(0xFFE5E7EB)),
                _SummaryRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: _formatDate(widget.tripDate),
                ),
                const Divider(height: 16, color: Color(0xFFE5E7EB)),
                _SummaryRow(
                  icon: Icons.event_seat_rounded,
                  label: 'Seat',
                  value: widget.seatNumber,
                ),
                const Divider(height: 16, color: Color(0xFFE5E7EB)),
                _SummaryRow(
                  icon: Icons.attach_money_rounded,
                  label: 'Amount',
                  value: '\$${widget.totalPrice.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Policy note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFFF97316),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cancellations must be made at least 2 hours before departure. Trips already in progress cannot be cancelled.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A3412),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Keep Booking',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _performCancellation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFFCA5A5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Yes, Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDate(String d) {
    try {
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
    } catch (_) {
      return d;
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
