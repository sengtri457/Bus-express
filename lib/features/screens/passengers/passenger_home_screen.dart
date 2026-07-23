import 'package:flutter/material.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../l10n/tr_extension.dart';
import '../../../models/operator_model.dart';
import '../../../models/route_model.dart';
import '../../../models/user_model.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/notification_service.dart';
import '../../widgets/animations.dart';
import '../../widgets/notification_bell.dart';
import '../route_list_screen.dart';
import 'passenger_profile_screen.dart';
import 'widgets/location_field.dart';
import 'widgets/offers_section.dart';
import 'widgets/popular_routes.dart';
import 'widgets/route_selector_sheet.dart';

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
  List<OperatorModel> _operators = [];
  List<RouteModel> _popularRoutes = [];
  bool _isLoadingOperators = true;
  bool _isLoadingRoutes = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  Future<void> _loadData() async {
    await Future.wait([
      _loadUserName(),
      _loadOperators(),
      _loadPopularRoutes(),
    ]);
  }

  Future<void> _loadUserName() async {
    final user = UserRepository().client.auth.currentUser;
    if (user == null) return;
    final result = await UserRepository().getCurrentUser(user.id);
    if (mounted && result is Success<UserModel>) {
      setState(() => _userName = result.data.name ?? '');
    }
  }

  Future<void> _loadOperators() async {
    try {
      final data = await UserRepository().client
          .from('operators')
          .select('id, name, logo_url')
          .eq('status', 'active');
      if (mounted) {
        setState(() {
          _operators = data
              .map((e) => OperatorModel.fromMap(e as Map<String, dynamic>))
              .toList();
          _isLoadingOperators = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOperators = false);
    }
  }

  Future<void> _loadPopularRoutes() async {
    try {
      final data = await UserRepository().client
          .from('routes')
          .select('id, name, origin, destination, distance_km, duration_min')
          .eq('status', 'active')
          .limit(5);
      if (mounted) {
        setState(() {
          _popularRoutes = data
              .map((e) => RouteModel.fromMap(e as Map<String, dynamic>))
              .toList();
          _isLoadingRoutes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRoutes = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _swapLocations() {
    final temp = _originController.text;
    _originController.text = _destinationController.text;
    _destinationController.text = temp;
  }

  Future<void> _openRouteSelector() async {
    final result = await showModalBottomSheet<MapEntry<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RouteSelectorSheet(
        onSelected: (origin, destination) {
          Navigator.pop(context, MapEntry(origin, destination));
        },
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _originController.text = result.key;
        _destinationController.text = result.value;
      });
    }
  }

  void _searchRoutes() {
    if (_originController.text.trim().isEmpty ||
        _destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.homeErrorOriginDestination),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      AppPageTransitions.slideHorizontal(
        RouteListScreen(
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/blueKhmer.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.85)),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/HomeBanner.webp',
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.6),
                              AppColors.primaryDark.withValues(alpha: 0.85),
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
                              context.tr.homeHelloName(
                                _userName.split(' ').first,
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              context.tr.homeWhereGoing,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const NotificationBell(),
                      Semantics(
                        button: true,
                        label: context.tr.navProfile,
                        excludeSemantics: true,
                        child: InkWell(
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
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
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
                      _buildSearchCard(),
                      const SizedBox(height: 28),
                      Text(
                        context.tr.homeOurPartners,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildOperatorsList(),
                      const SizedBox(height: 28),
                      Text(
                        context.tr.homePopularRoutes,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      PopularRoutes(
                        onRouteTap: (origin, destination) {
                          Navigator.push(
                            context,
                            AppPageTransitions.slideHorizontal(
                              RouteListScreen(
                                origin: origin,
                                destination: destination,
                                date: _selectedDate,
                              ),
                            ),
                          );
                        },
                        routes: _popularRoutes,
                        isLoading: _isLoadingRoutes,
                      ),
                      const SizedBox(height: 28),
                      const OffersSection(),
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

  Widget _buildSearchCard() {
    return SlideFadeIn(
      duration: const Duration(milliseconds: 500),
      offset: 25,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.xlR,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            LocationField(
              controller: _originController,
              hint: context.tr.homeOriginHint,
              label: context.tr.homeOriginLabel,
              icon: Icons.radio_button_checked,
              iconColor: AppColors.primary,
              onBrowse: _openRouteSelector,
            ),
            Row(
              children: [
                const SizedBox(width: 20),
                Container(width: 1, height: 20, color: AppColors.border),
                const Spacer(),
                Semantics(
                  button: true,
                  label: context.tr.homeSwapLocations,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _swapLocations,
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: AppRadius.smR,
                            ),
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            LocationField(
              controller: _destinationController,
              hint: context.tr.homeDestinationHint,
              label: context.tr.homeDestinationLabel,
              icon: Icons.location_on_rounded,
              iconColor: AppColors.error,
              onBrowse: _openRouteSelector,
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label:
                  '${context.tr.homeTravelDate}, ${DateHelpers.formatDateFromDt(_selectedDate)}',
              excludeSemantics: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: AppRadius.mdR,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: AppRadius.mdR,
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr.homeTravelDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            DateHelpers.formatDateFromDt(_selectedDate),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _searchRoutes,
                icon: const Icon(Icons.search_rounded, size: 20),
                label: Text(
                  context.tr.homeSearchBuses,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultOperatorAvatar(OperatorModel op) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryBlue,
        borderRadius: AppRadius.mdR,
      ),
      child: Center(
        child: Text(
          op.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorsList() {
    if (_isLoadingOperators) {
      return SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Column(
              children: [
                ShimmerBox(width: 44, height: 44, borderRadius: 22),
                SizedBox(height: 10),
                ShimmerBox(width: 60, height: 11, borderRadius: 5),
              ],
            ),
          ),
        ),
      );
    }
    if (_operators.isEmpty) {
      return Text(
        context.tr.homeNoOperators,
        style: const TextStyle(color: AppColors.textHint),
      );
    }
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _operators.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final op = _operators[index];
          return Semantics(
            button: true,
            label: op.name,
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: AppRadius.lgR,
                onTap: () {
                  Navigator.push(
                    context,
                    AppPageTransitions.slideHorizontal(
                      RouteListScreen(
                        origin: '',
                        destination: '',
                        date: _selectedDate,
                        operatorId: op.id,
                        operatorName: op.name,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.lgR,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.mdR,
                        child: op.logoUrl != null
                            ? Image.network(
                                op.logoUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _defaultOperatorAvatar(op),
                              )
                            : _defaultOperatorAvatar(op),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        op.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
