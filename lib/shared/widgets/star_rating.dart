import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double size;
  final double spacing;
  final bool interactive;
  final ValueChanged<int>? onChanged;

  const StarRating({
    super.key,
    this.rating = 0,
    this.maxRating = 5,
    this.size = 28,
    this.spacing = 4,
    this.interactive = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (i) {
        final starIndex = i + 1;
        final filled = starIndex <= rating;
        final halfFilled = !filled && (starIndex - rating) < 1;

        return GestureDetector(
          onTap: interactive ? () => onChanged?.call(starIndex) : null,
          child: Padding(
            padding: EdgeInsets.only(right: i < maxRating - 1 ? spacing : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                halfFilled ? Icons.star_half_rounded : Icons.star_rounded,
                size: size,
                color: filled || halfFilled
                    ? const Color(0xFFFBBF24)
                    : AppColors.border,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class RatingSummary extends StatelessWidget {
  final double average;
  final int count;

  const RatingSummary({
    super.key,
    required this.average,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(rating: average.round(), size: 16, spacing: 2),
        const SizedBox(width: 6),
        Text(
          average.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
