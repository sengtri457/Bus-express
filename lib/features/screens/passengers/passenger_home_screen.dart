import 'package:flutter/material.dart';
import '../../../supabase_config.dart';
import '../route_list_screen.dart';
import 'passenger_profile_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const PassengerHomeScreen({super.key, this.onProfileTap});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _userName = '';
  List<Map<String, dynamic>> _operators = [];
  bool _isLoadingOperators = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadOperators();
    PassengerProfileScreen.userNameNotifier.addListener(_onUserNameChanged);
  }

  @override
  void dispose() {
    PassengerProfileScreen.userNameNotifier.removeListener(_onUserNameChanged);
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _onUserNameChanged() {
    if (mounted) {
      setState(() => _userName = PassengerProfileScreen.userNameNotifier.value);
    }
  }

  Future<void> _loadUserName() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      final data = await SupabaseConfig.client
          .from('users')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() => _userName = data['name'] ?? '');
      }
    } catch (_) {}
  }

  Future<void> _loadOperators() async {
    try {
      final data = await SupabaseConfig.client
          .from('operators')
          .select('id, name')
          .eq('status', 'active');
      if (mounted) {
        setState(() {
          _operators = List<Map<String, dynamic>>.from(data);
          _isLoadingOperators = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOperators = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A73E8)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _swapLocations() {
    final temp = _originController.text;
    _originController.text = _destinationController.text;
    _destinationController.text = temp;
  }

  void _searchRoutes() {
    if (_originController.text.trim().isEmpty ||
        _destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter origin and destination'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteListScreen(
          origin: _originController.text.trim(),
          destination: _destinationController.text.trim(),
          date: _selectedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1A73E8),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${_userName.split(' ').first} 👋',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Where are you going today?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                if (widget.onProfileTap != null) {
                                  widget.onProfileTap!();
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PassengerProfileScreen(),
                                    ),
                                  ).then((_) => _loadUserName());
                                }
                              },
                              child: CircleAvatar(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                child: Text(
                                  _userName.isNotEmpty
                                      ? _userName[0].toUpperCase()
                                      : 'P',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                  // Search Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Origin
                        _LocationField(
                          controller: _originController,
                          hint: 'From where?',
                          label: 'Origin',
                          icon: Icons.radio_button_checked,
                          iconColor: const Color(0xFF1A73E8),
                        ),
                        // Swap + divider
                        Row(
                          children: [
                            const SizedBox(width: 20),
                            Container(
                              width: 1,
                              height: 20,
                              color: const Color(0xFFE5E7EB),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _swapLocations,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.swap_vert_rounded,
                                  color: Color(0xFF1A73E8),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Destination
                        _LocationField(
                          controller: _destinationController,
                          hint: 'Where to?',
                          label: 'Destination',
                          icon: Icons.location_on_rounded,
                          iconColor: const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 16),
                        // Date picker
                        GestureDetector(
                          onTap: _pickDate,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Travel Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  Text(
                                    _formatDate(_selectedDate),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF9CA3AF),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Search Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _searchRoutes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A73E8),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Search Buses',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Our Partners (Operators)
                  const Text(
                    'Our Partners',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _isLoadingOperators
                      ? const Center(child: CircularProgressIndicator())
                      : _operators.isEmpty
                      ? const Text(
                          'No operators available at the moment',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        )
                      : SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _operators.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final op = _operators[index];
                              final name = op['name'] as String;
                              final initial = name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : 'O';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RouteListScreen(
                                        origin: '',
                                        destination: '',
                                        date: _selectedDate,
                                        operatorId: op['id'],
                                        operatorName: name,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 100,
                                  padding: const EdgeInsets.all(12),
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
                                    border: Border.all(
                                      color: const Color(0xFFF3F4F6),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF1A73E8),
                                              Color(0xFF0D47A1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        name,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 28),

                  // Popular Routes
                  const Text(
                    'Popular Routes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PopularRoutes(
                    onRouteTap: (origin, destination) {
                      _originController.text = origin;
                      _destinationController.text = destination;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }
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
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

// ─── Location Field ───────────────────────────────────────────────────────────

class _LocationField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _LocationField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Popular Routes ───────────────────────────────────────────────────────────

class _PopularRoutes extends StatefulWidget {
  final Function(String, String) onRouteTap;
  const _PopularRoutes({required this.onRouteTap});

  @override
  State<_PopularRoutes> createState() => _PopularRoutesState();
}

class _PopularRoutesState extends State<_PopularRoutes> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final data = await SupabaseConfig.client
          .from('routes')
          .select('id, name, origin, destination, distance_km, duration_min')
          .eq('status', 'active');
      if (mounted) {
        setState(() {
          _routes = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_routes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No routes available yet',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }
    return Column(
      children: _routes
          .map(
            (route) => _RouteCard(
              route: route,
              onTap: () =>
                  widget.onRouteTap(route['origin'], route['destination']),
            ),
          )
          .toList(),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  final VoidCallback onTap;
  const _RouteCard({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Color(0xFF1A73E8),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${route['origin']} → ${route['destination']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.straighten_rounded,
                        size: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${route['distance_km']} km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${route['duration_min']} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
