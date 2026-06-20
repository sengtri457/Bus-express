class PaymentModel {
  final String id;
  final String? bookingId;
  final double? amount;
  final String method;
  final String status;
  final String? transactionId;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const PaymentModel({
    required this.id,
    this.bookingId,
    this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.paidAt,
    this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
    id: map['id'] as String,
    bookingId: map['booking_id'] as String?,
    amount: (map['amount'] as num?)?.toDouble(),
    method: map['method'] as String,
    status: map['status'] as String,
    transactionId: map['transaction_id'] as String?,
    paidAt: map['paid_at'] != null
        ? DateTime.parse(map['paid_at'] as String).toLocal()
        : null,
    createdAt: map['created_at'] != null
        ? DateTime.parse(map['created_at'] as String).toLocal()
        : null,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    if (bookingId != null) 'booking_id': bookingId,
    if (amount != null) 'amount': amount,
    'method': method,
    'status': status,
    if (transactionId != null) 'transaction_id': transactionId,
    if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
  };

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isRefunded => status == 'refunded';
  bool get isBakong => method == 'bakong';
}
