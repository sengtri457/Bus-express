import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../supabase_config.dart';

class SeeAllPromotionsScreen extends StatefulWidget {
  const SeeAllPromotionsScreen({super.key});

  @override
  State<SeeAllPromotionsScreen> createState() => _SeeAllPromotionsScreenState();
}

class _SeeAllPromotionsScreenState extends State<SeeAllPromotionsScreen> {
  List<Map<String, dynamic>> _promotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseConfig.client
          .from('promotions')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _promotions = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Promo code "$code" copied!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDiscount(Map<String, dynamic> promo) {
    final type = promo['discount_type'] as String;
    final value = (promo['discount_value'] as num).toDouble();
    if (type == 'percentage') return '${value.toStringAsFixed(0)}% OFF';
    return '\$${value.toStringAsFixed(2)} OFF';
  }

  String? _formatExpiry(String? expiresAt) {
    if (expiresAt == null) return null;
    try {
      final date = DateTime.parse(expiresAt);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return null;
    }
  }

  Color _cardColor(int index) {
    const colors = [
      Color(0xFFFFEAE9),
      Color(0xFFFEF3C7),
      Color(0xFFE0F2FE),
      Color(0xFFF3E8FF),
      Color(0xFFD1FAE5),
      Color(0xFFFFE4E6),
    ];
    return colors[index % colors.length];
  }

  Color _badgeColor(int index) {
    const colors = [
      Color(0xFF5B5251),
      Color(0xFF5B5251),
      Color(0xFF1E293B),
      Color(0xFF1E293B),
      Color(0xFF065F46),
      Color(0xFF991B1B),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Promotions',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : _promotions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.discount_outlined,
                        size: 64,
                        color: const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No promotions available right now',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check back later for exciting offers!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPromotions,
                  color: const Color(0xFF2563EB),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _promotions.length,
                    itemBuilder: (context, index) {
                      final promo = _promotions[index];
                      final code = promo['code'] as String;
                      final discount = _formatDiscount(promo);
                      final expiry = _formatExpiry(promo['expires_at'] as String?);
                      final minPurchase = (promo['min_purchase'] as num?)?.toDouble();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _cardColor(index),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -30,
                                top: -30,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _badgeColor(index),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              discount,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          GestureDetector(
                                            onTap: () => _copyCode(code),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(30),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.04),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.local_offer_outlined,
                                                    size: 13,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    code,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF1E293B),
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.copy_rounded,
                                                    size: 14,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (minPurchase != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Min. purchase: \$${minPurchase.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(0.35),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.5),
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              discount.contains('%')
                                                  ? discount.replaceAll(' OFF', '')
                                                  : '\$${(promo['discount_value'] as num).toDouble().toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: discount.contains('%') ? 14 : 16,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFFDC2626).withOpacity(0.85),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (expiry != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            expiry,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
