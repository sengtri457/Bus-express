import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/tr_extension.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/trip_repository.dart';
import '../../widgets/animations.dart';
import 'widgets/ticket_card.dart';

class MyTicketsScreen extends StatefulWidget {
  final String? newBookingId;
  final int newSeatCount;

  const MyTicketsScreen({
    super.key,
    this.newBookingId,
    this.newSeatCount = 1,
  });

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  List<List<Map<String, dynamic>>> _upcomingGroups = [];
  List<List<Map<String, dynamic>>> _pastGroups = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  String _statusFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchController = TextEditingController();
  bool _showSearch = false;
  bool _showFilters = false;

  static const _statusOptions = ['', 'confirmed', 'boarded', 'pending', 'cancelled'];
  static const _statusLabels = ['All', 'Confirmed', 'Boarded', 'Pending', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _loadTickets();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _loadTickets());
    if (widget.newBookingId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showBookingSuccessDialog(),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTickets();
      _refreshTimer ??=
          Timer.periodic(const Duration(seconds: 30), (_) => _loadTickets());
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  bool get _hasActiveFilters =>
      _statusFilter.isNotEmpty ||
      _startDate != null ||
      _endDate != null ||
      _searchController.text.trim().isNotEmpty;

  void _clearFilters() {
    setState(() {
      _statusFilter = '';
      _startDate = null;
      _endDate = null;
      _searchController.clear();
      _showSearch = false;
    });
    _loadTickets();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? now.subtract(const Duration(days: 30)))
          : (_endDate ?? now),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 90)),
      helpText: isStart ? 'Select start date' : 'Select end date',
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _loadTickets();
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      await TripRepository().syncOverdueTrips();
      final user = BookingRepository().client.auth.currentUser;
      if (user == null) return;

      var query = BookingRepository()
          .client
          .from('bookings')
          .select('''
            id, seat_number, status, total_price, booked_at,
            trips (
              id, trip_date, status,
              schedules (
                departure_time, arrival_time,
                routes ( name, origin, destination ),
                buses ( model, plate_number )
              )
            ),
            tickets ( id, qr_code, status, scanned_at )
          ''')
          .eq('passenger_id', user.id);

      if (_statusFilter.isNotEmpty) {
        query = query.eq('status', _statusFilter);
      } else {
        query = query.inFilter('status', ['confirmed', 'boarded']);
      }
      if (_startDate != null) {
        query = query.gte('booked_at', _startDate!.toIso8601String());
      }
      if (_endDate != null) {
        query = query.lte(
          'booked_at',
          _endDate!.add(const Duration(days: 1)).toIso8601String(),
        );
      }

      final data = await query.order('booked_at', ascending: false);

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final booking in data as List) {
        final trip = booking['trips'] as Map<String, dynamic>?;
        if (trip == null) continue;
        final tripId = trip['id'] as String;
        grouped.putIfAbsent(tripId, () => []);
        grouped[tripId]!.add(Map<String, dynamic>.from(booking));
      }

      final searchTerm = _searchController.text.trim().toLowerCase();

      final upcoming = <List<Map<String, dynamic>>>[];
      final past = <List<Map<String, dynamic>>>[];

      for (final group in grouped.values) {
        final trip = group.first['trips'] as Map<String, dynamic>;
        final tripStatus = trip['status'] as String;

        if (searchTerm.isNotEmpty) {
          final schedule = trip['schedules'] as Map<String, dynamic>?;
          final route = schedule?['routes'] as Map<String, dynamic>?;
          final origin =
              (route?['origin'] as String? ?? '').toLowerCase();
          final destination =
              (route?['destination'] as String? ?? '').toLowerCase();
          if (!origin.contains(searchTerm) &&
              !destination.contains(searchTerm)) {
            continue;
          }
        }

        if (tripStatus == 'scheduled' || tripStatus == 'in_progress') {
          upcoming.add(group);
        } else {
          past.add(group);
        }
      }

      upcoming.sort((a, b) => (b.first['booked_at'] as String).compareTo(
        a.first['booked_at'] as String,
      ));
      past.sort((a, b) => (b.first['booked_at'] as String).compareTo(
        a.first['booked_at'] as String,
      ));

      if (mounted) {
        setState(() {
          _upcomingGroups = upcoming;
          _pastGroups = past;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBookingSuccessDialog() {
    final count = widget.newSeatCount;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlR),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                count > 1
                    ? context.tr.myTicketsSuccessPlural(count)
                    : context.tr.myTicketsSuccessSingular,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                count > 1
                    ? context.tr.myTicketsSuccessDescPlural(count)
                    : context.tr.myTicketsSuccessDescSingular,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    count > 1
                        ? context.tr.myTicketsViewPlural
                        : context.tr.myTicketsViewSingular,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.tr.myTicketsTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            ),
            onPressed: () =>
                setState(() => _showSearch = !_showSearch),
          ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
            ),
            onPressed: () =>
                setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTickets,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: context.tr.myTicketsUpcoming(_upcomingGroups.length)),
            Tab(text: context.tr.myTicketsPast(_pastGroups.length)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_showSearch) _buildSearchBar(),
          if (_showFilters) _buildFilterBar(),
          if (_hasActiveFilters) _buildActiveFiltersChip(),
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: SkeletonList(count: 4),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _TicketList(
                        groups: _upcomingGroups,
                        emptyMessage: context.tr.myTicketsNoUpcoming,
                        emptySubMessage: context.tr.myTicketsNoUpcomingSub,
                        emptyIcon: Icons.confirmation_number_outlined,
                        highlightId: widget.newBookingId,
                        onRefresh: _loadTickets,
                      ),
                      _TicketList(
                        groups: _pastGroups,
                        emptyMessage: context.tr.myTicketsNoPast,
                        emptySubMessage: context.tr.myTicketsNoPastSub,
                        emptyIcon: Icons.history_rounded,
                        onRefresh: _loadTickets,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by route…',
          hintStyle:
              const TextStyle(fontSize: 14, color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _loadTickets();
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onSubmitted: (_) => _loadTickets(),
        onChanged: (_) {
          if (_searchController.text.length > 2 ||
              _searchController.text.isEmpty) {
            _loadTickets();
          }
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    final dateFormat = DateFormat('MMM d');

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (_hasActiveFilters)
                GestureDetector(
                  onTap: _clearFilters,
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_statusOptions.length, (i) {
              final selected = _statusFilter == _statusOptions[i];
              return FilterChip(
                label: Text(
                  _statusLabels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _statusFilter = selected ? '' : _statusOptions[i];
                  });
                  _loadTickets();
                },
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                backgroundColor: AppColors.background,
                side: BorderSide(
                  color: selected
                      ? AppColors.primary
                      : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickDate(isStart: true),
                icon: const Icon(Icons.calendar_today_rounded, size: 14),
                label: Text(
                  _startDate != null
                      ? 'From ${dateFormat.format(_startDate!)}'
                      : 'From date',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _startDate != null
                      ? AppColors.primary
                      : AppColors.textHint,
                  side: BorderSide(
                    color: _startDate != null
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _pickDate(isStart: false),
                icon: const Icon(Icons.calendar_today_rounded, size: 14),
                label: Text(
                  _endDate != null
                      ? 'To ${dateFormat.format(_endDate!)}'
                      : 'To date',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      _endDate != null ? AppColors.primary : AppColors.textHint,
                  side: BorderSide(
                    color: _endDate != null
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChip() {
    final parts = <String>[];
    if (_statusFilter.isNotEmpty) {
      parts.add(_statusLabels[_statusOptions.indexOf(_statusFilter)]);
    }
    if (_startDate != null) {
      parts.add('From ${DateFormat('MMM d').format(_startDate!)}');
    }
    if (_endDate != null) {
      parts.add('To ${DateFormat('MMM d').format(_endDate!)}');
    }
    if (_searchController.text.trim().isNotEmpty) {
      parts.add('“${_searchController.text.trim()}”');
    }

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _clearFilters,
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  final List<List<Map<String, dynamic>>> groups;
  final String emptyMessage;
  final String emptySubMessage;
  final IconData emptyIcon;
  final String? highlightId;
  final VoidCallback onRefresh;

  const _TicketList({
    required this.groups,
    required this.emptyMessage,
    required this.emptySubMessage,
    required this.emptyIcon,
    required this.onRefresh,
    this.highlightId,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  emptyIcon,
                  size: 40,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final isHighlighted = group.any((b) => b['id'] == highlightId);
          return TicketGroupCard(
            bookings: group,
            isHighlighted: isHighlighted,
            onRefresh: onRefresh,
          );
        },
      ),
    );
  }
}
