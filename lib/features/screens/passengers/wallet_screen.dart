import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/wallet_model.dart';
import '../../../services/wallet_service.dart';
import '../../widgets/animations.dart';

class WalletScreen extends StatefulWidget {
  final String userId;

  const WalletScreen({super.key, required this.userId});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletModel? _wallet;
  List<WalletTransactionModel> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      WalletService.getWallet(widget.userId),
      WalletService.getTransactions(widget.userId),
    ]);
    if (!mounted) return;
    setState(() {
      _wallet = results[0] as WalletModel?;
      _transactions = results[1] as List<WalletTransactionModel>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.primaryBlue),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Wallet',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  ShimmerBox(height: 180, borderRadius: 20),
                  SizedBox(height: 24),
                  SkeletonBlock(rows: 3),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildBalanceCard()),
                  SliverToBoxAdapter(child: _buildTransactionHeader()),
                  _transactions.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) =>
                                _buildTransactionItem(_transactions[i]),
                            childCount: _transactions.length,
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _wallet?.balance ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), AppColors.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Wallet Balance',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
              '\$${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Available for booking payments',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          const Text(
            'Transaction History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          if (_transactions.isNotEmpty)
            Text(
              '${_transactions.length} entries',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Refunds from cancelled bookings\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransactionModel txn) {
    final isCredit = txn.isCredit;
    final dateStr = DateFormat('MMM d, yyyy – h:mm a').format(txn.createdAt.toLocal());

    IconData icon;
    Color iconColor;
    switch (txn.type) {
      case 'refund':
        icon = Icons.replay_rounded;
        iconColor = AppColors.successGreen;
        break;
      case 'payment':
        icon = Icons.arrow_upward_rounded;
        iconColor = AppColors.error;
        break;
      case 'top_up':
        icon = Icons.add_circle_rounded;
        iconColor = AppColors.successGreen;
        break;
      case 'withdrawal':
        icon = Icons.logout_rounded;
        iconColor = AppColors.error;
        break;
      default:
        icon = Icons.swap_horiz_rounded;
        iconColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _txnTitle(txn),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : ''}\$${txn.amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isCredit ? AppColors.successGreen : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  String _txnTitle(WalletTransactionModel txn) {
    if (txn.description.isNotEmpty) return txn.description;
    switch (txn.type) {
      case 'refund':
        return 'Booking Refund';
      case 'payment':
        return 'Payment';
      case 'top_up':
        return 'Top Up';
      case 'withdrawal':
        return 'Withdrawal';
      default:
        return 'Transaction';
    }
  }
}
