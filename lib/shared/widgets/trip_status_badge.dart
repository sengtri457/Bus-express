import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class TripStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const TripStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final config = _config;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize == 12 ? 10 : 14,
        vertical: fontSize == 12 ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: fontSize + 2, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig get _config {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return _StatusConfig(
          label: 'Scheduled',
          color: AppColors.info,
          icon: Icons.schedule_rounded,
        );
      case 'in_progress':
        return _StatusConfig(
          label: 'In Progress',
          color: AppColors.success,
          icon: Icons.directions_bus_rounded,
        );
      case 'completed':
        return _StatusConfig(
          label: 'Completed',
          color: AppColors.textSecondary,
          icon: Icons.check_circle_rounded,
        );
      case 'cancelled':
        return _StatusConfig(
          label: 'Cancelled',
          color: AppColors.error,
          icon: Icons.cancel_rounded,
        );
      case 'confirmed':
        return _StatusConfig(
          label: 'Confirmed',
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      case 'boarded':
        return _StatusConfig(
          label: 'Boarded',
          color: AppColors.info,
          icon: Icons.person_pin_rounded,
        );
      case 'pending':
        return _StatusConfig(
          label: 'Pending',
          color: AppColors.warning,
          icon: Icons.hourglass_empty_rounded,
        );
      case 'paid':
        return _StatusConfig(
          label: 'Paid',
          color: AppColors.success,
          icon: Icons.payment_rounded,
        );
      case 'refunded':
        return _StatusConfig(
          label: 'Refunded',
          color: AppColors.textSecondary,
          icon: Icons.replay_rounded,
        );
      case 'valid':
        return _StatusConfig(
          label: 'Valid',
          color: AppColors.success,
          icon: Icons.qr_code_rounded,
        );
      case 'used':
        return _StatusConfig(
          label: 'Used',
          color: AppColors.textSecondary,
          icon: Icons.check_rounded,
        );
      case 'active':
        return _StatusConfig(
          label: 'Active',
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      case 'inactive':
        return _StatusConfig(
          label: 'Inactive',
          color: AppColors.textSecondary,
          icon: Icons.remove_circle_rounded,
        );
      default:
        return _StatusConfig(
          label: status,
          color: AppColors.textSecondary,
          icon: Icons.help_outline_rounded,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}
