import 'package:flutter/material.dart';
import '../../../supabase_config.dart';
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
  bool _isLoading = true;
  String? _operatorId;

  @override
  void initState() {
    super.initState();
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

      // Get user + operator info
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

      // Get operator info
      final opInfo = await SupabaseConfig.client
          .from('operators')
          .select('id, name, status')
          .eq('id', _operatorId!)
          .maybeSingle();

      // Get stats in parallel
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

      // Today's bookings
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

      if (mounted) {
        setState(() {
          _operatorInfo = opInfo;
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
      // Navigate back to login by popping everything
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
        onTabSelected: (index) => setState(() => _selectedIndex = index),
      ),
      OperatorRoutesScreen(operatorId: _operatorId ?? ''),
      OperatorBusesScreen(operatorId: _operatorId ?? ''),
      OperatorSchedulesScreen(operatorId: _operatorId ?? ''),
      OperatorStaffScreen(operatorId: _operatorId ?? ''),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _operatorInfo?['name'] ?? 'Operator Panel',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            )
          : IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0x260C9669),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
              color: Color(0xFF059669),
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route_rounded, color: Color(0xFF059669)),
            label: 'Routes',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(
              Icons.directions_bus_rounded,
              color: Color(0xFF059669),
            ),
            label: 'Buses',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(
              Icons.schedule_rounded,
              color: Color(0xFF059669),
            ),
            label: 'Schedules',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded, color: Color(0xFF059669)),
            label: 'Staff',
          ),
        ],
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
  final ValueChanged<int> onTabSelected;

  const _DashboardTab({
    required this.stats,
    required this.operatorInfo,
    required this.isLoading,
    required this.onRefresh,
    required this.operatorId,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Operator card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operatorInfo?['name'] ?? 'My Company',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6EE7B7),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Active Operator',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
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
            const SizedBox(height: 24),

            // Today's summary
            const Text(
              'Today',
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
                  child: _StatCard(
                    label: "Today's Bookings",
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
            const SizedBox(height: 24),

            // Fleet summary
            const Text(
              'Fleet Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _StatCard(
                  label: 'Active Buses',
                  value: '${stats['buses'] ?? 0}',
                  icon: Icons.directions_bus_rounded,
                  color: const Color(0xFF059669),
                ),
                _StatCard(
                  label: 'Active Routes',
                  value: '${stats['routes'] ?? 0}',
                  icon: Icons.route_rounded,
                  color: const Color(0xFF7C3AED),
                ),
                _StatCard(
                  label: 'Schedules',
                  value: '${stats['schedules'] ?? 0}',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFEF4444),
                ),
                _StatCard(
                  label: 'Staff',
                  value: '${stats['staff'] ?? 0}',
                  icon: Icons.people_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            _QuickAction(
              icon: Icons.add_road_rounded,
              label: 'Add New Route',
              subtitle: 'Create a new bus route',
              color: const Color(0xFF7C3AED),
              onTap: () => onTabSelected(1),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.directions_bus_filled_rounded,
              label: 'Add New Bus',
              subtitle: 'Register a bus to your fleet',
              color: const Color(0xFF059669),
              onTap: () => onTabSelected(2),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.person_add_rounded,
              label: 'Add Staff Member',
              subtitle: 'Hire a driver or conductor',
              color: const Color(0xFF0EA5E9),
              onTap: () => onTabSelected(4),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: color.withOpacity(0.1),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action ─────────────────────────────────────────────────────────────

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
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
