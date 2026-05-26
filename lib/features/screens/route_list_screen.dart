import 'package:flutter/material.dart';
import '../../supabase_config.dart';
import 'passengers/schedule_seat_screen.dart';

class RouteListScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final DateTime date;
  final String? operatorId;
  final String? operatorName;

  const RouteListScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
    this.operatorId,
    this.operatorName,
  });

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;
  String? _error;

  // Sort options
  String _sortBy = 'departure'; // departure, price, duration

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Auto-end overdue trips in real-time
      await SupabaseConfig.syncOverdueTrips();

      // Get day of week (1=Mon ... 7=Sun)
      final dayOfWeek = widget.date.weekday.toString();
      final dateStr = widget.date.toIso8601String().split('T')[0];

      var query = SupabaseConfig.client
          .from('schedules')
          .select('''
            id,
            departure_time,
            arrival_time,
            price,
            days_of_week,
            status,
            driver_id,
            conductor_id,
            routes!inner (
              id,
              name,
              origin,
              destination,
              distance_km,
              duration_min,
              operator_id,
              operators (
                id,
                name,
                logo_url
              )
            ),
            buses (
              id,
              plate_number,
              model,
              capacity
            ),
            users!schedules_driver_id_fkey (
              name
            )
          ''')
          .eq('status', 'active');

      if (widget.origin.isNotEmpty) {
        query = query.ilike('routes.origin', '%${widget.origin}%');
      }
      if (widget.destination.isNotEmpty) {
        query = query.ilike('routes.destination', '%${widget.destination}%');
      }
      if (widget.operatorId != null) {
        query = query.eq('routes.operator_id', widget.operatorId!);
      }

      final data = await query;

      // Fetch trips for this searched date
      final tripsData = await SupabaseConfig.client
          .from('trips')
          .select('id, schedule_id, status, trip_date')
          .eq('trip_date', dateStr);
      final tripsList = List<Map<String, dynamic>>.from(tripsData as List);

      final now = DateTime.now();
      final filtered = <Map<String, dynamic>>[];

      for (final s in data as List) {
        final days = (s['days_of_week'] as String).split(',');
        if (!days.contains(dayOfWeek)) continue;

        // Check if there is an ended/completed/cancelled trip today for this schedule
        final tripForToday = tripsList.firstWhere(
          (t) => t['schedule_id'] == s['id'],
          orElse: () => <String, dynamic>{},
        );

        if (tripForToday.isNotEmpty) {
          final tripStatus = tripForToday['status'] as String?;
          // If driver clicked "end trip" (completed) or if it's cancelled, it should NOT show on the routes
          if (tripStatus == 'completed' || tripStatus == 'cancelled') {
            continue;
          }
        }

        // Validate scheduled arrival and departure times for today
        try {
          final departureParts = (s['departure_time'] as String).split(':');
          final arrivalParts = (s['arrival_time'] as String).split(':');
          
          final plannedDeparture = DateTime(
            widget.date.year,
            widget.date.month,
            widget.date.day,
            int.parse(departureParts[0]),
            int.parse(departureParts[1]),
          );
          
          final plannedArrival = DateTime(
            widget.date.year,
            widget.date.month,
            widget.date.day,
            int.parse(arrivalParts[0]),
            int.parse(arrivalParts[1]),
          );

          // If the searched date has already passed the arrival/departure time,
          // it is "Time over", so we do NOT show it on the route list
          if (now.isAfter(plannedArrival) || now.isAfter(plannedDeparture)) {
            continue;
          }
        } catch (_) {
          // If we fail parsing for some reason, keep the schedule
        }

        filtered.add(Map<String, dynamic>.from(s));
      }

      if (mounted) {
        setState(() {
          _schedules = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _sortedSchedules {
    final list = List<Map<String, dynamic>>.from(_schedules);
    switch (_sortBy) {
      case 'price':
        list.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
      case 'duration':
        list.sort(
          (a, b) => (a['routes']['duration_min'] as num).compareTo(
            b['routes']['duration_min'] as num,
          ),
        );
      default:
        list.sort(
          (a, b) => (a['departure_time'] as String).compareTo(
            b['departure_time'] as String,
          ),
        );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (widget.origin.isEmpty &&
                      widget.destination.isEmpty &&
                      widget.operatorName != null)
                  ? 'Trips by ${widget.operatorName}'
                  : '${widget.origin} → ${widget.destination}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              _formatDate(widget.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Sort Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'Sort by:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 12),
                _SortChip(
                  label: 'Departure',
                  isSelected: _sortBy == 'departure',
                  onTap: () => setState(() => _sortBy = 'departure'),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Price',
                  isSelected: _sortBy == 'price',
                  onTap: () => setState(() => _sortBy = 'price'),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Duration',
                  isSelected: _sortBy == 'duration',
                  onTap: () => setState(() => _sortBy = 'duration'),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ErrorView(error: _error!, onRetry: _loadSchedules)
                : _sortedSchedules.isEmpty
                ? _EmptyView(
                    origin: widget.origin,
                    destination: widget.destination,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sortedSchedules.length,
                    itemBuilder: (context, index) {
                      return _ScheduleCard(
                        schedule: _sortedSchedules[index],
                        date: widget.date,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ─── Sort Chip ────────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A73E8) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ─── Schedule Card ────────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final DateTime date;

  const _ScheduleCard({required this.schedule, required this.date});

  @override
  Widget build(BuildContext context) {
    final route = schedule['routes'] as Map<String, dynamic>;
    final operator = route['operators'] as Map<String, dynamic>?;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScheduleSeatScreen(schedule: schedule, date: date),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top: Logo and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                if (operator != null)
                  Container(
                    width: 70,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      image:
                          operator['logo_url'] != null &&
                              operator['logo_url'].toString().startsWith('http')
                          ? DecorationImage(
                              image: NetworkImage(operator['logo_url']),
                              fit: BoxFit.contain,
                            )
                          : null,
                    ),
                    child:
                        operator['logo_url'] == null ||
                            !operator['logo_url'].toString().startsWith('http')
                        ? Center(
                            child: Text(
                              operator['name'] != null &&
                                      operator['name'].toString().isNotEmpty
                                  ? operator['name'].toString()[0].toUpperCase()
                                  : 'O',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A73E8),
                                fontSize: 18,
                              ),
                            ),
                          )
                        : null,
                  )
                else
                  const SizedBox(),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'USD ${schedule['price']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Middle: Timeline
            Row(
              children: [
                // Departure
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(schedule['departure_time']),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      route['origin'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),

                // Duration line
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Text(
                          _formatDuration(route['duration_min'] as int),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(height: 1.5, color: const Color(0xFFE5E7EB)),
                      ],
                    ),
                  ),
                ),

                // Arrival
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(schedule['arrival_time']),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      route['destination'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bottom: Operator Name & Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    operator != null ? operator['name'] : 'Standard Bus',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4B5563),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981), // Green rating badge
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        '4.7',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ─── Empty View ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String origin;
  final String destination;

  const _EmptyView({required this.origin, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No buses found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No schedules from $origin to $destination on this date.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A73E8),
                side: const BorderSide(color: Color(0xFF1A73E8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Try Different Date'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
