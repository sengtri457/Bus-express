class IncidentModel {
  final String id;
  final String tripId;
  final String reportedBy;
  final String type;
  final String description;
  final DateTime createdAt;

  const IncidentModel({
    required this.id,
    required this.tripId,
    required this.reportedBy,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory IncidentModel.fromMap(Map<String, dynamic> map) {
    return IncidentModel(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      reportedBy: map['reported_by'] as String,
      type: map['type'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'trip_id': tripId,
    'reported_by': reportedBy,
    'type': type,
    'description': description,
    'created_at': createdAt.toIso8601String(),
  };

  int get delayMinutes {
    switch (type) {
      case 'delay':
        return 20;
      case 'breakdown':
        return 30;
      case 'accident':
        return 45;
      default:
        return 15;
    }
  }
}
