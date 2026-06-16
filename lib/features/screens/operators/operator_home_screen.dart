import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_helper.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/notification_service.dart';
import '../../widgets/notification_bell.dart';
import 'operator_buses_screen.dart';
import 'operator_routes_screen.dart';
import 'operator_schedules_screen.dart';
import 'operator_staff_screen.dart';
import 'widgets/incident_card.dart';
import 'widgets/operator_card.dart';
import 'widgets/quick_action.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> {
  final _userRepo = UserRepository();

  int _selectedIndex = 0;
  Map<String, dynamic>? _operatorInfo;
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _activeIncidents = [];
  bool _isLoading = true;
  String? _operatorId;

  static const _primaryColor = Color(0xFF54282E);

  @override
  void initState() {
    super.initState();
    NotificationService.instance.refreshUnreadCount();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = _userRepo.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userData = await _userRepo.client
          .from('users')
          .select('name, operator_id')
          .eq('id', user.id)
          .maybeSingle();

      _operatorId = userData?['operator_id'] as String?;
      if (_operatorId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final opInfo = await _userRepo.client
          .from('operators')
          .select('id, name, status, logo_url')
          .eq('id', _operatorId!)
          .maybeSingle();

      final results = await Future.wait([
        _userRepo.client
            .from('buses')
            .select('id')
            .eq('operator_id', _operatorId!)
            .eq('status', 'active'),
        _userRepo.client
            .from('routes')
            .select('id')
            .eq('operator_id', _operatorId!)
            .eq('status', 'active'),
        _userRepo.client
            .from('schedules')
            .select('id')
            .eq('status', 'active'),
        _userRepo.client
            .from('users')
            .select('id')
            .eq('operator_id', _operatorId!)
            .inFilter('role', ['driver', 'conductor']),
        _userRepo.client
            .from('trips')
            .select('id')
            .eq('status', 'scheduled'),
      ]);

      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayTrips = await _userRepo.client
          .from('trips')
          .select('id')
          .eq('trip_date', today);

      final tripIds =
          (todayTrips as List).map((t) => t['id'] as String).toList();
      int todayBookings = 0;
      if (tripIds.isNotEmpty) {
        final bookings = await _userRepo.client
            .from('bookings')
            .select('id')
            .inFilter('trip_id', tripIds)
            .inFilter('status', ['confirmed', 'boarded']);
        todayBookings = (bookings as List).length;
      }

      final incidentsData = await _userRepo.client
          .from('incidents')
          .select('''
            id,
            type,
            description,
            created_at,
            trips!inner (
              id,
              trip_date,
              schedules!inner (
                id,
                departure_time,
                routes!inner (
                  id,
                  origin,
                  destination,
                  operator_id
                )
              )
            )
          ''')
          .order('created_at', ascending: false);

      final incidentsList = List<Map<String, dynamic>>.from(
        incidentsData as List,
      );
      final fleetIncidents = incidentsList.where((incident) {
        final trip =
            (incident['trips'] ?? incident['trip']) as Map<String, dynamic>?;
        final schedule =
            (trip?['schedules'] ?? trip?['schedule'])
                as Map<String, dynamic>?;
        final route =
            (schedule?['routes'] ?? schedule?['route'])
                as Map<String, dynamic>?;
        return route?['operator_id'] == _operatorId;
      }).toList();

      if (mounted) {
        setState(() {
          _operatorInfo = opInfo;
          _activeIncidents = fleetIncidents;
          _stats = {
            'buses': (results[0] as List).length,
            'routes': (results[1] as List).length,
            'schedules': (results[2] as List).length,
            'staff': (results[3] as List).length,
            'upcoming_trips': (results[4] as List).length,
            'today_bookings': todayBookings,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() => AuthHelper.signOut(context);

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardTab(
        stats: _stats,
        operatorInfo: _operatorInfo,
        isLoading: _isLoading,
        onRefresh: _loadData,
        operatorId: _operatorId ?? '',
        activeIncidents: _activeIncidents,
        onTabSelected: (index) => setState(() => _selectedIndex = index),
      ),
      OperatorRoutesScreen(operatorId: _operatorId ?? ''),
      OperatorBusesScreen(operatorId: _operatorId ?? ''),
      OperatorSchedulesScreen(operatorId: _operatorId ?? ''),
      OperatorStaffScreen(operatorId: _operatorId ?? ''),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _OperatorAppBar(
        companyName: _operatorInfo?['name'] ?? 'Operator Panel',
        onRefresh: _loadData,
        onSignOut: _signOut,
        primaryColor: _primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: _OperatorNavBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        primaryColor: _primaryColor,
      ),
    );
  }
}

class _OperatorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String companyName;
  final VoidCallback onRefresh;
  final VoidCallback onSignOut;
  final Color primaryColor;

  const _OperatorAppBar({
    required this.companyName,
    required this.onRefresh,
    required this.onSignOut,
    required this.primaryColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            companyName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        const NotificationBell(),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 22),
          tooltip: 'Refresh',
          onPressed: onRefresh,
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 22),
          tooltip: 'Sign out',
          onPressed: onSignOut,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _OperatorNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color primaryColor;

  static const _items = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.route_outlined,
      activeIcon: Icons.route_rounded,
      label: 'Routes',
    ),
    _NavItem(
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus_rounded,
      label: 'Buses',
    ),
    _NavItem(
      icon: Icons.schedule_outlined,
      activeIcon: Icons.schedule_rounded,
      label: 'Schedules',
    ),
    _NavItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Staff',
    ),
  ];

  const _OperatorNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _items.length,
              (i) => _NavBarItem(
                item: _items[i],
                isActive: currentIndex == i,
                activeColor: primaryColor,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                size: 22,
                color: isActive ? activeColor : const Color(0xFFCBD5E1),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Map<String, int> stats;
  final Map<String, dynamic>? operatorInfo;
  final bool isLoading;
  final VoidCallback onRefresh;
  final String operatorId;
  final List<Map<String, dynamic>> activeIncidents;
  final ValueChanged<int> onTabSelected;

  const _DashboardTab({
    required this.stats,
    required this.operatorInfo,
    required this.isLoading,
    required this.onRefresh,
    required this.operatorId,
    required this.activeIncidents,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF059669),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OperatorCard(operatorInfo: operatorInfo),
            const SizedBox(height: 28),
            const SectionLabel(label: "Today's Summary"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Bookings',
                    value: '${stats['today_bookings'] ?? 0}',
                    icon: Icons.confirmation_number_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Upcoming Trips',
                    value: '${stats['upcoming_trips'] ?? 0}',
                    icon: Icons.departure_board_rounded,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const SectionLabel(label: 'Fleet Overview'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.65,
              children: [
                _StatCard(
                  label: 'Active Buses',
                  value: '${stats['buses'] ?? 0}',
                  icon: Icons.directions_bus_rounded,
                  color: const Color(0xFF54282E),
                ),
                _StatCard(
                  label: 'Active Routes',
                  value: '${stats['routes'] ?? 0}',
                  icon: Icons.route_rounded,
                  color: const Color(0xFF54282E),
                ),
                _StatCard(
                  label: 'Schedules',
                  value: '${stats['schedules'] ?? 0}',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF54282E),
                ),
                _StatCard(
                  label: 'Staff',
                  value: '${stats['staff'] ?? 0}',
                  icon: Icons.people_rounded,
                  color: const Color(0xFF54282E),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const SectionLabel(label: 'Fleet Alerts'),
                const SizedBox(width: 8),
                if (activeIncidents.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${activeIncidents.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            activeIncidents.isEmpty
                ? const AllClearCard()
                : Column(
                    children: activeIncidents
                        .map((i) => IncidentCard(incident: i))
                        .toList(),
                  ),
            const SizedBox(height: 28),
            const SectionLabel(label: 'Quick Actions'),
            const SizedBox(height: 12),
            QuickAction(
              icon: Icons.add_road_rounded,
              label: 'Add New Route',
              subtitle: 'Create a new bus route',
              color: const Color(0xFF54282E),
              onTap: () => onTabSelected(1),
            ),
            const SizedBox(height: 10),
            QuickAction(
              icon: Icons.directions_bus_filled_rounded,
              label: 'Add New Bus',
              subtitle: 'Register a bus to your fleet',
              color: const Color(0xFF54282E),
              onTap: () => onTabSelected(2),
            ),
            const SizedBox(height: 10),
            QuickAction(
              icon: Icons.person_add_rounded,
              label: 'Add Staff Member',
              subtitle: 'Hire a driver or conductor',
              color: const Color(0xFF54282E),
              onTap: () => onTabSelected(4),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
