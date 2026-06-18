import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../l10n/tr_extension.dart';
import '../../../../shared/widgets/trip_status_badge.dart';

class UpcomingTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const UpcomingTripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final schedule = trip['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/HomeBanner.webp',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.upcomingTripCardRoute(
                          '${route?['origin'] ?? ''}',
                          '${route?['destination'] ?? ''}',
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr.upcomingTripCardDateTime(
                          DateHelpers.formatDateShort(trip['trip_date']),
                          DateHelpers.formatTime(schedule?['departure_time'] ?? ''),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TripStatusBadge(
                  status: trip['status'] as String,
                  fontSize: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
