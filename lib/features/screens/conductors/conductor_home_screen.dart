import 'package:flutter/material.dart';

import '../../../l10n/tr_extension.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_helper.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../models/user_model.dart';
import '../../../repositories/trip_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/notification_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../widgets/animations.dart';
import '../../widgets/notification_bell.dart';
import 'conductor_passengers_screen.dart';
import 'conductor_scanner_screen.dart';
import 'widgets/action_card.dart';
import 'widgets/conductor_trip_card.dart';

class ConductorHomeScreen extends StatefulWidget {
  const ConductorHomeScreen({super.key});

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  final _tripRepo = TripRepository();
  final _userRepo = UserRepository();

  List<Map<String, dynamic>> _todayTrips = [];
  int _selectedTripIndex = 0;
  Map<String, dynamic>? _todayTrip;
  UserModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalPassengers = 0;
  int _boardedCount = 0;
  int _confirmedCount = 0;

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
      final user = _userRepo.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      debugPrint('[Conductor] Loading data for user: ${user.id}');

      final profileResult = await _userRepo.getCurrentUser(user.id);
      if (mounted && profileResult is Success<UserModel>) {
        _profile = profileResult.data;
      }

      final today = DateTime.now().toLocal().toIso8601String().split('T')[0];
      final weekday = DateTime.now().weekday.toString();

      await _autoSpawnTrips(user.id, today, weekday);

      await _tripRepo.syncOverdueTrips();

      debugPrint(
        '[Conductor] Querying trips for date=$today, conductor_id=${user.id}',
      );

      final tripsResponse = await _userRepo.client
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

      if (todayTrip != null) {
        debugPrint(
          '[Conductor] Found trip id=${todayTrip['id']}, loading bookings...',
        );
        final bookings = await _userRepo.client
            .from('bookings')
            .select('id, status')
            .eq('trip_id', todayTrip['id'])
            .inFilter('status', ['confirmed', 'boarded', 'pending']);

        debugPrint(
          '[Conductor] Bookings count: ${(bookings as List).length}',
        );
        final bookingList = List<Map<String, dynamic>>.from(bookings);
        if (mounted) {
          setState(() {
            _todayTrip = todayTrip;
            _totalPassengers = bookingList.length;
            _boardedCount =
                bookingList.where((b) => b['status'] == 'boarded').length;
            _confirmedCount =
                bookingList.where((b) => b['status'] == 'confirmed').length;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('[Conductor] No trip found for today.');
        if (mounted) {
          setState(() {
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

  Future<void> _autoSpawnTrips(
    String conductorId,
    String today,
    String weekday,
  ) async {
    try {
      final schedules = await _userRepo.client
          .from('schedules')
          .select('id, days_of_week, bus_id, driver_id, conductor_id, status')
          .eq('conductor_id', conductorId)
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
            '[Conductor Sync] Auto-spawning trip for schedule ${sched['id']} on $today',
          );
          await _userRepo.client.from('trips').insert({
            'schedule_id': sched['id'],
            'trip_date': today,
            'bus_id': sched['bus_id'],
            'driver_id': sched['driver_id'],
            'conductor_id': conductorId,
            'status': 'scheduled',
          });
        }
      }
    } catch (e) {
      debugPrint('[Conductor Sync] Error auto-spawning trips: $e');
    }
  }

  Future<void> _signOut() => AuthHelper.signOut(context);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: EdgeInsets.all(20),
          child: SkeletonList(count: 4),
        ),
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
    final name = _profile?.name?.split(' ').first ?? 'Conductor';
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: const Color(0xFF2563EB),
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.confirmation_number_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr.conductorHomeHello(name),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              context.tr.conductorHomeDashboard,
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
                      DateHelpers.formatFullDate(
                        DateTime.now().toIso8601String(),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
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

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_todayTrip != null) ...[
            Text(
              context.tr.conductorHomeQuickActions,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ActionCard(
                    icon: Icons.qr_code_scanner_rounded,
                    label: context.tr.conductorHomeScanTicket,
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConductorScannerScreen(
                            tripId: _todayTrip!['id'],
                          ),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionCard(
                    icon: Icons.people_rounded,
                    label: context.tr.conductorHomePassengerList,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConductorPassengersScreen(
                            trip: _todayTrip!,
                          ),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (_todayTrip != null) ...[
            StatCardRow(
              cards: [
                StatCard(
                  title: context.tr.conductorHomeStatTotal,
                  value: '$_totalPassengers',
                  icon: Icons.people_rounded,
                  color: const Color(0xFF2563EB),
                ),
                StatCard(
                  title: context.tr.conductorHomeStatBoarded,
                  value: '$_boardedCount',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
                StatCard(
                  title: context.tr.conductorHomeStatWaiting,
                  value: '$_confirmedCount',
                  icon: Icons.pending_rounded,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Text(
            context.tr.conductorHomeTodaysTrip,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _todayTrips.isNotEmpty
              ? Column(
                  children: _todayTrips.asMap().entries.map((entry) {
                    final index = entry.key;
                    final trip = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ConductorTripCard(
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
              : EmptyState(
                  icon: Icons.free_cancellation_rounded,
                  title: context.tr.conductorHomeNoTripToday,
                  subtitle: context.tr.conductorHomeNoTripSubtitle,
                ),
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
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                context.tr.driverHomeFailedLoad,
                style: const TextStyle(
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
                  backgroundColor: const Color(0xFF2563EB),
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
