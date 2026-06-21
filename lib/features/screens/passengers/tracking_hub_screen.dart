import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/booking_model.dart';
import '../../../supabase_config.dart';
import 'live_tracking_screen.dart';

class TrackingHubScreen extends StatefulWidget {
  const TrackingHubScreen({super.key});

  @override
  State<TrackingHubScreen> createState() => _TrackingHubScreenState();
}

class _TrackingHubScreenState extends State<TrackingHubScreen> {
  List<BookingModel> _activeBookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final data = await SupabaseConfig.client
          .from('bookings')
          .select('''
            id, trip_id, passenger_id, seat_number, status, total_price,
            booked_at, booking_channel,
            passenger_name, passenger_age, passenger_phone, passenger_nationality,
            trips (
              id, trip_date, status,
              schedules (
                id, departure_time, arrival_time,
                routes ( origin, destination )
              ),
              buses ( plate_number )
            )
          ''')
          .eq('passenger_id', user.id)
          .inFilter('status', ['confirmed', 'boarded'])
          .order('booked_at', ascending: false);

      _activeBookings = (data as List)
          .map((e) => BookingModel.fromMap(e as Map<String, dynamic>))
          .where((b) =>
              b.trip?.status == 'in_progress' || b.trip?.status == 'scheduled')
          .toList();
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Live Tracking',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _activeBookings.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _activeBookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) =>
                          _buildBookingCard(_activeBookings[i]),
                    ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pin_drop_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No active trips',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            Text(
              'Your in-progress and upcoming\nbookings will show here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final trip = booking.trip;
    final schedule = trip?.schedule;
    final route = schedule?.route;
    final isInProgress = trip?.status == 'in_progress';
    final dateStr = trip?.tripDate != null
        ? DateFormat('MMM d').format(DateTime.parse(trip!.tripDate))
        : '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveTrackingScreen(
              tripId: trip?.id ?? '',
              origin: route?.origin ?? '',
              destination: route?.destination ?? '',
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isInProgress
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isInProgress
                          ? Icons.directions_bus_rounded
                          : Icons.schedule_rounded,
                      color: isInProgress
                          ? const Color(0xFF059669)
                          : const Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isInProgress
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isInProgress ? 'LIVE' : 'Upcoming',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isInProgress
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                            if (dateStr.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(dateStr,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500])),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${route?.origin ?? ''} → ${route?.destination ?? ''}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isInProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me_rounded,
                              size: 14, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text('TRACK',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              )),
                        ],
                      ),
                    ),
                  if (!isInProgress)
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey[400], size: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
