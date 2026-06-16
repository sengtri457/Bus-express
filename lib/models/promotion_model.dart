class PromotionModel {
  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final double? minPurchase;
  final int? maxUsage;
  final int? maxPerUser;
  final int usedCount;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const PromotionModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minPurchase,
    this.maxUsage,
    this.maxPerUser,
    this.usedCount = 0,
    this.isActive = true,
    this.expiresAt,
    this.createdAt,
  });

  factory PromotionModel.fromMap(Map<String, dynamic> map) {
    return PromotionModel(
      id: map['id'] as String,
      code: map['code'] as String,
      discountType: map['discount_type'] as String,
      discountValue: (map['discount_value'] as num).toDouble(),
      minPurchase: (map['min_purchase'] as num?)?.toDouble(),
      maxUsage: map['max_usage'] as int?,
      maxPerUser: map['max_per_user'] as int?,
      usedCount: map['used_count'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String).toLocal()
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String).toLocal()
          : null,
    );
  }

  bool get isPercentage => discountType == 'percentage';
  bool get isFixed => discountType == 'fixed';
  bool get hasExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isValid => isActive && !hasExpired;

  double applyDiscount(double amount) {
    if (!isValid) return amount;
    if (isPercentage) {
      return amount - (amount * discountValue / 100);
    }
    return amount - discountValue;
  }
}
