import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/star_rating.dart';
import '../../../../supabase_config.dart';

class ReviewSheet extends StatefulWidget {
  final String bookingId;
  final String tripId;
  final String? driverId;
  final String? driverName;
  final String origin;
  final String destination;
  final VoidCallback onSubmitted;

  const ReviewSheet({
    super.key,
    required this.bookingId,
    required this.tripId,
    this.driverId,
    this.driverName,
    required this.origin,
    required this.destination,
    required this.onSubmitted,
  });

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  int _tripRating = 0;
  int _driverRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _tripLabel(int r) {
    switch (r) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent';
      default: return '';
    }
  }

  Future<void> _submit() async {
    if (_tripRating == 0) return;
    setState(() => _isSubmitting = true);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      await SupabaseConfig.client.from('reviews').insert({
        'booking_id': widget.bookingId,
        'trip_id': widget.tripId,
        'user_id': user.id,
        'rating': _tripRating,
        if (_commentController.text.trim().isNotEmpty)
          'comment': _commentController.text.trim(),
        if (widget.driverId != null && _driverRating > 0) ...{
          'driver_id': widget.driverId,
          'driver_rating': _driverRating,
        },
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thank you for your review!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Rate Your Trip',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Center(
              child: Text(
                '${widget.origin} → ${widget.destination}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Trip Experience',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StarRating(
                    rating: _tripRating,
                    size: 36,
                    spacing: 6,
                    interactive: true,
                    onChanged: (r) => setState(() => _tripRating = r),
                  ),
                  if (_tripRating > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      _tripLabel(_tripRating),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _tripRating >= 4
                            ? AppColors.success
                            : _tripRating >= 3
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.driverId != null) ...[
              const SizedBox(height: 20),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_rounded,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Driver: ${widget.driverName ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StarRating(
                      rating: _driverRating,
                      size: 30,
                      spacing: 6,
                      interactive: true,
                      onChanged: (r) => setState(() => _driverRating = r),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.all(16),
                counterStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _tripRating == 0 || _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
