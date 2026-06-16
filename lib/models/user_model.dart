class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final String? status;
  final String? operatorId;
  final int? age;
  final String? nationality;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.status,
    this.operatorId,
    this.age,
    this.nationality,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      role: map['role'] as String?,
      status: map['status'] as String?,
      operatorId: map['operator_id'] as String?,
      age: map['age'] as int?,
      nationality: map['nationality'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    if (name != null) 'name': name,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (role != null) 'role': role,
    if (status != null) 'status': status,
    if (operatorId != null) 'operator_id': operatorId,
    if (age != null) 'age': age,
    if (nationality != null) 'nationality': nationality,
  };

  String get initials => name != null && name!.isNotEmpty
      ? name!.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
      : email?[0].toUpperCase() ?? '?';

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isPassenger => role == 'passenger';
  bool get isDriver => role == 'driver';
  bool get isConductor => role == 'conductor';
  bool get isOperatorAdmin => role == 'operator_admin';
  bool get isSuperAdmin => role == 'super_admin';

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? status,
    String? operatorId,
    int? age,
    String? nationality,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      operatorId: operatorId ?? this.operatorId,
      age: age ?? this.age,
      nationality: nationality ?? this.nationality,
      createdAt: createdAt,
    );
  }
}
