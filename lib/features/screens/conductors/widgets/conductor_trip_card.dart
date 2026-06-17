import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/widgets/trip_status_badge.dart';

class ConductorTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool isSelected;
  final VoidCallback? onTap;

  const ConductorTripCard({
    super.key,
    required this.trip,
    this.isSelected = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = trip['schedules'] as Map<String, dynamic>?;
    final route = schedule?['routes'] as Map<String, dynamic>?;
    final bus = schedule?['buses'] as Map<String, dynamic>?;
    final status = trip['status'] as String;

    if (schedule == null) {
      return _buildNoScheduleCard(status);
    }

    final textColor = isSelected ? Colors.white : AppColors.textPrimary;
    final subTextColor = isSelected
        ? Colors.white.withValues(alpha: 0.8)
        : AppColors.textSecondary;
    final iconColor = isSelected
        ? Colors.white
        : const Color(0xFF475569);
    final dividerColor =
        isSelected ? Colors.white24 : AppColors.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                gradient: AppGradients.primaryBlue,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              )
            : BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TripStatusBadge(status: status, fontSize: 12),
                Text(
                  DateHelpers.formatTime(schedule['departure_time'] ?? ''),
                  style: TextStyle(color: subTextColor, fontSize: 13),
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
                      DateHelpers.formatTime(schedule['departure_time'] ?? ''),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      route?['origin'] ?? '',
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${route?['duration_min'] ?? ''} min',
                        style: TextStyle(fontSize: 11, color: subTextColor),
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(height: 1.5, color: dividerColor),
                          Icon(
                            Icons.directions_bus_rounded,
                            color: iconColor,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateHelpers.formatTime(schedule['arrival_time'] ?? ''),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      route?['destination'] ?? '',
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: dividerColor),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.directions_bus_outlined,
                  color: iconColor.withValues(alpha: 0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${bus?['model'] ?? ''} • ${bus?['plate_number'] ?? ''}',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.event_seat_outlined,
                  color: iconColor.withValues(alpha: 0.7),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${bus?['capacity'] ?? ''} seats',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoScheduleCard(String status) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              TripStatusBadge(status: status, fontSize: 12),
            ],
          ),
          const SizedBox(height: 20),
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 40,
          ),
          const SizedBox(height: 10),
          const Text(
            'No schedule assigned',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This trip has no schedule linked.\nContact your operator to fix it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
