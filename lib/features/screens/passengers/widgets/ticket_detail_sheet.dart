import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../l10n/tr_extension.dart';
import '../../../../shared/widgets/star_rating.dart';
import '../../../../shared/widgets/trip_status_badge.dart';
import '../../../../supabase_config.dart';
import '../live_tracking_screen.dart';
import 'review_sheet.dart';

class TicketDetailSheet extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;
  final VoidCallback onRefresh;

  const TicketDetailSheet({
    super.key,
    required this.bookings,
    required this.onRefresh,
  });

  @override
  State<TicketDetailSheet> createState() => _TicketDetailSheetState();
}

class _TicketDetailSheetState extends State<TicketDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.bookings.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _totalPrice =>
      widget.bookings.fold(0, (s, b) => s + (b['total_price'] as num).toDouble());

  bool get _isTrackable {
    final trip = widget.bookings.first['trips'] as Map<String, dynamic>?;
    final status = trip?['status'] as String? ?? '';
    return status == 'scheduled' || status == 'in_progress';
  }

  bool get _isLive {
    final trip = widget.bookings.first['trips'] as Map<String, dynamic>?;
    return (trip?['status'] as String?) == 'in_progress';
  }

  bool get _isCancellable {
    final trip = widget.bookings.first['trips'] as Map<String, dynamic>?;
    final status = trip?['status'] as String? ?? '';
    if (status != 'scheduled') return false;
    final anyBoarded = widget.bookings.any((b) => b['status'] == 'boarded');
    final allCancelled = widget.bookings.every((b) => b['status'] == 'cancelled');
    return !anyBoarded && !allCancelled;
  }

  void _openTracking() {
    final trip = widget.bookings.first['trips'] as Map<String, dynamic>?;
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

  Future<void> _cancelBookings() async {
    final trip = widget.bookings.first['trips'] as Map<String, dynamic>?;
    final schedule = trip?['schedules'] as Map<String, dynamic>?;

    if (trip != null && schedule != null) {
      final tripDate = trip['trip_date'] as String;
      final depTime = schedule['departure_time'] as String;
      final depParts = depTime.split(':');
      final departure = DateTime(
        int.parse(tripDate.split('-')[0]),
        int.parse(tripDate.split('-')[1]),
        int.parse(tripDate.split('-')[2]),
        int.parse(depParts[0]),
        int.parse(depParts[1]),
      );
      if (departure.difference(DateTime.now()).inMinutes < 120) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.ticketDetailCancelTooLate,
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isCancelling = true);

    try {
      for (final booking in widget.bookings) {
        final bookingId = booking['id'] as String;
        await SupabaseConfig.client
            .from('bookings')
            .update({'status': 'cancelled'})
            .eq('id', bookingId);
        await SupabaseConfig.client
            .from('tickets')
            .update({'status': 'cancelled'})
            .eq('booking_id', bookingId);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.bookings.length > 1
                  ? context.tr.ticketDetailCancelledPlural(widget.bookings.length)
                  : context.tr.ticketDetailCancelledSingular,
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.ticketDetailErrorPrefix('$e')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndCancel() async {
    final trip = widget.bookings.first['trips'] as Map<String, dynamic>?;
    final schedule = trip?['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;
    final isMulti = widget.bookings.length > 1;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgR),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isMulti
                    ? context.tr.ticketDetailConfirmCancelTitlePlural(widget.bookings.length)
                    : context.tr.ticketDetailConfirmCancelTitleSingular,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${route?['origin'] ?? '?'} → ${route?['destination'] ?? '?'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isMulti) ...[
                const SizedBox(height: 4),
                Text(
                  'Seats: ${widget.bookings.map((b) => b['seat_number']).join(', ')}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: AppRadius.smR,
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.access_time_rounded, color: Color(0xFFF97316), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr.ticketDetailConfirmPolicy,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9A3412),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.tr.ticketDetailKeepIt),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: Text(context.tr.ticketDetailYesCancel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) _cancelBookings();
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.bookings.first;
    final trip = first['trips'] as Map<String, dynamic>?;
    final schedule = trip?['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;
    final isMulti = widget.bookings.length > 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${route?['origin'] ?? '?'} → ${route?['destination'] ?? '?'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTripDate(trip?['trip_date']),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.mdR,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr.ticketDetailSeatCount(widget.bookings.length),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('•', style: TextStyle(color: Color(0xFF93C5FD))),
                        const SizedBox(width: 8),
                        Text(
                          context.tr.ticketDetailTotal('\$${_totalPrice.toStringAsFixed(2)}'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isTrackable)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _openTracking,
                        icon: Icon(
                          _isLive
                              ? Icons.my_location_rounded
                              : Icons.location_on_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _isLive ? context.tr.ticketDetailTrackLive : context.tr.ticketDetailTrackBus,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isLive ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                  if (_isCancellable) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isCancelling ? null : _confirmAndCancel,
                        icon: _isCancelling
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.error,
                                ),
                              )
                            : const Icon(Icons.cancel_outlined, size: 18),
                        label: Text(
                          isMulti
                              ? context.tr.ticketDetailCancelAll(widget.bookings.length)
                              : context.tr.ticketDetailCancelBooking,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  if (isMulti)
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textHint,
                      dividerColor: AppColors.border,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: widget.bookings
                          .map((b) => Tab(text: context.tr.ticketDetailSeatTab('${b['seat_number']}')))
                          .toList(),
                    ),
                ],
              ),
            ),
            Expanded(
              child: isMulti
                  ? TabBarView(
                      controller: _tabController,
                      children: widget.bookings
                          .map((b) => _SingleTicketView(booking: b))
                          .toList(),
                    )
                  : _SingleTicketView(booking: first),
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

class _SingleTicketView extends StatefulWidget {
  final Map<String, dynamic> booking;
  const _SingleTicketView({required this.booking});

  @override
  State<_SingleTicketView> createState() => _SingleTicketViewState();
}

class _SingleTicketViewState extends State<_SingleTicketView> {
  Map<String, dynamic>? _review;
  bool _loadingReview = true;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      final data = await SupabaseConfig.client
          .from('reviews')
          .select('rating, comment, driver_rating, created_at')
          .eq('booking_id', widget.booking['id'] as String)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _review = data;
          _loadingReview = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReview = false);
    }
  }

  bool get _isPastTrip {
    final ticketsList = widget.booking['tickets'] as List?;
    if (ticketsList == null || ticketsList.isEmpty) return true;
    final status = ticketsList.first['status'] as String? ?? '';
    return status == 'used' || status == 'expired';
  }

  void _openReviewSheet(BuildContext context) {
    final trip = widget.booking['trips'] as Map<String, dynamic>?;
    final schedule = trip?['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewSheet(
        bookingId: widget.booking['id'] as String,
        tripId: trip?['id'] as String? ?? '',
        driverId: trip?['driver_id'] as String?,
        driverName: null,
        origin: route?['origin'] as String? ?? '?',
        destination: route?['destination'] as String? ?? '?',
        onSubmitted: _loadReview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.booking['trips'] as Map<String, dynamic>?;
    final schedule = trip?['schedules'] as Map<String, dynamic>?;
    final ticketsList = widget.booking['tickets'] as List?;
    final ticket = ticketsList != null && ticketsList.isNotEmpty
        ? ticketsList.first
        : null;
    final qrCode = ticket?['qr_code'] as String?;
    final ticketStatus = ticket?['status'] as String? ?? 'unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (ticketStatus == 'valid' && qrCode != null)
            _QrCodeCard(bookingId: widget.booking['id'] as String, qrCode: qrCode)
          else
            _TicketStatusPlaceholder(status: ticketStatus),
          const SizedBox(height: 12),
          TripStatusBadge(status: ticketStatus, fontSize: 14),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.lgR,
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: context.tr.ticketDetailDeparture,
                  value: schedule != null
                      ? DateHelpers.formatTime(
                          schedule['departure_time'] as String,
                        )
                      : '—',
                ),
                const Divider(height: 16, color: AppColors.border),
                _DetailRow(
                  label: context.tr.ticketDetailArrival,
                  value: schedule != null
                      ? DateHelpers.formatTime(
                          schedule['arrival_time'] as String,
                        )
                      : '—',
                ),
                const Divider(height: 16, color: AppColors.border),
                _DetailRow(
                  label: 'Seat',
                  value: widget.booking['seat_number'] as String,
                ),
                const Divider(height: 16, color: AppColors.border),
                _DetailRow(
                  label: context.tr.ticketDetailTicketPrice,
                  value: '\$${(widget.booking['total_price'] as num).toStringAsFixed(2)}',
                ),
                const Divider(height: 16, color: AppColors.border),
                _DetailRow(
                  label: context.tr.ticketDetailPayment,
                  value: context.tr.bookingCashOnBoard,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoBanner(status: ticketStatus),
          if (_isPastTrip) ...[
            const SizedBox(height: 20),
            _buildReviewSection(context),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    if (_loadingReview) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.lgR,
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_review != null) {
      final rating = _review!['rating'] as int;
      final comment = _review!['comment'] as String? ?? '';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: AppRadius.lgR,
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text(
                  'Your Review',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StarRating(rating: rating, size: 18, spacing: 2),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                comment,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openReviewSheet(context),
        icon: const Icon(Icons.star_border_rounded, size: 18),
        label: const Text(
          'Rate this trip',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _QrCodeCard extends StatelessWidget {
  final String bookingId;
  final String qrCode;
  const _QrCodeCard({required this.bookingId, required this.qrCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlR,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          QrImageView(
            data: qrCode,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            errorStateBuilder: (_, __) => SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: Text(
                  context.tr.ticketDetailQrError,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '#${bookingId.substring(0, 8).toUpperCase()}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketStatusPlaceholder extends StatelessWidget {
  final String status;
  const _TicketStatusPlaceholder({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String message;
    Color color;

    switch (status) {
      case 'used':
        icon = Icons.check_circle_rounded;
        message = context.tr.ticketDetailStatusUsed;
        color = AppColors.textSecondary;
      case 'cancelled':
        icon = Icons.cancel_rounded;
        message = context.tr.ticketDetailStatusCancelled;
        color = AppColors.error;
      case 'expired':
        icon = Icons.timer_off_rounded;
        message = context.tr.ticketDetailStatusExpired;
        color = AppColors.textHint;
      default:
        icon = Icons.help_outline_rounded;
        message = context.tr.ticketDetailStatusNoData;
        color = AppColors.textHint;
    }

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlR,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: color),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String status;
  const _InfoBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String text;
    Color bgColor;
    Color borderColor;
    Color textColor;
    Color iconColor;

    switch (status) {
      case 'valid':
        icon = Icons.info_outline_rounded;
        text = context.tr.ticketDetailInfoValid;
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFF92400E);
        iconColor = AppColors.warning;
      case 'used':
        icon = Icons.check_circle_outline_rounded;
        text = context.tr.ticketDetailInfoUsed;
        bgColor = const Color(0xFFF3F4F6);
        borderColor = AppColors.border;
        textColor = AppColors.textSecondary;
        iconColor = AppColors.textSecondary;
      case 'cancelled':
        icon = Icons.cancel_outlined;
        text = context.tr.ticketDetailInfoCancelled;
        bgColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFFCA5A5);
        textColor = const Color(0xFF991B1B);
        iconColor = AppColors.error;
      case 'expired':
        icon = Icons.timer_off_outlined;
        text = context.tr.ticketDetailInfoExpired;
        bgColor = const Color(0xFFF3F4F6);
        borderColor = AppColors.border;
        textColor = AppColors.textSecondary;
        iconColor = AppColors.textHint;
      default:
        icon = Icons.help_outline_rounded;
        text = context.tr.ticketDetailInfoUnknown;
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFF92400E);
        iconColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.mdR,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: textColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
