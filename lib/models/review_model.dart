import 'trip_model.dart';
import 'user_model.dart';

class ReviewModel {
  final String id;
  final String bookingId;
  final String tripId;
  final String userId;
  final int rating;
  final String comment;
  final String? driverId;
  final int? driverRating;
  final DateTime createdAt;
  final TripModel? trip;
  final UserModel? driver;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.tripId,
    required this.userId,
    required this.rating,
    this.comment = '',
    this.driverId,
    this.driverRating,
    required this.createdAt,
    this.trip,
    this.driver,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] as String,
      bookingId: map['booking_id'] as String,
      tripId: map['trip_id'] as String,
      userId: map['user_id'] as String,
      rating: map['rating'] as int,
      comment: map['comment'] as String? ?? '',
      driverId: map['driver_id'] as String?,
      driverRating: map['driver_rating'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      trip: map['trips'] != null
          ? TripModel.fromMap(map['trips'] as Map<String, dynamic>)
          : null,
      driver: map['driver'] != null
          ? UserModel.fromMap(map['driver'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'booking_id': bookingId,
    'trip_id': tripId,
    'user_id': userId,
    'rating': rating,
    if (comment.isNotEmpty) 'comment': comment,
    if (driverId != null) 'driver_id': driverId,
    if (driverRating != null) 'driver_rating': driverRating,
    'created_at': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toInsertMap() => {
    'booking_id': bookingId,
    'trip_id': tripId,
    'user_id': userId,
    'rating': rating,
    if (comment.isNotEmpty) 'comment': comment,
    if (driverId != null) 'driver_id': driverId,
    if (driverRating != null) 'driver_rating': driverRating,
  };
}
