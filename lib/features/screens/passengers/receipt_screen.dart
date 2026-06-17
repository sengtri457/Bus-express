import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../services/download_helper.dart';
import '../../../services/receipt_service.dart';

class ReceiptScreen extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;

  const ReceiptScreen({super.key, required this.bookings});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _isGenerating = false;

  double get _totalPrice =>
      widget.bookings.fold<double>(
        0,
        (s, b) => s + (b['total_price'] as num).toDouble(),
      );

  Future<void> _generateAndShare() async {
    setState(() => _isGenerating = true);

    final result = await ReceiptService.generate(bookings: widget.bookings);

    if (!mounted) return;

    switch (result) {
      case Success<Uint8List>(:final data):
        if (kIsWeb) {
          downloadBytes(data, 'BusExpress_Receipt.pdf');
        } else {
          await ReceiptService.share(data, widget.bookings.first['id'] as String);
        }
      case Failure<Uint8List>(:final message):
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
    }

    if (mounted) setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.bookings.first;
    final trip = first['trips'] as Map<String, dynamic>?;
    final schedule = trip?['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;
    final bus = schedule?['buses'] as Map<String, dynamic>?;
    final bookingRef =
        '#${(first['id'] as String).substring(0, 8).toUpperCase()}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Receipt',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgR,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BUS EXPRESS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'OFFICIAL RECEIPT',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _ReceiptLine(label: 'Receipt #', value: bookingRef),
                _ReceiptLine(
                  label: 'Issued',
                  value: DateHelpers.formatFullDate(
                    (first['booked_at'] as String?) ?? DateTime.now().toIso8601String(),
                  ),
                ),
                const Divider(height: 24, color: AppColors.border),
                _ReceiptLine(
                  label: 'Route',
                  value:
                      '${route?['origin'] ?? '?'} \u2192 ${route?['destination'] ?? '?'}',
                ),
                _ReceiptLine(
                  label: 'Date',
                  value: DateHelpers.formatFullDate(
                    (trip?['trip_date'] as String?) ?? '',
                  ),
                ),
                _ReceiptLine(
                  label: 'Departure',
                  value: schedule != null
                      ? DateHelpers.formatTime(
                          schedule['departure_time'] as String,
                        )
                      : '\u2014',
                ),
                if (bus != null)
                  _ReceiptLine(
                    label: 'Bus',
                    value: '${bus['model'] ?? '?'} (${bus['plate_number'] ?? '?'})',
                  ),
                const Divider(height: 24, color: AppColors.border),
                const Text(
                  'Booking Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: AppRadius.smR,
                  ),
                  child: Column(
                    children: [
                      _TableHeader(),
                      ...widget.bookings.map((b) => _TableRow(
                            seat: b['seat_number'] as String,
                            status: b['status'] as String,
                            price:
                                '\$${(b['total_price'] as num).toStringAsFixed(2)}',
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Total: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '\$${_totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  bookingRef,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Thank you for traveling with Bus Express!',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Text(
                  'This is your official receipt. Please keep it for your records.',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateAndShare,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share_rounded, size: 18),
              label: Text(
                _isGenerating ? 'Generating...' : 'Share Receipt (PDF)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _CellText('Seat')),
          Expanded(flex: 2, child: _CellText('Status')),
          Expanded(flex: 2, child: _CellText('Price')),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final String seat;
  final String status;
  final String price;
  const _TableRow({
    required this.seat,
    required this.status,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _CellText(seat)),
          Expanded(flex: 2, child: _CellText(status)),
          Expanded(flex: 2, child: _CellText(price)),
        ],
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  final String text;
  const _CellText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
    );
  }
}
