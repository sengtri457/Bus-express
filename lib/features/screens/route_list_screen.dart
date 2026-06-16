import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_helpers.dart';
import '../../repositories/trip_repository.dart';
import '../widgets/animations.dart';
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
  final _tripRepo = TripRepository();
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'departure';

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
      await _tripRepo.syncOverdueTrips();

      final dayOfWeek = widget.date.weekday.toString();
      final dateStr = widget.date.toIso8601String().split('T')[0];

      var query = _tripRepo.client
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

      final tripsData = await _tripRepo.client
          .from('trips')
          .select('id, schedule_id, status, trip_date')
          .eq('trip_date', dateStr);
      final tripsList = List<Map<String, dynamic>>.from(tripsData as List);

      final now = DateTime.now();
      final filtered = <Map<String, dynamic>>[];

      for (final s in data as List) {
        final days = (s['days_of_week'] as String).split(',');
        if (!days.contains(dayOfWeek)) continue;

        final tripForToday = tripsList.firstWhere(
          (t) => t['schedule_id'] == s['id'],
          orElse: () => <String, dynamic>{},
        );

        if (tripForToday.isNotEmpty) {
          final tripStatus = tripForToday['status'] as String?;
          if (tripStatus == 'in_progress' ||
              tripStatus == 'completed' ||
              tripStatus == 'cancelled') {
            continue;
          }
        }

        try {
          final departureParts =
              (s['departure_time'] as String).split(':');
          final arrivalParts = (s['arrival_time'] as String).split(':');

          final plannedDeparture = DateTime(
            widget.date.year,
            widget.date.month,
            widget.date.day,
            int.parse(departureParts[0]),
            int.parse(departureParts[1]),
          );

          var plannedArrival = DateTime(
            widget.date.year,
            widget.date.month,
            widget.date.day,
            int.parse(arrivalParts[0]),
            int.parse(arrivalParts[1]),
          );

          final depHours = int.parse(departureParts[0]);
          final depMins = int.parse(departureParts[1]);
          final arrHours = int.parse(arrivalParts[0]);
          final arrMins = int.parse(arrivalParts[1]);

          if (arrHours * 60 + arrMins < depHours * 60 + depMins) {
            plannedArrival = plannedArrival.add(const Duration(days: 1));
          }

          if (now.isAfter(plannedArrival) ||
              now.isAfter(plannedDeparture)) {
            continue;
          }
        } catch (_) {}

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
        list.sort(
          (a, b) => (a['price'] as num).compareTo(b['price'] as num),
        );
      case 'duration':
        list.sort(
          (a, b) =>
              (a['routes']['duration_min'] as num).compareTo(
                b['routes']['duration_min'] as num,
              ),
        );
      default:
        list.sort(
          (a, b) =>
              (a['departure_time'] as String).compareTo(
                b['departure_time'] as String,
              ),
        );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (widget.origin.isEmpty &&
                      widget.destination.isEmpty &&
                      widget.operatorName != null)
                  ? 'Trips by ${widget.operatorName}'
                  : '${widget.origin} → ${widget.destination}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              DateHelpers.formatFullDate(widget.date.toIso8601String()),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'Sort by:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ShimmerBox(height: 140),
                    ),
                  )
                : _error != null
                ? _ErrorView(error: _error!, onRetry: _loadSchedules)
                : _sortedSchedules.isEmpty
                ? _EmptyView(
                    origin: widget.origin,
                    destination: widget.destination,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _sortedSchedules.length,
                    itemBuilder: (context, index) {
                      return SlideFadeIn(
                        delay: Duration(milliseconds: 80 * index),
                        duration: const Duration(milliseconds: 350),
                        offset: 20,
                        child: _ScheduleCard(
                          schedule: _sortedSchedules[index],
                          date: widget.date,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

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
          color: isSelected
              ? const Color(0xFF2563EB)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

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
          builder: (_) =>
              ScheduleSeatScreen(schedule: schedule, date: date),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (operator != null)
                              Container(
                                width: 60,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F7FF),
                                  borderRadius: BorderRadius.circular(6),
                                  image: operator['logo_url'] != null &&
                                          operator['logo_url']
                                              .toString()
                                              .startsWith('http')
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            operator['logo_url'],
                                          ),
                                          fit: BoxFit.contain,
                                        )
                                      : null,
                                ),
                                child: operator['logo_url'] == null ||
                                        !operator['logo_url']
                                            .toString()
                                            .startsWith('http')
                                    ? Center(
                                        child: Text(
                                          operator['name'] != null &&
                                                  operator['name']
                                                      .toString()
                                                      .isNotEmpty
                                              ? operator['name']
                                                  .toString()[0]
                                                  .toUpperCase()
                                              : 'O',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2563EB),
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                    : null,
                              )
                            else
                              const SizedBox(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F7FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '\$${schedule['price']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
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
                                  DateHelpers.formatTime(
                                    schedule['departure_time'],
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  route['origin'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      DateHelpers.formatDuration(
                                        route['duration_min'] as int,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          height: 1.5,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF2563EB)
                                                    .withValues(alpha: 0.3),
                                                const Color(0xFF2563EB),
                                                const Color(0xFF2563EB)
                                                    .withValues(alpha: 0.3),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.directions_bus_rounded,
                                            size: 14,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DateHelpers.formatTime(
                                    schedule['arrival_time'],
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  route['destination'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.business_rounded,
                                    size: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      operator != null
                                          ? operator['name']
                                          : 'Standard Bus',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 3),
                                const Text(
                                  '4.7',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Book',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(44),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 44,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No buses found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No schedules from $origin to $destination on this date.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
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
