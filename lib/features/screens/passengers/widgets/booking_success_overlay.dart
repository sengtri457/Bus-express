import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/tr_extension.dart';
import '../../../widgets/animations.dart';

/// Celebratory confirmation shown after a booking is paid for.
class BookingSuccessOverlay extends StatefulWidget {
  final int seatCount;
  final Duration holdDuration;

  const BookingSuccessOverlay({
    super.key,
    required this.seatCount,
    this.holdDuration = const Duration(milliseconds: 1600),
  });

  /// Shows the overlay and completes once it has dismissed itself.
  static Future<void> show(BuildContext context, {required int seatCount}) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'booking-success',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: context.motion(AppAnimations.fast),
      pageBuilder: (_, _, _) => BookingSuccessOverlay(seatCount: seatCount),
      transitionBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  State<BookingSuccessOverlay> createState() => _BookingSuccessOverlayState();
}

class _BookingSuccessOverlayState extends State<BookingSuccessOverlay> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(widget.holdDuration, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = widget.seatCount == 1;
    final title = isSingle
        ? context.tr.myTicketsSuccessSingular
        : context.tr.myTicketsSuccessPlural(widget.seatCount);
    final description = isSingle
        ? context.tr.myTicketsSuccessDescSingular
        : context.tr.myTicketsSuccessDescPlural(widget.seatCount);

    return Semantics(
      liveRegion: true,
      label: '$title $description',
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.xlR,
                boxShadow: AppShadows.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SuccessCheckmark(size: 88),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
