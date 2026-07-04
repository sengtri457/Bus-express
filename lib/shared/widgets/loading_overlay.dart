import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          AnimatedOpacity(
            duration: AppAnimations.fast,
            opacity: isLoading ? 1.0 : 0.0,
            child: _LoadingCard(message: message),
          ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String? message;
  const _LoadingCard({this.message});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Container(
        color: Colors.black.withValues(alpha: 0.28),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgR,
              boxShadow: AppShadows.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wave dot indicator
                _WaveDots(),
                if (message != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    message!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 250.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.90, 0.90),
                end: const Offset(1, 1),
                duration: 300.ms,
                curve: Curves.easeOutBack,
              ),
        ),
      ),
    );
  }
}

// ── Wave dots loader ──────────────────────────────────────────

class _WaveDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const color = AppColors.primaryBlue;
    const dotSize = 10.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: const BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )
              .animate(
                onPlay: (c) => c.repeat(),
                delay: Duration(milliseconds: i * 180),
              )
              .moveY(
                begin: 0,
                end: -9,
                duration: 420.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .moveY(
                begin: -9,
                end: 0,
                duration: 420.ms,
                curve: Curves.easeInOut,
              ),
        );
      }),
    );
  }
}
