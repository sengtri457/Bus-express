import 'bus_model.dart';
import 'route_model.dart';
import 'user_model.dart';

class ScheduleModel {
  final String id;
  final String? routeId;
  final String? busId;
  final String? driverId;
  final String? conductorId;
  final String departureTime;
  final String arrivalTime;
  final String? daysOfWeek;
  final double? price;
  final String? status;
  final RouteModel? route;
  final BusModel? bus;
  final UserModel? driver;

  const ScheduleModel({
    required this.id,
    this.routeId,
    this.busId,
    this.driverId,
    this.conductorId,
    required this.departureTime,
    required this.arrivalTime,
    this.daysOfWeek,
    this.price,
    this.status,
    this.route,
    this.bus,
    this.driver,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] as String,
      routeId: map['route_id'] as String?,
      busId: map['bus_id'] as String?,
      driverId: map['driver_id'] as String?,
      conductorId: map['conductor_id'] as String?,
      departureTime: map['departure_time'] as String,
      arrivalTime: map['arrival_time'] as String,
      daysOfWeek: map['days_of_week'] as String?,
      price: (map['price'] as num?)?.toDouble(),
      status: map['status'] as String?,
      route: map['routes'] != null
          ? RouteModel.fromMap(map['routes'] as Map<String, dynamic>)
          : null,
      bus: map['buses'] != null
          ? BusModel.fromMap(map['buses'] as Map<String, dynamic>)
          : null,
      driver: map['users'] != null
          ? UserModel.fromMap(map['users'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    if (routeId != null) 'route_id': routeId,
    if (busId != null) 'bus_id': busId,
    if (driverId != null) 'driver_id': driverId,
    if (conductorId != null) 'conductor_id': conductorId,
    'departure_time': departureTime,
    'arrival_time': arrivalTime,
    if (daysOfWeek != null) 'days_of_week': daysOfWeek,
    if (price != null) 'price': price,
    if (status != null) 'status': status,
    if (route != null) 'routes': route!.toMap(),
    if (bus != null) 'buses': bus!.toMap(),
    if (driver != null) 'users': driver!.toMap(),
  };

  int get departureMinutes {
    final parts = departureTime.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int get arrivalMinutes {
    final parts = arrivalTime.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int get durationMinutes {
    final arr = arrivalMinutes;
    final dep = departureMinutes;
    return arr >= dep ? arr - dep : (arr + 1440) - dep;
  }
}
