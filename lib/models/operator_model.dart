class OperatorModel {
  final String id;
  final String name;
  final String? contact;
  final String? status;
  final DateTime? createdAt;
  final String? logoUrl;

  const OperatorModel({
    required this.id,
    required this.name,
    this.contact,
    this.status,
    this.createdAt,
    this.logoUrl,
  });

  factory OperatorModel.fromMap(Map<String, dynamic> map) {
    return OperatorModel(
      id: map['id'] as String,
      name: map['name'] as String,
      contact: map['contact'] as String?,
      status: map['status'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      logoUrl: map['logo_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    if (contact != null) 'contact': contact,
    if (status != null) 'status': status,
    if (logoUrl != null) 'logo_url': logoUrl,
  };

  String get initials => name.isNotEmpty
      ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
      : 'OP';
}
