import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../l10n/tr_extension.dart';
import '../../../../shared/widgets/trip_status_badge.dart';
import '../trip_punctuality.dart';

class TodayTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onTap;
  const TodayTripCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final schedule = trip['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;
    final bus = schedule?['buses'] as Map<String, dynamic>?;
    final status = trip['status'] as String;

    if (schedule == null) {
      return _buildNoScheduleCard(status, context);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/HomeBanner.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark.withValues(alpha: 0.85),
                      const Color(0xFF0D47A1).withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          TripStatusBadge(status: status, fontSize: 12),
                          _PunctualityBadge(trip: trip),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.tr.todayTripCardTapToManage,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateHelpers.formatTime(
                              schedule['departure_time'] ?? '',
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            route?['origin'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              context.tr.todayTripCardDurationMin(
                                (route?['duration_min'] as num?)?.toInt() ?? 0,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 1.5,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                const Icon(
                                  Icons.directions_bus_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr.todayTripCardDistanceKm(
                                (route?['distance_km'] as num?)?.toInt() ?? 0,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateHelpers.formatTime(
                              schedule['arrival_time'] ?? '',
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            route?['destination'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_bus_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr.todayTripCardBusInfo(
                          '${bus?['model'] ?? ''}',
                          '${bus?['plate_number'] ?? ''}',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.event_seat_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.tr.todayTripCardCapacity(
                          (bus?['capacity'] as num?)?.toInt() ?? 0,
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
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
    );
  }

  Widget _buildNoScheduleCard(String status, BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/HomeBanner.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDark.withValues(alpha: 0.85),
                    const Color(0xFF0D47A1).withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(children: [TripStatusBadge(status: status, fontSize: 12)]),
                const SizedBox(height: 20),
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr.todayTripCardNoSchedule,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr.todayTripCardNoScheduleDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
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

class _PunctualityBadge extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _PunctualityBadge({required this.trip});

  @override
  Widget build(BuildContext context) {
    final punctuality = TripPunctuality.calculate(trip, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: punctuality.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: punctuality.color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(punctuality.icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            punctuality.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
