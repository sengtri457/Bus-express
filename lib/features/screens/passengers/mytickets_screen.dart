import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../supabase_config.dart';
import 'live_tracking_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  final String? newBookingId;
  final int newSeatCount;

  const MyTicketsScreen({super.key, this.newBookingId, this.newSeatCount = 1});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<List<Map<String, dynamic>>> _upcomingGroups = [];
  List<List<Map<String, dynamic>>> _pastGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTickets();
    if (widget.newBookingId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showBookingSuccessDialog(),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final data = await SupabaseConfig.client
          .from('bookings')
          .select('''
            id, seat_number, status, total_price, booked_at,
            trips (
              id, trip_date, status,
              schedules (
                departure_time, arrival_time,
                routes ( name, origin, destination ),
                buses ( model, plate_number )
              )
            ),
            tickets ( id, qr_code, status, scanned_at )
          ''')
          .eq('passenger_id', user.id)
          .not('status', 'eq', 'cancelled')
          .order('booked_at', ascending: false);

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final booking in data as List) {
        final trip = booking['trips'] as Map<String, dynamic>?;
        if (trip == null) continue;
        final tripId = trip['id'] as String;
        grouped.putIfAbsent(tripId, () => []);
        grouped[tripId]!.add(Map<String, dynamic>.from(booking));
      }

      final upcoming = <List<Map<String, dynamic>>>[];
      final past = <List<Map<String, dynamic>>>[];

      for (final group in grouped.values) {
        final trip = group.first['trips'] as Map<String, dynamic>;
        var tripStatus = trip['status'] as String;

        // Skip groups where all seats are cancelled
        final allCancelled = group.every((b) => b['status'] == 'cancelled');
        if (allCancelled) continue;

        if (tripStatus == 'scheduled' || tripStatus == 'in_progress') {
          upcoming.add(group);
        } else {
          past.add(group);
        }
      }

      upcoming.sort(
        (a, b) => (b.first['booked_at'] as String).compareTo(
          a.first['booked_at'] as String,
        ),
      );
      past.sort(
        (a, b) => (b.first['booked_at'] as String).compareTo(
          a.first['booked_at'] as String,
        ),
      );

      if (mounted) {
        setState(() {
          _upcomingGroups = upcoming;
          _pastGroups = past;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBookingSuccessDialog() {
    final count = widget.newSeatCount;
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                count > 1
                    ? '$count Seats Confirmed! 🎉'
                    : 'Booking Confirmed! 🎉',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                count > 1
                    ? 'Your $count tickets are ready. Each seat has its own QR code.'
                    : 'Your ticket is ready. Show the QR code to the conductor when boarding.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    count > 1 ? 'View My Tickets' : 'View My Ticket',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Tickets',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTickets,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: 'Upcoming (${_upcomingGroups.length})'),
            Tab(text: 'Past (${_pastGroups.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _TicketList(
                  groups: _upcomingGroups,
                  emptyMessage: 'No upcoming trips',
                  emptySubMessage: 'Book a bus ticket to see it here',
                  emptyIcon: Icons.confirmation_number_outlined,
                  highlightId: widget.newBookingId,
                  onRefresh: _loadTickets,
                ),
                _TicketList(
                  groups: _pastGroups,
                  emptyMessage: 'No past trips',
                  emptySubMessage: 'Your completed trips will appear here',
                  emptyIcon: Icons.history_rounded,
                  onRefresh: _loadTickets,
                ),
              ],
            ),
    );
  }
}

// ─── Ticket List ──────────────────────────────────────────────────────────────

class _TicketList extends StatelessWidget {
  final List<List<Map<String, dynamic>>> groups;
  final String emptyMessage;
  final String emptySubMessage;
  final IconData emptyIcon;
  final String? highlightId;
  final VoidCallback onRefresh;

