import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../repositories/booking_repository.dart';
import '../../widgets/animations.dart';
import 'widgets/ticket_card.dart';

class MyTicketsScreen extends StatefulWidget {
  final String? newBookingId;
  final int newSeatCount;

  const MyTicketsScreen({
    super.key,
    this.newBookingId,
    this.newSeatCount = 1,
  });

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
      final user = BookingRepository().client.auth.currentUser;
      if (user == null) return;

      final data = await BookingRepository()
          .client
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
        final tripStatus = trip['status'] as String;
        final allCancelled = group.every((b) => b['status'] == 'cancelled');
        if (allCancelled) continue;
        if (tripStatus == 'scheduled' || tripStatus == 'in_progress') {
          upcoming.add(group);
        } else {
          past.add(group);
        }
      }

      upcoming.sort((a, b) => (b.first['booked_at'] as String).compareTo(
        a.first['booked_at'] as String,
      ));
      past.sort((a, b) => (b.first['booked_at'] as String).compareTo(
        a.first['booked_at'] as String,
      ));

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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlR),
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
                  color: AppColors.success,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                count > 1
                    ? '$count Seats Confirmed!'
                    : 'Booking Confirmed!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
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
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: SkeletonList(count: 4),
            )
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
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                emptyIcon,
                size: 40,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubMessage,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              ),
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
          return TicketGroupCard(
            bookings: group,
            isHighlighted: isHighlighted,
            onRefresh: onRefresh,
          );
        },
      ),
    );
  }
}
