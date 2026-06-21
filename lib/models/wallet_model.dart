class WalletModel {
  final String userId;
  final double balance;
  final DateTime updatedAt;

  const WalletModel({
    required this.userId,
    required this.balance,
    required this.updatedAt,
  });

  factory WalletModel.fromMap(Map<String, dynamic> map) => WalletModel(
        userId: map['user_id'] as String,
        balance: (map['balance'] as num).toDouble(),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}

class WalletTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final String? referenceType;
  final String? referenceId;
  final String description;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.referenceType,
    this.referenceId,
    this.description = '',
    required this.createdAt,
  });

  factory WalletTransactionModel.fromMap(Map<String, dynamic> map) =>
      WalletTransactionModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] as String,
        referenceType: map['reference_type'] as String?,
        referenceId: map['reference_id'] as String?,
        description: map['description'] as String? ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;
}
