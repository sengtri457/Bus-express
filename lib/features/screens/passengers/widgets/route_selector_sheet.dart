import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../supabase_config.dart';

class RouteOption {
  final String origin;
  final String destination;

  const RouteOption({required this.origin, required this.destination});

  String get displayName => '$origin → $destination';
}

class RouteSelectorSheet extends StatefulWidget {
  final void Function(String origin, String destination) onSelected;

  const RouteSelectorSheet({super.key, required this.onSelected});

  @override
  State<RouteSelectorSheet> createState() => _RouteSelectorSheetState();
}

class _RouteSelectorSheetState extends State<RouteSelectorSheet> {
  List<RouteOption> _routes = [];
  List<RouteOption> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    try {
      final data = await SupabaseConfig.client
          .from('routes')
          .select('origin, destination')
          .eq('status', 'active')
          .order('origin');

      final seen = <String>{};
      final routes = <RouteOption>[];
      for (final row in data) {
        final origin = row['origin'] as String? ?? '';
        final destination = row['destination'] as String? ?? '';
        if (origin.isEmpty || destination.isEmpty) continue;
        final key = '$origin|$destination';
        if (seen.add(key)) {
          routes.add(RouteOption(origin: origin, destination: destination));
        }
      }

      if (mounted) {
        setState(() {
          _routes = routes;
          _filtered = routes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _routes
          : _routes.where((r) {
              return r.origin.toLowerCase().contains(query) ||
                  r.destination.toLowerCase().contains(query) ||
                  r.displayName.toLowerCase().contains(query);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<RouteOption>>{};
    for (final route in _filtered) {
      grouped.putIfAbsent(route.origin, () => []).add(route);
    }
    final origins = grouped.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    const Text(
                      'Select Route',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 20, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search destinations...',
                    hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? 'No routes available'
                                  : 'No routes match "$_searchController"',
                              style: const TextStyle(
                                  color: Color(0xFF9CA3AF), fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: origins.length,
                            itemBuilder: (context, i) {
                              final origin = origins[i];
                              final dests = grouped[origin]!;
                              return _OriginGroup(
                                origin: origin,
                                destinations: dests,
                                onTap: (dest) {
                                  widget.onSelected(origin, dest);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OriginGroup extends StatelessWidget {
  final String origin;
  final List<RouteOption> destinations;
  final void Function(String destination) onTap;

  const _OriginGroup({
    required this.origin,
    required this.destinations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                origin,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        ...destinations.map((d) => _DestinationTile(
              origin: origin,
              destination: d.destination,
              onTap: () => onTap(d.destination),
            )),
      ],
    );
  }
}

class _DestinationTile extends StatelessWidget {
  final String origin;
  final String destination;
  final VoidCallback onTap;

  const _DestinationTile({
    required this.origin,
    required this.destination,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_bus_rounded,
                  size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$origin → $destination',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}
