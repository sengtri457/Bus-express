import 'package:flutter/material.dart';
import '../../../supabase_config.dart';
import '../../auth/login_screen.dart';
import 'conductor_passengers_screen.dart';
import 'conductor_scanner_screen.dart';

class ConductorHomeScreen extends StatefulWidget {
  const ConductorHomeScreen({super.key});

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  List<Map<String, dynamic>> _todayTrips = [];
  int _selectedTripIndex = 0;
  Map<String, dynamic>? _todayTrip;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalPassengers = 0;
  int _boardedCount = 0;
  int _confirmedCount = 0;

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

      debugPrint('[Conductor] Loading data for user: ${user.id}');

      // Load profile
      final profile = await SupabaseConfig.client
          .from('users')
          .select('name, phone, email')
          .eq('id', user.id)
          .maybeSingle();

      debugPrint('[Conductor] Profile: $profile');

      // Sync/Spawn today's trips from active schedules in background
      final today = DateTime.now().toLocal().toIso8601String().split('T')[0];
      final weekday = DateTime.now().weekday.toString();
      try {
        final schedules = await SupabaseConfig.client
            .from('schedules')
            .select('id, days_of_week, bus_id, driver_id, conductor_id, status')
            .eq('conductor_id', user.id)
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
              '[Conductor Sync] Auto-spawning trip for schedule ${sched['id']} on $today',
            );
            await SupabaseConfig.client.from('trips').insert({
              'schedule_id': sched['id'],
              'trip_date': today,
              'bus_id': sched['bus_id'],
              'driver_id': sched['driver_id'],
              'conductor_id': user.id,
              'status': 'scheduled',
            });
          }
        }
      } catch (e) {
        debugPrint('[Conductor Sync] Error auto-spawning trips: $e');
      }

      // Load today's trip
      debugPrint(
        '[Conductor] Querying trips for date=$today, conductor_id=${user.id}',
      );

      final tripsResponse = await SupabaseConfig.client
          .from('trips')
          .select('''
            id, trip_date, status, departed_at,
            schedules (
              departure_time, arrival_time,
              routes ( name, origin, destination, distance_km, duration_min ),
              buses ( model, plate_number, capacity )
            )
          ''')
          .eq('conductor_id', user.id)
          .eq('trip_date', today);

      debugPrint('[Conductor] Today trips result list: $tripsResponse');
      final tripList = List<Map<String, dynamic>>.from(tripsResponse as List);

      // Sort today's trips so those with valid schedules come first
      tripList.sort((a, b) {
        if (a['schedules'] != null && b['schedules'] == null) return -1;
        if (a['schedules'] == null && b['schedules'] != null) return 1;
        return 0;
      });
      _todayTrips = tripList;

      if (_selectedTripIndex >= _todayTrips.length) {
        _selectedTripIndex = 0;
      }
      final todayTrip = _todayTrips.isNotEmpty
          ? _todayTrips[_selectedTripIndex]
          : null;

      // Load booking counts
      if (todayTrip != null) {
        debugPrint(
          '[Conductor] Found trip id=${todayTrip['id']}, loading bookings...',
        );
        final bookings = await SupabaseConfig.client
            .from('bookings')
            .select('id, status')
            .eq('trip_id', todayTrip['id'])
            .inFilter('status', ['confirmed', 'boarded', 'pending']);

        debugPrint('[Conductor] Bookings count: ${(bookings as List).length}');
        final bookingList = List<Map<String, dynamic>>.from(bookings);
        if (mounted) {
          setState(() {
            _todayTrip = todayTrip;
            _userProfile = profile;
            _totalPassengers = bookingList.length;
            _boardedCount = bookingList
                .where((b) => b['status'] == 'boarded')
                .length;
            _confirmedCount = bookingList
                .where((b) => b['status'] == 'confirmed')
                .length;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('[Conductor] No trip found for today.');
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _todayTrip = null;
            _totalPassengers = 0;
            _boardedCount = 0;
            _confirmedCount = 0;
            _isLoading = false;
          });
        }
      }
    } catch (e, stack) {
      debugPrint('[Conductor] ERROR loading data: $e');
      debugPrint('[Conductor] Stack: $stack');
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
                    backgroundColor: const Color(0xFF2563EB),
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
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/conductorBus.jpg',
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xB32563EB),
                                  Color(0xB31D4ED8),
                                ],
                              ),
                            ),
                          ),
                          SafeArea(
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
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.confirmation_number_rounded,
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
                                            'Hello, ${_userProfile?['name']?.split(' ').first ?? 'Conductor'} 👋',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Conductor Dashboard',
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
                                    _formatDate(DateTime.now()),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Boarding stats
                          if (_todayTrip != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total',
                                    value: '$_totalPassengers',
                                    icon: Icons.people_rounded,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Boarded',
                                    value: '$_boardedCount',
                                    icon: Icons.check_circle_rounded,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Waiting',
                                    value: '$_confirmedCount',
                                    icon: Icons.pending_rounded,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Today's trip
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
                                  children: _todayTrips.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final trip = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: _TodayTripCard(
                                        trip: trip,
                                        isSelected: index == _selectedTripIndex,
                                        onTap: () {
                                          if (index != _selectedTripIndex) {
                                            setState(() {
                                              _selectedTripIndex = index;
                                            });
                                            _loadData();
                                          }
                                        },
                                      ),
                                    );
                                  }).toList(),
                                )
                              : _NoTripCard(),

                          // Quick actions
                          if (_todayTrip != null) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionCard(
                                    icon: Icons.qr_code_scanner_rounded,
                                    label: 'Scan Ticket',
                                    color: const Color(0xFF2563EB),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ConductorScannerScreen(
                                          tripId: _todayTrip!['id'],
                                        ),
                                      ),
                                    ).then((_) => _loadData()),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionCard(
                                    icon: Icons.people_rounded,
                                    label: 'Passenger List',
                                    color: const Color(0xFF1A73E8),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ConductorPassengersScreen(
                                              trip: _todayTrip!,
                                            ),
                                      ),
                                    ).then((_) => _loadData()),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
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
    const w = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${w[d.weekday - 1]}, ${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

// ─── Today Trip Card ──────────────────────────────────────────────────────────

class _TodayTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TodayTripCard({
    required this.trip,
    this.isSelected = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = trip['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;
    final bus = schedule?['buses'] as Map<String, dynamic>?;
    final status = trip['status'] as String;

    // ── If schedule is null, show warning banner ──────────────────────────────
    if (schedule == null) {
      return _buildNoScheduleCard(status);
    }

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'in_progress':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'In Progress';
      case 'completed':
        statusColor = const Color(0xFF6B7280);
        statusLabel = 'Completed';
      default:
        statusColor = const Color(0xFF2563EB);
        statusLabel = 'Scheduled';
    }

    final textColor = isSelected ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isSelected
        ? Colors.white.withOpacity(0.8)
        : const Color(0xFF64748B);
    final iconColor = isSelected ? Colors.white : const Color(0xFF475569);
    final dividerColor = isSelected ? Colors.white24 : const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? statusColor.withOpacity(0.2)
                        : statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? statusColor.withOpacity(0.5)
                          : statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: isSelected ? Colors.white : statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatTime(schedule?['departure_time'] ?? ''),
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(schedule?['departure_time'] ?? ''),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      route?['origin'] ?? '',
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${route?['duration_min'] ?? ''} min',
                        style: TextStyle(fontSize: 11, color: subTextColor),
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(height: 1.5, color: dividerColor),
                          Icon(
                            Icons.directions_bus_rounded,
                            color: iconColor,
                            size: 18,
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
                      _formatTime(schedule?['arrival_time'] ?? ''),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      route?['destination'] ?? '',
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: dividerColor),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.directions_bus_outlined,
                  color: iconColor.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${bus?['model'] ?? ''} • ${bus?['plate_number'] ?? ''}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.event_seat_outlined,
                  color: iconColor.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${bus?['capacity'] ?? ''} seats',
                  style: TextStyle(
                    color: textColor.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoScheduleCard(String status) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
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
            'You have no assigned trips for today',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
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
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
