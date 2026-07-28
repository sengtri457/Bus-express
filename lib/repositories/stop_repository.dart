import '../core/error/result.dart';
import '../models/route_stop_model.dart';
import '../models/stop_model.dart';
import 'base_repository.dart';

class StopRepository extends BaseRepository {
  StopRepository() : super('stops');

  Future<Result<List<StopModel>>> getAllStops() async {
    try {
      final data = await client
          .from('stops')
          .select('*')
          .order('name');
      return Success(
        data.map((e) => StopModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return Failure('Failed to load stops', error: e);
    }
  }

  Future<Result<StopModel>> createStop({
    required String name,
    double? lat,
    double? lng,
  }) async {
    try {
      final data = await client
          .from('stops')
          .insert({
            'name': name,
            if (lat != null) 'lat': lat,
            if (lng != null) 'lng': lng,
          })
          .select()
          .single();
      return Success(StopModel.fromJson(data as Map<String, dynamic>));
    } catch (e) {
      return Failure('Failed to create stop', error: e);
    }
  }

  Future<Result<StopModel>> updateStop({
    required String id,
    required String name,
    double? lat,
    double? lng,
  }) async {
    try {
      final data = await client
          .from('stops')
          .update({
            'name': name,
            if (lat != null) 'lat': lat,
            if (lng != null) 'lng': lng,
          })
          .eq('id', id)
          .select()
          .single();
      return Success(StopModel.fromJson(data as Map<String, dynamic>));
    } catch (e) {
      return Failure('Failed to update stop', error: e);
    }
  }

  Future<Result<void>> deleteStop(String id) async {
    try {
      await client.from('stops').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete stop', error: e);
    }
  }

  Future<Result<List<RouteStopModel>>> getStopsByRoute(String routeId) async {
    try {
      final data = await client
          .from('route_stops')
          .select('*, stops(*)')
          .eq('route_id', routeId)
          .order('stop_order');
      return Success(
        data.map((e) => RouteStopModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return Failure('Failed to load route stops', error: e);
    }
  }

  Future<Result<RouteStopModel>> addStopToRoute({
    required String routeId,
    required String stopId,
    required int stopOrder,
    required int arrivalOffset,
    required int departureOffset,
  }) async {
    try {
      final data = await client
          .from('route_stops')
          .insert({
            'route_id': routeId,
            'stop_id': stopId,
            'stop_order': stopOrder,
            'arrival_offset': arrivalOffset,
            'departure_offset': departureOffset,
          })
          .select('*, stops(*)')
          .single();
      return Success(RouteStopModel.fromJson(data as Map<String, dynamic>));
    } catch (e) {
      return Failure('Failed to add stop to route', error: e);
    }
  }

  Future<Result<void>> removeStopFromRoute({
    required String routeId,
    required String stopId,
  }) async {
    try {
      await client
          .from('route_stops')
          .delete()
          .eq('route_id', routeId)
          .eq('stop_id', stopId);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to remove stop from route', error: e);
    }
  }

  Future<Result<void>> saveRouteStops({
    required String routeId,
    required List<Map<String, dynamic>> stops,
  }) async {
    try {
      await client.from('route_stops').delete().eq('route_id', routeId);
      if (stops.isNotEmpty) {
        final inserts = stops.map((s) => {
          'route_id': routeId,
          'stop_id': s['stop_id'],
          'stop_order': s['stop_order'],
          'arrival_offset': s['arrival_offset'],
          'departure_offset': s['departure_offset'],
        }).toList();
        await client.from('route_stops').insert(inserts);
      }
      return const Success(null);
    } catch (e) {
      return Failure('Failed to save route stops', error: e);
    }
  }
}
