import 'stop_model.dart';

class RouteStopModel {
  final String id;
  final String routeId;
  final String stopId;
  final int stopOrder;
  final int arrivalOffset;
  final int departureOffset;
  final StopModel? stop;

  const RouteStopModel({
    required this.id,
    required this.routeId,
    required this.stopId,
    required this.stopOrder,
    required this.arrivalOffset,
    required this.departureOffset,
    this.stop,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      id: json['id'] as String,
      routeId: json['route_id'] as String? ?? '',
      stopId: json['stop_id'] as String? ?? '',
      stopOrder: json['stop_order'] as int? ?? 0,
      arrivalOffset: json['arrival_offset'] as int? ?? 0,
      departureOffset: json['departure_offset'] as int? ?? 0,
      stop: json['stops'] != null
          ? StopModel.fromJson(json['stops'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'route_id': routeId,
    'stop_id': stopId,
    'stop_order': stopOrder,
    'arrival_offset': arrivalOffset,
    'departure_offset': departureOffset,
    if (stop != null) 'stops': stop!.toJson(),
  };

  String get stopName => stop?.name ?? 'Unknown Stop';

  String formatArrivalTime(String departureTime) {
    final parts = departureTime.split(':');
    final depMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final total = depMin + arrivalOffset;
    final h = (total ~/ 60) % 24;
    final m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String formatDepartureTime(String departureTime) {
    final parts = departureTime.split(':');
    final depMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final total = depMin + departureOffset;
    final h = (total ~/ 60) % 24;
    final m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
