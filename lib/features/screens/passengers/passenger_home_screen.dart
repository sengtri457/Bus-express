import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../services/notification_service.dart';
import '../../../supabase_config.dart';
import '../../widgets/animations.dart';
import '../../widgets/notification_bell.dart';
import '../route_list_screen.dart';
import 'passenger_profile_screen.dart';
import 'see_all_promotions_screen.dart';

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
    NotificationService.instance.refreshUnreadCount();
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
          colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
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
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/blueKhmer.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Semi-transparent overlay for readability
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.85)),
          ),
          // Content
          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF2563EB),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        "assets/images/HomeBanner.webp",
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                        width: double.infinity,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF2563EB).withValues(alpha: 0.6),
                              const Color(0xFF1D4ED8).withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                title: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${_userName.split(' ').first} 👋',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Where are you going today?',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const NotificationBell(),
                      GestureDetector(
                        onTap: () {
                          if (widget.onProfileTap != null) {
                            widget.onProfileTap!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PassengerProfileScreen(),
                              ),
                            ).then((_) => _loadUserName());
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Search Card
                  SlideFadeIn(
                    duration: const Duration(milliseconds: 500),
                    offset: 25,
                    child: Container(
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
                              iconColor: const Color(0xFF2563EB),
                            ),
                            // Swap + divider
                            Row(
                              children: [
                                const SizedBox(width: 20),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: const Color(0xFFE2E8F0),
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
                                      color: Color(0xFF2563EB),
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
                            const Divider(color: Color(0xFFE2E8F0)),
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
                                      color: Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Travel Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        _formatDate(_selectedDate),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF94A3B8),
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
                                  backgroundColor: const Color(0xFF2563EB),
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
                                            color: Colors.black.withOpacity(
                                              0.04,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: const Color(0xFFF3F4F6),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFF2563EB),
                                                  Color(0xFF1D4ED8),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RouteListScreen(
                                origin: origin,
                                destination: destination,
                                date: _selectedDate,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      const _OffersSection(),
                    ],
                  ),
                ),
              ),
            ],
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
          .eq('status', 'active')
          .limit(5);
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
    return SlideFadeIn(
      duration: const Duration(milliseconds: 500),
      offset: 20,
      child: Column(
        children: _routes
            .map(
              (route) => _RouteCard(
                route: route,
                onTap: () =>
                    widget.onRouteTap(route['origin'], route['destination']),
              ),
            )
            .toList(),
      ),
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
                color: Color(0xFF2563EB),
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

// ─── Offers Section ──────────────────────────────────────────────────────────

class _OffersSection extends StatefulWidget {
  const _OffersSection();

  @override
  State<_OffersSection> createState() => _OffersSectionState();
}

class _OffersSectionState extends State<_OffersSection> {
  String _selectedCategory = 'All';
  late PageController _pageController;
  int _currentPage = 0;

  final List<_OfferItem> _allOffers = [
    const _OfferItem(
      category: 'Bus',
      title: 'Save up to Rs 250 on bus tickets',
      validity: 'Valid till 31 May',
      code: 'FIRST',
      backgroundColor: Color(
        0xFFFFEAE9,
      ), // Premium soft coral/peach from screenshot
      badgeColor: Color(0xFF5B5251), // Dark grey/brown badge from screenshot
      isBus: true,
      imageAsset: null,
    ),
    const _OfferItem(
      category: 'Bus',
      title: 'Save up to Rs 200 on operators.',
      validity: 'Valid till 31 May',
      code: 'PRIMO200',
      backgroundColor: Color(0xFFFEF3C7), // Light yellow gold from screenshot
      badgeColor: Color(0xFF5B5251), // Dark grey/brown badge
      isBus: true,
      imageAsset: null,
    ),
    const _OfferItem(
      category: 'Train',
      title: 'Get 15% off on your first train booking',
      validity: 'Valid till 15 June',
      code: 'TRAIN15',
      backgroundColor: Color(0xFFE0F2FE), // Soft sky blue
      badgeColor: Color(0xFF1E293B),
      isBus: false,
      imageAsset: null,
    ),
    const _OfferItem(
      category: 'All',
      title: 'Flat Rs 100 cashback on any booking',
      validity: 'Valid till 10 June',
      code: 'CASHBACK100',
      backgroundColor: Color(0xFFF3E8FF), // Soft lavender
      badgeColor: Color(0xFF1E293B),
      isBus: true,
      imageAsset: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_OfferItem> get _filteredOffers {
    if (_selectedCategory == 'All') {
      return _allOffers;
    }
    return _allOffers
        .where(
          (offer) =>
              offer.category == _selectedCategory || offer.category == 'All',
        )
        .toList();
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _currentPage = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offers = _filteredOffers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and View More Link
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Offers for you',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SeeAllPromotionsScreen(),
                  ),
                );
              },
              child: const Text(
                'View more',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Category Tabs
        Row(
          children: ['All', 'Bus', 'Train'].map((category) {
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () => _onCategorySelected(category),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF2563EB),
                    width: 1,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color.fromARGB(255, 235, 235, 235)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Carousel Slider
        offers.isEmpty
            ? Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                height: 170,
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
                child: const Center(
                  child: Text(
                    'No offers available for this category',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              )
            : Column(
                children: [
                  SizedBox(
                    height: 170,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: offers.length,
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      itemBuilder: (context, index) {
                        final offer = offers[index];
                        return _OfferCard(offer: offer);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pager Indicator: Badge & Dots
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page Badge (1/32 format)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2563EB,
                            ), // Beautiful crimson red
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentPage + 1}/${offers.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Dots
                        Row(
                          children: List.generate(
                            offers.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _currentPage == index ? 8 : 6,
                              height: _currentPage == index ? 8 : 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final _OfferItem offer;

  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: offer.backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Abstract circles to give a premium glassmorphic/modern vibe
            Positioned(
              right: -35,
              bottom: -35,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
            Positioned(
              right: 15,
              top: -45,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  // Text details
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: offer.badgeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            offer.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Title
                        Text(
                          offer.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Validity
                        Text(
                          offer.validity,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Promo/Coupon Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_offer_outlined,
                                size: 12,
                                color: Color(0xFF1E293B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                offer.code,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Illustration Placeholder
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: offer.imageAsset != null
                          ? Image.asset(
                              offer.imageAsset!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  _FallbackIllustration(isBus: offer.isBus),
                            )
                          : _FallbackIllustration(isBus: offer.isBus),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackIllustration extends StatelessWidget {
  final bool isBus;
  const _FallbackIllustration({required this.isBus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.4),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          isBus ? Icons.directions_bus_rounded : Icons.train_rounded,
          size: 38,
          color: const Color(0xFFDC2626).withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _OfferItem {
  final String category;
  final String title;
  final String validity;
  final String code;
  final Color backgroundColor;
  final Color badgeColor;
  final String? imageAsset;
  final bool isBus;

  const _OfferItem({
    required this.category,
    required this.title,
    required this.validity,
    required this.code,
    required this.backgroundColor,
    required this.badgeColor,
    required this.imageAsset,
    this.isBus = true,
  });
}
