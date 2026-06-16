import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/result.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';
import 'auth_provider.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(),
);

final passengerBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  final repo = ref.watch(bookingRepositoryProvider);
  final result = await repo.getPassengerBookings(user.id);
  return result is Success<List<BookingModel>> ? result.data : [];
});

final tripBookingsProvider = FutureProvider.family<List<BookingModel>, String>(
  (ref, tripId) async {
    final repo = ref.watch(bookingRepositoryProvider);
    final result = await repo.getTripBookings(tripId);
    return result is Success<List<BookingModel>> ? result.data : [];
  },
);

final bookedSeatsProvider = FutureProvider.family<List<String>, String>(
  (ref, tripId) async {
    final repo = ref.watch(bookingRepositoryProvider);
    final result = await repo.getBookedSeats(tripId);
    return result is Success<List<String>> ? result.data : [];
  },
);
