import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../l10n/tr_extension.dart';

class AllClearCard extends StatelessWidget {
  const AllClearCard({super.key});

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
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF54282E),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.allSystemsNormal,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr.allSystemsNormalSubtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentConfig {
  final Color primary;
  final Color background;
  final IconData icon;
  const _IncidentConfig({
    required this.primary,
    required this.background,
    required this.icon,
  });
}

class IncidentCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  const IncidentCard({super.key, required this.incident});

  static const _configs = {
    'delay': _IncidentConfig(
      primary: Color(0xFFD97706),
      background: Color(0xFFFFFBEB),
      icon: Icons.timer_off_rounded,
    ),
    'breakdown': _IncidentConfig(
      primary: Color(0xFFDC2626),
      background: Color(0xFFFEF2F2),
      icon: Icons.build_rounded,
    ),
    'accident': _IncidentConfig(
      primary: Color(0xFFB91C1C),
      background: Color(0xFFFEF2F2),
      icon: Icons.car_crash_rounded,
    ),
    'other': _IncidentConfig(
      primary: Color(0xFF4B5563),
      background: Color(0xFFF3F4F6),
      icon: Icons.warning_amber_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final type = incident['type'] as String? ?? 'other';
    final desc = incident['description'] as String? ?? '';
    final timeStr = incident['created_at'] as String? ?? '';

    final trip =
        (incident['trips'] ?? incident['trip']) as Map<String, dynamic>?;
    final schedule =
        (trip?['schedules'] ?? trip?['schedule']) as Map<String, dynamic>?;
    final route =
        (schedule?['routes'] ?? schedule?['route']) as Map<String, dynamic>?;

    final origin = route?['origin'] as String? ?? 'Unknown';
    final destination = route?['destination'] as String? ?? 'Unknown';
    final depTime = schedule?['departure_time'] as String? ?? '';

    final cfg = _configs[type] ?? _configs['other']!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cfg.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cfg.background,
              shape: BoxShape.circle,
            ),
            child: Icon(cfg.icon, color: cfg.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$origin → $destination',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      DateHelpers.formatTime(timeStr),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cfg.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: cfg.primary,
                        ),
                      ),
                    ),
                    if (depTime.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Departs ${DateHelpers.formatTime(depTime)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.4,
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
