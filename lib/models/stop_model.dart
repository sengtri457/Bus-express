class StopModel {
  final String id;
  final String name;
  final double? lat;
  final double? lng;

  const StopModel({
    required this.id,
    required this.name,
    this.lat,
    this.lng,
  });

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
  };
}
