class BusModel {
  final String id;
  final String? operatorId;
  final String plateNumber;
  final String model;
  final int capacity;
  final String? status;

  const BusModel({
    required this.id,
    this.operatorId,
    required this.plateNumber,
    required this.model,
    required this.capacity,
    this.status,
  });

  factory BusModel.fromMap(Map<String, dynamic> map) {
    return BusModel(
      id: map['id'] as String,
      operatorId: map['operator_id'] as String?,
      plateNumber: map['plate_number'] as String,
      model: map['model'] as String,
      capacity: map['capacity'] as int,
      status: map['status'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    if (operatorId != null) 'operator_id': operatorId,
    'plate_number': plateNumber,
    'model': model,
    'capacity': capacity,
    if (status != null) 'status': status,
  };
}
