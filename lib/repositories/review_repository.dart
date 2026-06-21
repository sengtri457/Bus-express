import '../core/error/result.dart';
import '../models/review_model.dart';
import 'base_repository.dart';

class ReviewRepository extends BaseRepository {
  ReviewRepository() : super('reviews');

  Future<Result<ReviewModel>> createReview({
    required String bookingId,
    required String tripId,
    required String userId,
    required int rating,
    String comment = '',
    String? driverId,
    int? driverRating,
  }) async {
    try {
      final existing = await client
          .from('reviews')
          .select('id')
          .eq('booking_id', bookingId)
          .maybeSingle();
      if (existing != null) {
        return Failure('You have already reviewed this trip');
      }

      final data = await client
          .from('reviews')
          .insert({
            'booking_id': bookingId,
            'trip_id': tripId,
            'user_id': userId,
            'rating': rating,
            if (comment.isNotEmpty) 'comment': comment,
            if (driverId != null) 'driver_id': driverId,
            if (driverRating != null) 'driver_rating': driverRating,
          })
          .select()
          .single();
      return Success(ReviewModel.fromMap(data));
    } catch (e) {
      return Failure('Failed to submit review', error: e);
    }
  }

  Future<Result<ReviewModel?>> getBookingReview(String bookingId) async {
    try {
      final data = await client
          .from('reviews')
          .select('''
            *,
            trips ( id, trip_date, status ),
            driver:users!reviews_driver_id_fkey ( id, name, avatar_url )
          ''')
          .eq('booking_id', bookingId)
          .maybeSingle();
      if (data == null) return const Success(null);
      return Success(ReviewModel.fromMap(data));
    } catch (e) {
      return Failure('Failed to load review', error: e);
    }
  }

  Future<Result<ReviewModel?>> getTripReviewByUser({
    required String tripId,
    required String userId,
  }) async {
    try {
      final data = await client
          .from('reviews')
          .select('*')
          .eq('trip_id', tripId)
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return const Success(null);
      return Success(ReviewModel.fromMap(data));
    } catch (e) {
      return Failure('Failed to load review', error: e);
    }
  }

  Future<Result<List<ReviewModel>>> getDriverReviews({
    required String driverId,
    int limit = 20,
  }) async {
    try {
      final data = await client
          .from('reviews')
          .select('''
            *,
            trips ( id, trip_date, status )
          ''')
          .eq('driver_id', driverId)
          .not('driver_rating', 'is', null)
          .order('created_at', ascending: false)
          .limit(limit);
      return Success(
        (data as List).map((e) => ReviewModel.fromMap(e)).toList(),
      );
    } catch (e) {
      return Failure('Failed to load driver reviews', error: e);
    }
  }

  Future<Result<double>> getDriverAverageRating(String driverId) async {
    try {
      final result = await client.rpc('get_driver_avg_rating', params: {
        'p_driver_id': driverId,
      });
      return Success((result as num).toDouble());
    } catch (e) {
      return Failure('Failed to load driver rating', error: e);
    }
  }
}
