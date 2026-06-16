class TicketModel {
  final String id;
  final String? bookingId;
  final String? qrCode;
  final String? status;
  final DateTime? scannedAt;
  final String? scannedBy;

  const TicketModel({
    required this.id,
    this.bookingId,
    this.qrCode,
    this.status,
    this.scannedAt,
    this.scannedBy,
  });

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    return TicketModel(
      id: map['id'] as String,
      bookingId: map['booking_id'] as String?,
      qrCode: map['qr_code'] as String?,
      status: map['status'] as String?,
      scannedAt: map['scanned_at'] != null
          ? DateTime.parse(map['scanned_at'] as String).toLocal()
          : null,
      scannedBy: map['scanned_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    if (bookingId != null) 'booking_id': bookingId,
    if (qrCode != null) 'qr_code': qrCode,
    if (status != null) 'status': status,
    if (scannedAt != null) 'scanned_at': scannedAt!.toIso8601String(),
    if (scannedBy != null) 'scanned_by': scannedBy,
  };

  bool get isValid => status == 'valid';
  bool get isUsed => status == 'used';
  bool get isCancelled => status == 'cancelled';
}
