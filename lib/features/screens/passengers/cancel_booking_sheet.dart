import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../l10n/tr_extension.dart';
import 'services/booking_cancellation_service.dart';

class CancelBookingSheet extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;
  final String origin;
  final String destination;
  final String tripDate;
  final VoidCallback onCancelled;

  const CancelBookingSheet({
    super.key,
    required this.bookings,
    required this.origin,
    required this.destination,
    required this.tripDate,
    required this.onCancelled,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Map<String, dynamic>> bookings,
    required String origin,
    required String destination,
    required String tripDate,
    required VoidCallback onCancelled,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelBookingSheet(
        bookings: bookings,
        origin: origin,
        destination: destination,
        tripDate: tripDate,
        onCancelled: onCancelled,
      ),
    );
  }

  @override
  State<CancelBookingSheet> createState() => _CancelBookingSheetState();
}

class _CancelBookingSheetState extends State<CancelBookingSheet> {
  bool _isLoading = false;

  List<String> get _bookingIds =>
      widget.bookings.map((b) => b['id'] as String).toList();

  List<String> get _seatNumbers =>
      widget.bookings.map((b) => b['seat_number'] as String).toList();

  double get _totalPrice =>
      widget.bookings.fold(0.0, (s, b) => s + (b['total_price'] as num).toDouble());

  bool get _isMulti => widget.bookings.length > 1;

  Future<void> _performCancellation() async {
    setState(() => _isLoading = true);

    double totalRefund = 0;
    bool anySuccess = false;
    String? firstError;

    for (final id in _bookingIds) {
      final res = await CancellationService.cancelBooking(id);
      if (res.result == CancelResult.successWithRefund) {
        totalRefund += res.refundAmount ?? 0;
        anySuccess = true;
      } else if (res.result == CancelResult.success) {
        anySuccess = true;
      } else {
        firstError ??= CancellationService.messageFor(res.result);
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);

    if (anySuccess) {
      _showSuccessDialog(refundAmount: totalRefund > 0 ? totalRefund : null);
    } else {
      _showErrorSnack(
        firstError ?? context.tr.cancelServiceError,
        CancelResult.error,
      );
    }
  }

  void _showSuccessDialog({double? refundAmount}) {
    final hasRefund = refundAmount != null && refundAmount > 0;
    final seatsText = _isMulti ? _seatNumbers.join(', ') : _seatNumbers.first;

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
                  color: hasRefund
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  hasRefund ? Icons.account_balance_wallet_rounded : Icons.cancel_rounded,
                  color: hasRefund ? const Color(0xFF10B981) : AppColors.error,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hasRefund ? 'Refund Processed' : context.tr.cancelSuccessTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isMulti
                    ? context.tr.cancelSuccessDesc(
                        widget.origin, widget.destination, seatsText)
                    : context.tr.cancelSuccessDesc(
                        widget.origin, widget.destination, seatsText),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              if (hasRefund) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Refunded to Wallet',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${refundAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.account_balance_wallet_rounded,
                              size: 14, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text(
                            'Use it for your next booking',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF059669),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr.cancelSuccessNote,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF065F46),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.tr.cancelSheetDone,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
        : AppColors.error;

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
              color: AppColors.border,
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

          Text(
            context.tr.cancelSheetTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr.cancelSheetConfirm,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Booking summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.route_rounded,
                  label: context.tr.cancelSheetRoute,
                  value: '${widget.origin} → ${widget.destination}',
                ),
                const Divider(height: 16, color: AppColors.border),
                 _SummaryRow(
                  icon: Icons.calendar_today_rounded,
                  label: context.tr.bookingDate,
                  value: DateHelpers.formatDate(widget.tripDate),
                ),
                const Divider(height: 16, color: AppColors.border),
                _SummaryRow(
                  icon: Icons.event_seat_rounded,
                  label: context.tr.cancelSheetSeat,
                  value: _seatNumbers.join(', '),
                ),
                const Divider(height: 16, color: AppColors.border),
                _SummaryRow(
                  icon: Icons.attach_money_rounded,
                  label: context.tr.cancelSheetAmount,
                  value: '\$${_totalPrice.toStringAsFixed(2)}',
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFFF97316),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr.cancelSheetPolicy,
                    style: const TextStyle(
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
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    context.tr.cancelSheetKeep,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _performCancellation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
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
                      : Text(
                          context.tr.cancelSheetYesCancel,
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
        Icon(icon, size: 15, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
