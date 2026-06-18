import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_helper.dart';
import '../../../l10n/tr_extension.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/notification_service.dart';
import '../../widgets/animations.dart';
import '../../widgets/notification_bell.dart';
import 'super_admin_operators_screen.dart';
import 'super_admin_users_screen.dart';

class SuperAdminHomeScreen extends StatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  State<SuperAdminHomeScreen> createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends State<SuperAdminHomeScreen> {
  final _userRepo = UserRepository();
  int _selectedIndex = 0;
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.refreshUnreadCount();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _userRepo.client
            .from('operators')
            .select('id')
            .eq('status', 'active'),
        _userRepo.client
            .from('operators')
            .select('id')
            .eq('status', 'inactive'),
        _userRepo.client
            .from('users')
            .select('id')
            .eq('role', 'passenger'),
        _userRepo.client.from('users').select('id').inFilter('role', [
          'driver',
          'conductor',
        ]),
        _userRepo.client
            .from('trips')
            .select('id')
            .eq('status', 'in_progress'),
        _userRepo.client
            .from('bookings')
            .select('id')
            .eq('status', 'confirmed'),
      ]);

      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayTrips = await _userRepo.client
          .from('trips')
          .select('id')
          .eq('trip_date', today);

      if (mounted) {
        setState(() {
          _stats = {
            'active_operators': (results[0] as List).length,
            'inactive_operators': (results[1] as List).length,
            'passengers': (results[2] as List).length,
            'staff': (results[3] as List).length,
            'live_trips': (results[4] as List).length,
            'pending_bookings': (results[5] as List).length,
            'today_trips': (todayTrips as List).length,
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
        isLoading: _isLoading,
        onRefresh: _loadStats,
      ),
      const SuperAdminOperatorsScreen(),
      const SuperAdminUsersScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.superAdmin,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              context.tr.systemControlPanel,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
              color: Color(0xFF2563EB),
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(
              Icons.business_rounded,
              color: Color(0xFF2563EB),
            ),
            label: 'Operators',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded, color: Color(0xFF2563EB)),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Map<String, int> stats;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _DashboardTab({
    required this.stats,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: SkeletonList(count: 4),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF1F2937)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr.systemOverview,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            context.tr.allOperatorsAndUsers,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _HeroStat(
                        label: context.tr.liveTrips,
                        value: '${stats['live_trips'] ?? 0}',
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 24),
                      _HeroStat(
                        label: context.tr.todaysTrips,
                        value: '${stats['today_trips'] ?? 0}',
                        color: const Color(0xFF60A5FA),
                      ),
                      const SizedBox(width: 24),
                      _HeroStat(
                        label: context.tr.statBookings,
                        value: '${stats['pending_bookings'] ?? 0}',
                        color: const Color(0xFFFBBF24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr.operatorsSection,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: context.tr.statActive,
                    value: '${stats['active_operators'] ?? 0}',
                    icon: Icons.business_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Inactive',
                    value: '${stats['inactive_operators'] ?? 0}',
                    icon: Icons.business_outlined,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              context.tr.usersSection,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: context.tr.passengers,
                    value: '${stats['passengers'] ?? 0}',
                    icon: Icons.person_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Staff',
                    value: '${stats['staff'] ?? 0}',
                    icon: Icons.badge_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
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
          Column(
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
