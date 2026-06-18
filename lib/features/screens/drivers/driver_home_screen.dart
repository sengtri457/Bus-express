import 'package:flutter/material.dart';

import '../../../l10n/tr_extension.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_helper.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../models/trip_model.dart';
import '../../../models/user_model.dart';
import '../../../repositories/trip_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/notification_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../widgets/notification_bell.dart';
import 'driver_trips_screen.dart';
import 'widgets/today_trip_card.dart';
import 'widgets/upcoming_trip_card.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _tripRepo = TripRepository();
  final _userRepo = UserRepository();

  UserModel? _profile;
  List<TripModel> _todayTrips = [];
  List<TripModel> _upcomingTrips = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.refreshUnreadCount();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _tripRepo.syncOverdueTrips();

      final user = _userRepo.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      debugPrint('[Driver] Loading data for user: ${user.id}');

      final profileResult = await _userRepo.getCurrentUser(user.id);
      if (mounted && profileResult is Success<UserModel>) {
        _profile = profileResult.data;
      }

      final today = DateTime.now().toLocal().toIso8601String().split('T')[0];
      final weekday = DateTime.now().weekday.toString();

      await _autoSpawnTrips(user.id, today, weekday);

      await _tripRepo.syncOverdueTrips();

      final tripsResult = await _tripRepo.getDriverTrips(user.id);
      if (mounted && tripsResult is Success<List<TripModel>>) {
        final allTrips = tripsResult.data;
        setState(() {
          _todayTrips = allTrips
              .where((t) => t.tripDate == today)
              .toList()
            ..sort((a, b) {
              final aHas = a.schedule != null;
              final bHas = b.schedule != null;
              if (aHas && !bHas) return -1;
              if (!aHas && bHas) return 1;
              return 0;
            });
          _upcomingTrips = allTrips
              .where((t) => t.tripDate != today)
              .toList();
          _isLoading = false;
        });
      } else if (mounted && tripsResult is Failure<List<TripModel>>) {
        debugPrint('[Driver] TRIPS FAILURE: ${tripsResult.message} | ${tripsResult.error}');
        setState(() {
          _isLoading = false;
          _errorMessage = '${tripsResult.message}\n${tripsResult.error}';
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
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

  Future<void> _autoSpawnTrips(
    String driverId,
    String today,
    String weekday,
  ) async {
    try {
      final schedules = await _userRepo.client
          .from('schedules')
          .select('id, days_of_week, bus_id, driver_id, conductor_id, status')
          .eq('driver_id', driverId)
          .eq('status', 'active');

      final activeTodaySchedules =
          List<Map<String, dynamic>>.from(schedules as List).where((s) {
        final days = (s['days_of_week'] as String? ?? '').split(',');
        return days.contains(weekday);
      }).toList();

      for (final sched in activeTodaySchedules) {
        final exists = await _userRepo.client
            .from('trips')
            .select('id')
            .eq('schedule_id', sched['id'])
            .eq('trip_date', today)
            .maybeSingle();

        if (exists == null) {
          debugPrint(
            '[Driver Sync] Auto-spawning trip for schedule ${sched['id']} on $today',
          );
          await _userRepo.client.from('trips').insert({
            'schedule_id': sched['id'],
            'trip_date': today,
            'bus_id': sched['bus_id'],
            'driver_id': driverId,
            'conductor_id': sched['conductor_id'],
            'status': 'scheduled',
          });
        }
      }
    } catch (e) {
      debugPrint('[Driver Sync] Error auto-spawning trips: $e');
    }
  }

  Future<void> _signOut() => AuthHelper.signOut(context);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final name = _profile?.name?.split(' ').first ?? 'Driver';
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      actions: [
        const NotificationBell(),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadData,
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
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
                          color: Colors.white.withValues(alpha: 0.2),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr.driverHomeHello(name),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            context.tr.driverHomeDashboard,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    DateHelpers.formatFullDate(DateTime.now().toIso8601String()),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.driverHomeTodaysTrip,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (_todayTrips.isNotEmpty)
            ..._todayTrips.map(
              (trip) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TodayTripCard(
                  trip: trip.toMap(),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverTripScreen(trip: trip.toMap()),
                      ),
                    );
                    _loadData();
                  },
                ),
              ),
            )
          else
            EmptyState(
              icon: Icons.free_cancellation_rounded,
              title: context.tr.driverHomeNoTripToday,
              subtitle: context.tr.driverHomeNoTripSubtitle,
            ),
          const SizedBox(height: 28),
          if (_upcomingTrips.isNotEmpty) ...[
            Text(
              context.tr.driverHomeUpcomingTrips,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ..._upcomingTrips.map(
              (trip) => UpcomingTripCard(trip: trip.toMap()),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            context.tr.driverHomeQuickStats,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _StatsRow(driverId: _userRepo.client.auth.currentUser!.id),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Center(
              child: Text(
                context.tr.driverHomeFailedLoad,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr.driverHomeRetry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatefulWidget {
  final String driverId;
  const _StatsRow({required this.driverId});

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  final _tripRepo = TripRepository();
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
      final trips = await _tripRepo.client
          .from('trips')
          .select('id, status')
          .eq('driver_id', widget.driverId);

      final tripIds = (trips as List).map((t) => t['id'] as String).toList();
      int passengers = 0;
      if (tripIds.isNotEmpty) {
        final bookings = await _tripRepo.client
            .from('bookings')
            .select('id')
            .inFilter('trip_id', tripIds)
            .inFilter('status', ['confirmed', 'boarded']);
        passengers = (bookings as List).length;
      }

      if (mounted) {
        setState(() {
          _totalTrips = trips.length;
          _completedTrips = trips.where((t) => t['status'] == 'completed').length;
          _totalPassengers = passengers;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StatCardRow(
      cards: [
        StatCard(
          title: context.tr.driverHomeStatTotalTrips,
          value: '$_totalTrips',
          icon: Icons.route_rounded,
          color: AppColors.primary,
        ),
        StatCard(
          title: context.tr.driverHomeStatCompleted,
          value: '$_completedTrips',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
        StatCard(
          title: context.tr.driverHomeStatPassengers,
          value: '$_totalPassengers',
          icon: Icons.people_rounded,
          color: AppColors.warning,
        ),
      ],
    );
  }
}
