import 'package:flutter/material.dart';
import '../../../supabase_config.dart';
import '../../auth/login_screen.dart';
import 'driver_trips_screen.dart';
import 'trip_punctuality.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  List<Map<String, dynamic>> _todayTrips = [];
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _upcomingTrips = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Auto-end overdue trips in real-time
      await SupabaseConfig.syncOverdueTrips();

      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      debugPrint('[Driver] Loading data for user: ${user.id}');

      // Load profile
      final profile = await SupabaseConfig.client
          .from('users')
          .select('name, phone, email, operator_id')
          .eq('id', user.id)
          .maybeSingle();

      debugPrint('[Driver] Profile: $profile');

      // Sync/Spawn today's trips from active schedules in background
      final today = DateTime.now().toLocal().toIso8601String().split('T')[0];
      final weekday = DateTime.now().weekday.toString();
      try {
        final schedules = await SupabaseConfig.client
            .from('schedules')
            .select('id, days_of_week, bus_id, driver_id, conductor_id, status')
            .eq('driver_id', user.id)
            .eq('status', 'active');

        final activeTodaySchedules =
            List<Map<String, dynamic>>.from(schedules as List).where((s) {
              final days = (s['days_of_week'] as String? ?? '').split(',');
              return days.contains(weekday);
            }).toList();

        for (final sched in activeTodaySchedules) {
          // Check if trip already exists for today
          final tripExists = await SupabaseConfig.client
              .from('trips')
              .select('id')
              .eq('schedule_id', sched['id'])
              .eq('trip_date', today)
              .maybeSingle();

          if (tripExists == null) {
            debugPrint(
              '[Driver Sync] Auto-spawning trip for schedule ${sched['id']} on $today',
            );
            await SupabaseConfig.client.from('trips').insert({
              'schedule_id': sched['id'],
              'trip_date': today,
              'bus_id': sched['bus_id'],
              'driver_id': user.id,
              'conductor_id': sched['conductor_id'],
              'status': 'scheduled',
            });
          }
        }
      } catch (e) {
        debugPrint('[Driver Sync] Error auto-spawning trips: $e');
      }

      // Auto-complete any newly spawned trips whose departure time has already passed
      await SupabaseConfig.syncOverdueTrips();

      // Load today's and upcoming trips
      debugPrint(
        '[Driver] Querying trips for date >= $today, driver_id=${user.id}',
      );

      final trips = await SupabaseConfig.client
          .from('trips')
          .select('''
            id, trip_date, status, departed_at, arrived_at,
            schedules (
              departure_time, arrival_time, price,
              routes ( name, origin, destination, distance_km, duration_min ),
              buses ( model, plate_number, capacity )
            )
          ''')
          .eq('driver_id', user.id)
          .gte('trip_date', today)
          .order('trip_date');

      debugPrint('[Driver] Raw trips result: $trips');
      debugPrint('[Driver] Total trips found: ${(trips as List).length}');

      if (mounted) {
        setState(() {
          _userProfile = profile;
          final tripList = List<Map<String, dynamic>>.from(trips);

          // Get all today's trips and sort them so those with valid schedules come first
          final todayList = tripList
              .where((t) => t['trip_date'] == today)
              .toList();
          todayList.sort((a, b) {
            if (a['schedules'] != null && b['schedules'] == null) return -1;
            if (a['schedules'] == null && b['schedules'] != null) return 1;
            return 0;
          });
          _todayTrips = todayList;

          _upcomingTrips = tripList
              .where((t) => t['trip_date'] != today)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[Driver] ERROR loading data: $e');
      debugPrint('[Driver] Stack: $stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _signOut() async {
    await SupabaseConfig.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 160,
                    pinned: true,
                    backgroundColor: const Color(0xFF0D47A1),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _loadData,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _signOut,
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.drive_eta_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hello, ${_userProfile?['name']?.split(' ').first ?? 'Driver'} 👋',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Driver Dashboard',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _formatFullDate(DateTime.now()),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Today's Trip
                          const Text(
                            "Today's Trip",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _todayTrips.isNotEmpty
                              ? Column(
                                  children: _todayTrips
                                      .map(
                                        (trip) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          child: _TodayTripCard(
                                            trip: trip,
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      DriverTripScreen(
                                                        trip: trip,
                                                      ),
                                                ),
                                              );
                                              _loadData();
                                            },
                                          ),
                                        ),
                                      )
                                      .toList(),
                                )
                              : _NoTripCard(),
                          const SizedBox(height: 28),

                          // Upcoming Trips
                          if (_upcomingTrips.isNotEmpty) ...[
                            const Text(
                              'Upcoming Trips',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ..._upcomingTrips.map(
                              (trip) => _UpcomingTripCard(trip: trip),
                            ),
                          ],

                          // Stats
                          const SizedBox(height: 8),
                          const Text(
                            'Quick Stats',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _StatsRow(
                            driverId:
                                SupabaseConfig.client.auth.currentUser!.id,
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

  Widget _buildErrorView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime d) {
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
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Today Trip Card ──────────────────────────────────────────────────────────

class _TodayTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onTap;
  const _TodayTripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final schedule = trip['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;
    final bus = schedule?['buses'] as Map<String, dynamic>?;
    final status = trip['status'] as String;

    if (schedule == null) {
      return _buildNoScheduleCard(status);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A73E8).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/HomeBanner.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1565C0).withOpacity(0.85),
                      Color(0xFF0D47A1).withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _TripStatusBadge(status: status),
                    _TripPunctualityBadge(trip: trip),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to manage',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Route
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(schedule['departure_time'] ?? ''),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      route?['origin'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${route?['duration_min'] ?? ''} min',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${route?['distance_km'] ?? ''} km',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(schedule['arrival_time'] ?? ''),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      route?['destination'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),

            // Bus info
            Row(
              children: [
                const Icon(
                  Icons.directions_bus_outlined,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${bus?['model'] ?? ''} • ${bus?['plate_number'] ?? ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.event_seat_outlined,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${bus?['capacity'] ?? ''} seats',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
        ],
      ),
      ),
    );
  }

  Widget _buildNoScheduleCard(String status) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/HomeBanner.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1565C0).withOpacity(0.85),
                    Color(0xFF0D47A1).withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        status[0].toUpperCase() +
                            status.substring(1).replaceAll('_', ' '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
                const SizedBox(height: 10),
                const Text(
                  'No schedule assigned',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This trip has no schedule linked.\nContact your operator to fix it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String t) {
    if (t.isEmpty) return '';
    final p = t.split(':');
    final h = int.parse(p[0]);
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${p[1]} $period';
  }
}

// ─── No Trip Card ─────────────────────────────────────────────────────────────

class _NoTripCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/HomeBanner.webp',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.85)),
          ),
          const Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              children: [
                Icon(
                  Icons.free_cancellation_rounded,
                  size: 48,
                  color: Color(0xFF9CA3AF),
                ),
                SizedBox(height: 12),
                Text(
                  'No trip today',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'You have no scheduled trips for today',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming Trip Card ───────────────────────────────────────────────────────

class _UpcomingTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _UpcomingTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final schedule = trip['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/HomeBanner.webp',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.85)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF1A73E8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${route?['origin'] ?? ''} → ${route?['destination'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(trip['trip_date'])} • ${_formatTime(schedule?['departure_time'] ?? '')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                _TripStatusBadge(status: trip['status'] as String, small: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String d) {
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
    return '${dt.day} ${m[dt.month - 1]}';
  }

  String _formatTime(String t) {
    if (t.isEmpty) return '';
    final p = t.split(':');
    final h = int.parse(p[0]);
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${p[1]} $period';
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatefulWidget {
  final String driverId;
  const _StatsRow({required this.driverId});

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  int _totalTrips = 0;
  int _completedTrips = 0;
  int _totalPassengers = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final trips = await SupabaseConfig.client
          .from('trips')
          .select('id, status')
          .eq('driver_id', widget.driverId);

      final tripIds = (trips as List).map((t) => t['id'] as String).toList();
      int passengers = 0;
      if (tripIds.isNotEmpty) {
        final bookings = await SupabaseConfig.client
            .from('bookings')
            .select('id')
            .inFilter('trip_id', tripIds)
            .inFilter('status', ['confirmed', 'boarded']);
        passengers = (bookings as List).length;
      }

      if (mounted) {
        setState(() {
          _totalTrips = trips.length;
          _completedTrips = trips
              .where((t) => t['status'] == 'completed')
              .length;
          _totalPassengers = passengers;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Trips',
            value: '$_totalTrips',
            icon: Icons.route_rounded,
            color: const Color(0xFF1A73E8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Completed',
            value: '$_completedTrips',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Passengers',
            value: '$_totalPassengers',
            icon: Icons.people_rounded,
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/HomeBanner.webp',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.85)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trip Status Badge ────────────────────────────────────────────────────────

class _TripStatusBadge extends StatelessWidget {
  final String status;
  final bool small;
  const _TripStatusBadge({required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final configs = {
      'scheduled': [
        const Color(0xFFEFF6FF),
        const Color(0xFF1A73E8),
        Icons.schedule_rounded,
      ],
      'in_progress': [
        const Color(0xFFD1FAE5),
        const Color(0xFF10B981),
        Icons.play_circle_rounded,
      ],
      'completed': [
        const Color(0xFFF3F4F6),
        const Color(0xFF6B7280),
        Icons.check_circle_rounded,
      ],
      'cancelled': [
        const Color(0xFFFEE2E2),
        const Color(0xFFEF4444),
        Icons.cancel_rounded,
      ],
    };
    final cfg =
        configs[status] ??
        [
          const Color(0xFFFEF3C7),
          const Color(0xFFF59E0B),
          Icons.pending_rounded,
        ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
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
            size: small ? 10 : 12,
            color: cfg[1] as Color,
          ),
          SizedBox(width: small ? 3 : 5),
          Text(
            status == 'in_progress'
                ? 'In Progress'
                : status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: cfg[1] as Color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trip Punctuality Badge ───────────────────────────────────────────────────
class _TripPunctualityBadge extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripPunctualityBadge({required this.trip});

  @override
  Widget build(BuildContext context) {
    final punctuality = TripPunctuality.calculate(trip);

    // If it's unknown or scheduled and not delayed, let's keep it simple or not show it if preferred.
    // Showing it always provides premium visibility.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: punctuality.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: punctuality.color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            punctuality.icon,
            color: Colors.white,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            punctuality.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
