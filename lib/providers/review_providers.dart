import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/result.dart';
import '../models/review_model.dart';
import '../repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

final bookingReviewProvider = FutureProvider.family<ReviewModel?, String>(
  (ref, bookingId) async {
    final repo = ref.watch(reviewRepositoryProvider);
    final result = await repo.getBookingReview(bookingId);
    return result is Success<ReviewModel?> ? result.data : null;
  },
);

final driverAverageRatingProvider = FutureProvider.family<double, String>(
  (ref, driverId) async {
    final repo = ref.watch(reviewRepositoryProvider);
    final result = await repo.getDriverAverageRating(driverId);
    return result is Success<double> ? result.data : 0.0;
  },
);

final driverReviewsProvider = FutureProvider.family<List<ReviewModel>, String>(
  (ref, driverId) async {
    final repo = ref.watch(reviewRepositoryProvider);
    final result = await repo.getDriverReviews(driverId: driverId);
    return result is Success<List<ReviewModel>> ? result.data : [];
  },
);