  const _TicketList({
    required this.groups,
    required this.emptyMessage,
    required this.emptySubMessage,
    required this.emptyIcon,
    required this.onRefresh,
    this.highlightId,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(emptyIcon, size: 40, color: const Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubMessage,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final isHighlighted = group.any((b) => b['id'] == highlightId);
          return _TicketGroupCard(
            bookings: group,
            isHighlighted: isHighlighted,
            onRefresh: onRefresh,
          );
        },
      ),
    );
  }
}

// ─── Ticket Group Card ────────────────────────────────────────────────────────

class _TicketGroupCard extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final bool isHighlighted;
  final VoidCallback onRefresh;

  const _TicketGroupCard({
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

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            _TicketGroupDetailSheet(bookings: bookings, onRefresh: onRefresh),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isHighlighted
              ? Border.all(color: const Color(0xFF2563EB), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? const Color(0xFF2563EB).withOpacity(0.15)
                  : Colors.black.withOpacity(0.06),
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
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fiber_new_rounded,
                            color: Color(0xFF2563EB),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'New Booking',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2563EB),
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
                            color: Color(0xFF111827),
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
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${bookings.length} seats',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        )
                      else
                        _StatusBadge(
                          status:
                              ((first['tickets'] as List?)?.isNotEmpty == true
                                      ? (first['tickets'] as List)
                                            .first['status']
                                      : 'unknown')
                                  as String,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTripDate(trip?['trip_date']),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _MiniInfo(
                        icon: Icons.access_time_rounded,
                        value: schedule != null
                            ? _formatTime(schedule['departure_time'])
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
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2563EB),
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

                  // Track Bus button
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
                          isLive ? '🟢  Track Live' : 'Track Bus',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLive
                              ? const Color(0xFF10B981)
                              : const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Dashed divider
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
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_rounded,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMulti
                        ? 'Tap to view ${bookings.length} QR codes'
                        : 'Tap to view QR code',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTripDate(String? d) {
    if (d == null) return '—';
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

  String _formatTime(String t) {
    final p = t.split(':');
    final h = int.parse(p[0]);
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${p[1]} $period';
  }
}

// ─── Ticket Group Detail Sheet ────────────────────────────────────────────────

class _TicketGroupDetailSheet extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;
  final VoidCallback onRefresh;

  const _TicketGroupDetailSheet({
    required this.bookings,
    required this.onRefresh,
  });

  @override
  State<_TicketGroupDetailSheet> createState() =>
      _TicketGroupDetailSheetState();
}

class _TicketGroupDetailSheetState extends State<_TicketGroupDetailSheet>
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

  double get _totalPrice => widget.bookings.fold(
    0,
    (s, b) => s + (b['total_price'] as num).toDouble(),
  );

  bool get _isTrackable {
    final trip = widget.bookings.first['trips'] as Map<String, dynamic>?;
    final status = trip?['status'] as String? ?? '';
    return status == 'scheduled' || status == 'in_progress';
  }

  bool get _isLive {
    final trip = widget.bookings.first['trips'] as Map<String, dynamic>?;
    return (trip?['status'] as String?) == 'in_progress';
  }

  // Show cancel button only when: scheduled trip + not boarded + not all cancelled
  bool get _isCancellable {
    final trip = widget.bookings.first['trips'] as Map<String, dynamic>?;
    final status = trip?['status'] as String? ?? '';
    if (status != 'scheduled') return false;
    final anyBoarded = widget.bookings.any((b) => b['status'] == 'boarded');
    final allCancelled = widget.bookings.every(
      (b) => b['status'] == 'cancelled',
    );
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

  // ── Cancel all bookings in this group ──────────────────────────────────────
  Future<void> _cancelBookings() async {
    final trip = widget.bookings.first['trips'] as Map<String, dynamic>?;
    final schedule = trip?['schedules'] as Map<String, dynamic>?;

    // Check 2-hour cutoff
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
          const SnackBar(
            content: Text(
              '⚠️ Cannot cancel — departure is less than 2 hours away.',
            ),
            backgroundColor: Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isCancelling = true);
    int cancelled = 0;

    try {
      for (final booking in widget.bookings) {
        final bookingId = booking['id'] as String;

        // Cancel booking
        await SupabaseConfig.client
            .from('bookings')
            .update({'status': 'cancelled'})
            .eq('id', bookingId);

        // Cancel ticket
        await SupabaseConfig.client
            .from('tickets')
            .update({'status': 'cancelled'})
            .eq('booking_id', bookingId);

        cancelled++;
      }

      if (mounted) {
        Navigator.pop(context); // close sheet
        widget.onRefresh(); // reload ticket list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cancelled > 1
                  ? '✅ $cancelled bookings cancelled'
                  : '✅ Booking cancelled',
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Confirmation dialog before cancelling ──────────────────────────────────
  Future<void> _confirmAndCancel() async {
    final trip = widget.bookings.first['trips'] as Map<String, dynamic>?;
    final schedule = trip?['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;
    final isMulti = widget.bookings.length > 1;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  color: Color(0xFFF59E0B),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isMulti
                    ? 'Cancel ${widget.bookings.length} Seats?'
                    : 'Cancel Booking?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${route?['origin'] ?? '?'} → ${route?['destination'] ?? '?'}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              if (isMulti) ...[
                const SizedBox(height: 4),
                Text(
                  'Seats: ${widget.bookings.map((b) => b['seat_number']).join(', ')}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
              const SizedBox(height: 12),
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
                      size: 14,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cancellations must be made at least 2 hours before departure.',
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Keep It',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Yes, Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${route?['origin'] ?? '?'} → ${route?['destination'] ?? '?'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTripDate(trip?['trip_date']),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price summary
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.bookings.length} seat${widget.bookings.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '•',
                          style: TextStyle(color: Color(0xFF93C5FD)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total \$${_totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Track Bus button ──────────────────────────────────────
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
                          _isLive ? '🟢  Track Live' : 'Track Bus',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLive
                              ? const Color(0xFF10B981)
                              : const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  // ── Cancel Booking button ─────────────────────────────────
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
                                  color: Color(0xFFEF4444),
                                ),
                              )
                            : const Icon(Icons.cancel_outlined, size: 18),
                        label: Text(
                          isMulti
                              ? 'Cancel All ${widget.bookings.length} Seats'
                              : 'Cancel Booking',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),

                  // Seat tabs for multi-seat
                  if (isMulti)
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: const Color(0xFF1A73E8),
                      labelColor: const Color(0xFF1A73E8),
                      unselectedLabelColor: const Color(0xFF9CA3AF),
                      dividerColor: const Color(0xFFE5E7EB),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: widget.bookings
                          .map((b) => Tab(text: 'Seat ${b['seat_number']}'))
                          .toList(),
                    ),
                ],
              ),
            ),

            // Content per seat
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

// ─── Single Ticket View ───────────────────────────────────────────────────────

class _SingleTicketView extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _SingleTicketView({required this.booking});

  @override
  Widget build(BuildContext context) {
    final trip = booking['trips'] as Map<String, dynamic>?;
    final schedule = trip?['schedules'] as Map<String, dynamic>?;
    final ticketsList = booking['tickets'] as List?;
    final ticket = ticketsList != null && ticketsList.isNotEmpty
        ? ticketsList.first
        : null;
    final qrCode = ticket?['qr_code'] as String?;
    final ticketStatus = ticket?['status'] as String? ?? 'unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // QR code card — only shown for valid (unused) tickets
          if (ticketStatus == 'valid' && qrCode != null)
            _QrCodeCard(bookingId: booking['id'] as String, qrCode: qrCode)
          else
            _TicketStatusPlaceholder(status: ticketStatus),

          const SizedBox(height: 12),
          _StatusBadge(status: ticketStatus, large: true),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: 'Departure',
                  value: schedule != null
                      ? _formatTime(schedule['departure_time'])
                      : '—',
                ),
                const Divider(height: 16, color: Color(0xFFE5E7EB)),
                _DetailRow(
                  label: 'Arrival',
                  value: schedule != null
                      ? _formatTime(schedule['arrival_time'])
                      : '—',
                ),
                const Divider(height: 16, color: Color(0xFFE5E7EB)),
                _DetailRow(
                  label: 'Seat',
                  value: booking['seat_number'] as String,
                ),
                const Divider(height: 16, color: Color(0xFFE5E7EB)),
                _DetailRow(
                  label: 'Ticket price',
                  value:
                      '\$${(booking['total_price'] as num).toStringAsFixed(2)}',
                ),
                const Divider(height: 16, color: Color(0xFFE5E7EB)),
                const _DetailRow(label: 'Payment', value: 'Cash on Board'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _InfoBanner(status: ticketStatus),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatTime(String t) {
    final p = t.split(':');
    final h = int.parse(p[0]);
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${p[1]} $period';
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool large;
  const _StatusBadge({required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final configs = {
      'valid': [
        const Color(0xFFD1FAE5),
        const Color(0xFF065F46),
        Icons.check_circle_rounded,
      ],
      'used': [
        const Color(0xFFE0E7FF),
        const Color(0xFF3730A3),
        Icons.done_all_rounded,
      ],
      'expired': [
        const Color(0xFFF3F4F6),
        const Color(0xFF6B7280),
        Icons.timer_off_rounded,
      ],
      'cancelled': [
        const Color(0xFFFEE2E2),
        const Color(0xFF991B1B),
        Icons.cancel_rounded,
      ],
    };
    final cfg =
        configs[status] ??
        [
          const Color(0xFFFEF3C7),
          const Color(0xFF92400E),
          Icons.pending_rounded,
        ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: cfg[0] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            cfg[2] as IconData,
            size: large ? 16 : 12,
            color: cfg[1] as Color,
          ),
          SizedBox(width: large ? 6 : 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: large ? 14 : 11,
              fontWeight: FontWeight.w600,
              color: cfg[1] as Color,
            ),
          ),
        ],
      ),
    );
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
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
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
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
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

// ─── QR Code Card ──────────────────────────────────────────────────────────────

class _QrCodeCard extends StatelessWidget {
  final String bookingId;
  final String qrCode;
  const _QrCodeCard({required this.bookingId, required this.qrCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            errorStateBuilder: (_, __) => const SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: Text(
                  'QR Error',
                  style: TextStyle(color: Color(0xFFEF4444)),
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
              color: Color(0xFF374151),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ticket Status Placeholder ─────────────────────────────────────────────────

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
        message = 'Ticket already used';
        color = const Color(0xFF6B7280);
      case 'cancelled':
        icon = Icons.cancel_rounded;
        message = 'Ticket cancelled';
        color = const Color(0xFFEF4444);
      case 'expired':
        icon = Icons.timer_off_rounded;
        message = 'Ticket expired';
        color = const Color(0xFF9CA3AF);
      default:
        icon = Icons.help_outline_rounded;
        message = 'No ticket data';
        color = const Color(0xFF9CA3AF);
    }

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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

// ─── Info Banner ───────────────────────────────────────────────────────────────

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
        text = 'Show this QR code to the conductor. Pay cash when boarding.';
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFF92400E);
        iconColor = const Color(0xFFF59E0B);
      case 'used':
        icon = Icons.check_circle_outline_rounded;
        text = 'This ticket has already been used for boarding.';
        bgColor = const Color(0xFFF3F4F6);
        borderColor = const Color(0xFFE5E7EB);
        textColor = const Color(0xFF6B7280);
        iconColor = const Color(0xFF6B7280);
      case 'cancelled':
        icon = Icons.cancel_outlined;
        text = 'This booking has been cancelled.';
        bgColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFFCA5A5);
        textColor = const Color(0xFF991B1B);
        iconColor = const Color(0xFFEF4444);
      case 'expired':
        icon = Icons.timer_off_outlined;
        text = 'This ticket has expired.';
        bgColor = const Color(0xFFF3F4F6);
        borderColor = const Color(0xFFE5E7EB);
        textColor = const Color(0xFF6B7280);
        iconColor = const Color(0xFF9CA3AF);
      default:
        icon = Icons.help_outline_rounded;
        text = 'Ticket status is unknown.';
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFF92400E);
        iconColor = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
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
