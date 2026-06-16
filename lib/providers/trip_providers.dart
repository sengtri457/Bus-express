import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/result.dart';
import '../models/trip_model.dart';
import '../repositories/trip_repository.dart';
import 'auth_provider.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) => TripRepository());

final driverTripsProvider = FutureProvider<List<TripModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  final repo = ref.watch(tripRepositoryProvider);
  final result = await repo.getDriverTrips(user.id);
  return result is Success<List<TripModel>> ? result.data : [];
});

final conductorTripsProvider = FutureProvider<List<TripModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  final repo = ref.watch(tripRepositoryProvider);
  final result = await repo.getConductorTrips(user.id);
  return result is Success<List<TripModel>> ? result.data : [];
});

final activeTripProvider = FutureProvider<TripModel?>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return null;
  final repo = ref.watch(tripRepositoryProvider);
  final result = await repo.getActiveTrip(user.id);
  return result is Success<TripModel?> ? result.data : null;
});

final tripDetailProvider = FutureProvider.family<TripModel?, String>(
  (ref, tripId) async {
    final repo = ref.watch(tripRepositoryProvider);
    final result = await repo.getTripById(tripId);
    return result is Success<TripModel> ? result.data : null;
  },
);
