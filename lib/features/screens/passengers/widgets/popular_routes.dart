import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../models/route_model.dart';
import '../../../widgets/animations.dart';

class PopularRoutes extends StatefulWidget {
  final void Function(String origin, String destination) onRouteTap;
  final List<RouteModel> routes;
  final bool isLoading;

  const PopularRoutes({
    super.key,
    required this.onRouteTap,
    required this.routes,
    required this.isLoading,
  });

  @override
  State<PopularRoutes> createState() => _PopularRoutesState();
}

class _PopularRoutesState extends State<PopularRoutes> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const SkeletonList(count: 3, cardHeight: 80);
    }
    if (widget.routes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgR,
        ),
        child: const Center(
          child: Text(
            'No routes available yet',
            style: TextStyle(color: AppColors.textHint),
          ),
        ),
      );
    }
    return SlideFadeIn(
      duration: const Duration(milliseconds: 500),
      offset: 20,
      child: Column(
        children: widget.routes
            .map(
              (route) => _RouteCard(
                route: route,
                onTap: () => widget.onRouteTap(route.origin, route.destination),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteModel route;
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
          color: AppColors.surface,
          borderRadius: AppRadius.lgR,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                color: AppColors.primaryLight,
                borderRadius: AppRadius.mdR,
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (route.distanceKm != null) ...[
                        const Icon(
                          Icons.straighten_rounded,
                          size: 12,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${route.distanceKm!.toInt()} km',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (route.durationMin != null) ...[
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${route.durationMin} min',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
