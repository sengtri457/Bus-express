import 'package:flutter/foundation.dart';

import '../models/wallet_model.dart';
import '../supabase_config.dart';

class WalletService {
  WalletService._();

  /// Get or create wallet for the current user.
  static Future<WalletModel?> getWallet(String userId) async {
    try {
      final result = await SupabaseConfig.client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (result != null) return WalletModel.fromMap(result);

      await SupabaseConfig.client.from('wallets').insert({
        'user_id': userId,
        'balance': 0.00,
      });
      return WalletModel(
        userId: userId,
        balance: 0,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[WalletService] getWallet error: $e');
      return null;
    }
  }

  /// Record a transaction and update wallet balance atomically.
  static Future<bool> _recordTransaction({
    required String userId,
    required double amount,
    required String type,
    String? referenceType,
    String? referenceId,
    String description = '',
  }) async {
    try {
      await SupabaseConfig.client.from('wallet_transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': type,
        'reference_type': referenceType,
        'reference_id': referenceId,
        'description': description,
      });

      final wallet = await SupabaseConfig.client
          .from('wallets')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();

      final currentBalance = (wallet?['balance'] as num?)?.toDouble() ?? 0;
      final newBalance = currentBalance + amount;

      await SupabaseConfig.client
          .from('wallets')
          .update({
            'balance': newBalance,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('[WalletService] _recordTransaction error: $e');
      return false;
    }
  }

  /// Credit wallet (positive amount).
  static Future<bool> credit({
    required String userId,
    required double amount,
    required String type,
    String? referenceType,
    String? referenceId,
    String description = '',
  }) =>
      _recordTransaction(
        userId: userId,
        amount: amount.abs(),
        type: type,
        referenceType: referenceType,
        referenceId: referenceId,
        description: description,
      );

  /// Debit wallet (negative amount).
  static Future<bool> debit({
    required String userId,
    required double amount,
    required String type,
    String? referenceType,
    String? referenceId,
    String description = '',
  }) =>
      _recordTransaction(
        userId: userId,
        amount: -amount.abs(),
        type: type,
        referenceType: referenceType,
        referenceId: referenceId,
        description: description,
      );

  /// Get transaction history.
  static Future<List<WalletTransactionModel>> getTransactions(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await SupabaseConfig.client
          .from('wallet_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (result as List)
          .map((e) => WalletTransactionModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[WalletService] getTransactions error: $e');
      return [];
    }
  }
}
