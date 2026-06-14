import 'package:flutter/material.dart';
import '../../../services/notification_service.dart';
import '../../../supabase_config.dart';
import '../../widgets/notification_bell.dart';
import '../../auth/login_screen.dart';
import 'operator_routes_screen.dart';
import 'operator_buses_screen.dart';
import 'operator_schedules_screen.dart';
import 'operator_staff_screen.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> {
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
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userData = await SupabaseConfig.client
          .from('users')
          .select('name, operator_id')
          .eq('id', user.id)
          .maybeSingle();

      _operatorId = userData?['operator_id'] as String?;
      if (_operatorId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final opInfo = await SupabaseConfig.client
          .from('operators')
          .select('id, name, status, logo_url')
          .eq('id', _operatorId!)
          .maybeSingle();

      final results = await Future.wait([
        SupabaseConfig.client
            .from('buses')
            .select('id')
            .eq('operator_id', _operatorId!)
            .eq('status', 'active'),
        SupabaseConfig.client
            .from('routes')
            .select('id')
            .eq('operator_id', _operatorId!)
            .eq('status', 'active'),
        SupabaseConfig.client
            .from('schedules')
            .select('id')
            .eq('status', 'active'),
        SupabaseConfig.client
            .from('users')
            .select('id')
            .eq('operator_id', _operatorId!)
            .inFilter('role', ['driver', 'conductor']),
        SupabaseConfig.client
            .from('trips')
            .select('id')
            .eq('status', 'scheduled'),
      ]);

      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayTrips = await SupabaseConfig.client
          .from('trips')
          .select('id')
          .eq('trip_date', today);

      final tripIds = (todayTrips as List)
          .map((t) => t['id'] as String)
          .toList();
      int todayBookings = 0;
      if (tripIds.isNotEmpty) {
        final bookings = await SupabaseConfig.client
            .from('bookings')
            .select('id')
            .inFilter('trip_id', tripIds)
            .inFilter('status', ['confirmed', 'boarded']);
        todayBookings = (bookings as List).length;
      }

      final incidentsData = await SupabaseConfig.client
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
            (trip?['schedules'] ?? trip?['schedule']) as Map<String, dynamic>?;
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
      backgroundColor: const Color(0xFFF8FAFC),
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

// ─── App Bar ──────────────────────────────────────────────────────────────────

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

// ─── Bottom Nav Bar ───────────────────────────────────────────────────────────

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

// ─── Dashboard Tab ────────────────────────────────────────────────────────────

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
            // Operator header card
            _OperatorCard(operatorInfo: operatorInfo),
            const SizedBox(height: 28),

            // Today section
            _SectionLabel(label: "Today's Summary"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: "Bookings",
                    value: '${stats['today_bookings'] ?? 0}',
                    icon: Icons.confirmation_number_rounded,
                    color: const Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Upcoming Trips',
                    value: '${stats['upcoming_trips'] ?? 0}',
                    icon: Icons.departure_board_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Fleet overview
            _SectionLabel(label: 'Fleet Overview'),
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

            // Fleet alerts
            Row(
              children: [
                const _SectionLabel(label: 'Fleet Alerts'),
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
                ? _AllClearCard()
                : Column(
                    children: activeIncidents
                        .map((i) => _IncidentCard(incident: i))
                        .toList(),
                  ),
            const SizedBox(height: 28),

            // Quick actions
            _SectionLabel(label: 'Quick Actions'),
            const SizedBox(height: 12),
            _QuickAction(
              icon: Icons.add_road_rounded,
              label: 'Add New Route',
              subtitle: 'Create a new bus route',
              color: const Color(0xFF54282E),
              onTap: () => onTabSelected(1),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.directions_bus_filled_rounded,
              label: 'Add New Bus',
              subtitle: 'Register a bus to your fleet',
              color: const Color(0xFF54282E),
              onTap: () => onTabSelected(2),
            ),
            const SizedBox(height: 10),
            _QuickAction(
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

// ─── Operator Logo ─────────────────────────────────────────────────────────────

class _OperatorLogo extends StatelessWidget {
  final String? logoUrl;
  final String name;

  const _OperatorLogo({required this.logoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final hasUrl = logoUrl != null && logoUrl!.startsWith('http');

    return Container(
      width: 58,
      height: 58,
      padding: hasUrl ? null : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        image: hasUrl
            ? DecorationImage(image: NetworkImage(logoUrl!), fit: BoxFit.fill)
            : null,
      ),
      child: hasUrl
          ? null
          : Icon(Icons.business_rounded, color: Colors.white, size: 30),
    );
  }
}

// ─── Operator Card ────────────────────────────────────────────────────────────

class _OperatorCard extends StatelessWidget {
  final Map<String, dynamic>? operatorInfo;

  const _OperatorCard({required this.operatorInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF54282E), Color(0xFF54282E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _OperatorLogo(
            logoUrl: operatorInfo?['logo_url'] as String?,
            name: operatorInfo?['name'] as String? ?? '',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operatorInfo?['name'] ?? 'My Company',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6EE7B7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Active Operator',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── All Clear Card ───────────────────────────────────────────────────────────

class _AllClearCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF54282E),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Systems Normal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'All fleet vehicles operating normally.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Incident Card ────────────────────────────────────────────────────────────

class _IncidentCard extends StatelessWidget {
  final Map<String, dynamic> incident;

  const _IncidentCard({required this.incident});

  static const _configs = {
    'delay': _IncidentConfig(
      primary: Color(0xFFD97706),
      background: Color(0xFFFFFBEB),
      icon: Icons.timer_off_rounded,
    ),
    'breakdown': _IncidentConfig(
      primary: Color(0xFFDC2626),
      background: Color(0xFFFEF2F2),
      icon: Icons.build_rounded,
    ),
    'accident': _IncidentConfig(
      primary: Color(0xFFB91C1C),
      background: Color(0xFFFEF2F2),
      icon: Icons.car_crash_rounded,
    ),
    'other': _IncidentConfig(
      primary: Color(0xFF4B5563),
      background: Color(0xFFF3F4F6),
      icon: Icons.warning_amber_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final type = incident['type'] as String? ?? 'other';
    final desc = incident['description'] as String? ?? '';
    final timeStr = incident['created_at'] as String? ?? '';

    final trip =
        (incident['trips'] ?? incident['trip']) as Map<String, dynamic>?;
    final schedule =
        (trip?['schedules'] ?? trip?['schedule']) as Map<String, dynamic>?;
    final route =
        (schedule?['routes'] ?? schedule?['route']) as Map<String, dynamic>?;

    final origin = route?['origin'] as String? ?? 'Unknown';
    final destination = route?['destination'] as String? ?? 'Unknown';
    final depTime = schedule?['departure_time'] as String? ?? '';

    final cfg = _configs[type] ?? _configs['other']!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cfg.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cfg.background,
              shape: BoxShape.circle,
            ),
            child: Icon(cfg.icon, color: cfg.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$origin → $destination',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      _formatTime(timeStr),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cfg.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: cfg.primary,
                        ),
                      ),
                    ),
                    if (depTime.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Departs ${_formatDepTime(depTime)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String ts) {
    if (ts.isEmpty) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      final h = dt.hour;
      final period = h >= 12 ? 'PM' : 'AM';
      final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$dh:${dt.minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return '';
    }
  }

  String _formatDepTime(String t) {
    if (t.isEmpty) return '';
    try {
      final p = t.split(':');
      final h = int.parse(p[0]);
      final period = h >= 12 ? 'PM' : 'AM';
      final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$dh:${p[1]} $period';
    } catch (_) {
      return t;
    }
  }
}

class _IncidentConfig {
  final Color primary;
  final Color background;
  final IconData icon;

  const _IncidentConfig({
    required this.primary,
    required this.background,
    required this.icon,
  });
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
        letterSpacing: 0.1,
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
        color: Colors.white,
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
                    color: Color(0xFF9CA3AF),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
