import 'schedule_model.dart';
import 'user_model.dart';

class TripModel {
  final String id;
  final String? scheduleId;
  final String tripDate;
  final String? busId;
  final String? driverId;
  final String? conductorId;
  final String status;
  final DateTime? departedAt;
  final DateTime? arrivedAt;
  final double? latitude;
  final double? longitude;
  final bool? conductorAllowedStart;
  final ScheduleModel? schedule;
  final UserModel? driver;

  const TripModel({
    required this.id,
    this.scheduleId,
    required this.tripDate,
    this.busId,
    this.driverId,
    this.conductorId,
    required this.status,
    this.departedAt,
    this.arrivedAt,
    this.latitude,
    this.longitude,
    this.conductorAllowedStart,
    this.schedule,
    this.driver,
  });

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] as String,
      scheduleId: map['schedule_id'] as String?,
      tripDate: map['trip_date'] as String,
      busId: map['bus_id'] as String?,
      driverId: map['driver_id'] as String?,
      conductorId: map['conductor_id'] as String?,
      status: map['status'] as String,
      departedAt: map['departed_at'] != null
          ? DateTime.parse(map['departed_at'] as String).toLocal()
          : null,
      arrivedAt: map['arrived_at'] != null
          ? DateTime.parse(map['arrived_at'] as String).toLocal()
          : null,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      conductorAllowedStart: map['conductor_allowed_start'] as bool?,
      schedule: map['schedules'] != null
          ? ScheduleModel.fromMap(map['schedules'] as Map<String, dynamic>)
          : null,
      driver: map['users'] != null
          ? UserModel.fromMap(map['users'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    if (scheduleId != null) 'schedule_id': scheduleId,
    'trip_date': tripDate,
    if (busId != null) 'bus_id': busId,
    if (driverId != null) 'driver_id': driverId,
    if (conductorId != null) 'conductor_id': conductorId,
    'status': status,
    if (departedAt != null) 'departed_at': departedAt!.toIso8601String(),
    if (arrivedAt != null) 'arrived_at': arrivedAt!.toIso8601String(),
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (conductorAllowedStart != null) 'conductor_allowed_start': conductorAllowedStart,
    if (schedule != null) 'schedules': schedule!.toMap(),
    if (driver != null) 'users': driver!.toMap(),
  };

  bool get isScheduled => status == 'scheduled';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
