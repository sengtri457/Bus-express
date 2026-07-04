import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    final isLive = _isLiveStatus(status);

    return AnimatedSwitcher(
      duration: AppAnimations.medium,
      switchInCurve: AppAnimations.enter,
      switchOutCurve: AppAnimations.exit,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: _BadgeContent(
        key: ValueKey(status),
        config: config,
        fontSize: fontSize,
        isLive: isLive,
      ),
    );
  }

  static bool _isLiveStatus(String status) {
    final s = status.toLowerCase();
    return s == 'in_progress' || s == 'pending' || s == 'boarded';
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

// ─── Badge UI ─────────────────────────────────────────────────

class _BadgeContent extends StatelessWidget {
  final _StatusConfig config;
  final double fontSize;
  final bool isLive;

  const _BadgeContent({
    super.key,
    required this.config,
    required this.fontSize,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize == 12 ? 10 : 14,
        vertical: fontSize == 12 ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live pulse dot OR static icon
          if (isLive)
            _PulseDot(color: config.color, size: fontSize - 1)
          else
            Icon(config.icon, size: fontSize + 2, color: config.color),
          const SizedBox(width: 5),
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
}

// ─── Inline PulseDot for badge use ───────────────────────────

class _PulseDot extends StatelessWidget {
  final Color color;
  final double size;

  const _PulseDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2.0,
      height: size * 2.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 2.0,
            height: size * 2.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.25),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 0.4,
                end: 1.0,
                duration: 900.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(begin: 0.1, duration: 900.ms),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────

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
