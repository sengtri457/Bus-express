import '../core/error/result.dart';
import '../models/schedule_model.dart';
import 'base_repository.dart';

class ScheduleRepository extends BaseRepository {
  ScheduleRepository() : super('schedules');

  static const _scheduleSelect = '''
    id, departure_time, arrival_time, price, days_of_week, status,
    routes!inner ( id, name, origin, destination, distance_km, duration_min,
      operators ( id, name, logo_url )
    ),
    buses ( id, plate_number, model, capacity ),
    users!schedules_driver_id_fkey ( id, name )
  ''';

  Future<Result<List<ScheduleModel>>> getSchedulesByRoute(String routeId) async {
    try {
      final data = await client
          .from('schedules')
          .select(_scheduleSelect)
          .eq('route_id', routeId)
          .eq('status', 'active')
          .order('departure_time', ascending: true);
      return Success(data.map((e) => ScheduleModel.fromMap(e)).toList());
    } catch (e) {
      return Failure('Failed to load schedules', error: e);
    }
  }

  Future<Result<List<ScheduleModel>>> getActiveSchedules() async {
    try {
      final data = await client
          .from('schedules')
          .select(_scheduleSelect)
          .eq('status', 'active')
          .order('departure_time', ascending: true);
      return Success(data.map((e) => ScheduleModel.fromMap(e)).toList());
    } catch (e) {
      return Failure('Failed to load schedules', error: e);
    }
  }

  Future<Result<List<ScheduleModel>>> getOperatorSchedules(
    String routeId,
  ) async {
    try {
      final data = await client
          .from('schedules')
          .select('''
            id, departure_time, arrival_time, days_of_week, price, status,
            buses ( id, plate_number, model, capacity )
          ''')
          .eq('route_id', routeId)
          .order('departure_time', ascending: true);
      return Success(data.map((e) => ScheduleModel.fromMap(e)).toList());
    } catch (e) {
      return Failure('Failed to load schedules', error: e);
    }
  }

  Future<Result<List<ScheduleModel>>> getDriverSchedules(
    String driverId,
  ) async {
    try {
      final data = await client
          .from('schedules')
          .select(_scheduleSelect)
          .eq('driver_id', driverId)
          .eq('status', 'active')
          .order('departure_time', ascending: true);
      return Success(data.map((e) => ScheduleModel.fromMap(e)).toList());
    } catch (e) {
      return Failure('Failed to load driver schedules', error: e);
    }
  }
}
