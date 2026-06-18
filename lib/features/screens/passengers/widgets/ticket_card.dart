import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../l10n/tr_extension.dart';
import '../../../../shared/widgets/trip_status_badge.dart';
import '../live_tracking_screen.dart';
import '../receipt_screen.dart';
import 'ticket_detail_sheet.dart';

class TicketGroupCard extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final bool isHighlighted;
  final VoidCallback onRefresh;

  const TicketGroupCard({
    super.key,
    required this.bookings,
    required this.onRefresh,
    this.isHighlighted = false,
  });

  double get _groupTotal =>
      bookings.fold(0, (sum, b) => sum + (b['total_price'] as num).toDouble());

  List<String> get _seats =>
      bookings.map((b) => b['seat_number'] as String).toList();

  bool _isTrackable(Map<String, dynamic>? trip) {
    if (trip == null) return false;
    final status = trip['status'] as String? ?? '';
    return status == 'scheduled' || status == 'in_progress';
  }

  void _openTracking(BuildContext context, Map<String, dynamic>? trip) {
    if (trip == null) return;
    final schedule = trip['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTrackingScreen(
          tripId: trip['id'] as String,
          origin: route?['origin'] as String? ?? '?',
          destination: route?['destination'] as String? ?? '?',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = bookings.first;
    final trip = first['trips'] as Map<String, dynamic>?;
    final schedule = trip?['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;
    final isMulti = bookings.length > 1;
    final trackable = _isTrackable(trip);
    final isLive = (trip?['status'] as String?) == 'in_progress';

    final ticketsList = first['tickets'] as List?;
    final ticketStatus = ticketsList != null && ticketsList.isNotEmpty
        ? ticketsList.first['status'] as String
        : 'unknown';

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TicketDetailSheet(
          bookings: bookings,
          onRefresh: onRefresh,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgR,
          border: isHighlighted
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isHighlighted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fiber_new_rounded,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.tr.ticketCardNewBooking,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${route?['origin'] ?? '?'} → ${route?['destination'] ?? '?'}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isMulti)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            context.tr.ticketCardSeats(bookings.length),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else
                        TripStatusBadge(status: ticketStatus),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTripDate(trip?['trip_date']),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniInfo(
                        icon: Icons.access_time_rounded,
                        value: schedule != null
                            ? DateHelpers.formatTime(
                                schedule['departure_time'] as String,
                              )
                            : '—',
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          children: _seats
                              .map(
                                (s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MiniInfo(
                        icon: Icons.attach_money_rounded,
                        value: '\$${_groupTotal.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  if (trackable) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () => _openTracking(context, trip),
                        icon: Icon(
                          isLive
                              ? Icons.my_location_rounded
                              : Icons.location_on_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isLive ? context.tr.ticketCardTrackLive : context.tr.ticketCardTrackBus,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLive
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (_, constraints) => Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    (constraints.maxWidth / 8).floor(),
                    (_) => Container(
                      width: 4,
                      height: 1,
                      color: AppColors.border,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMulti
                        ? context.tr.ticketCardViewQrPlural(bookings.length)
                        : context.tr.ticketCardViewQrSingular,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                    size: 16,
                  ),
                ],
              ),
            ),
            if (!trackable)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptScreen(bookings: bookings),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr.ticketCardViewReceipt,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTripDate(String? d) {
    if (d == null) return '—';
    return DateHelpers.formatFullDate(d);
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String value;
  const _MiniInfo({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
