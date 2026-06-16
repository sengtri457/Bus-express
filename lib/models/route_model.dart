class RouteModel {
  final String id;
  final String? operatorId;
  final String name;
  final String origin;
  final String destination;
  final double? distanceKm;
  final int? durationMin;
  final String? status;
  final String? operatorName;
  final String? operatorLogoUrl;

  const RouteModel({
    required this.id,
    this.operatorId,
    required this.name,
    required this.origin,
    required this.destination,
    this.distanceKm,
    this.durationMin,
    this.status,
    this.operatorName,
    this.operatorLogoUrl,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    final operators = map['operators'] as Map<String, dynamic>?;
    return RouteModel(
      id: map['id'] as String,
      operatorId: map['operator_id'] as String?,
      name: map['name'] as String,
      origin: map['origin'] as String,
      destination: map['destination'] as String,
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      durationMin: map['duration_min'] as int?,
      status: map['status'] as String?,
      operatorName: operators?['name'] as String?,
      operatorLogoUrl: operators?['logo_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    if (operatorId != null) 'operator_id': operatorId,
    'name': name,
    'origin': origin,
    'destination': destination,
    if (distanceKm != null) 'distance_km': distanceKm,
    if (durationMin != null) 'duration_min': durationMin,
    if (status != null) 'status': status,
  };

  String get displayName => '$origin → $destination';
}
