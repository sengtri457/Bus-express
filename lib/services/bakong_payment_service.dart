import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:khqrcode/khqrcode.dart';

import '../core/error/result.dart';
import '../supabase_config.dart';

class BakongPaymentService {
  BakongPaymentService._();

  static const _merchantCity = 'Phnom Penh';
  static const _qrExpiryMinutes = 5;
  static const _bakongCurrencyUSD = 840;

  static String get _accountId => SupabaseConfig.bakongAccountId;
  static String get _merchantName => SupabaseConfig.bakongMerchantName;
  static bool get _isConfigured => SupabaseConfig.isBakongConfigured;

  static final BakongKHQR _khqr = BakongKHQR();

  static KhqrGenerationResult generateKhqr({
    required double amount,
    required String billNumber,
  }) {
    debugPrint('[Bakong] generateKhqr() amount=$amount billNumber=$billNumber');

    if (!_isConfigured) {
      debugPrint('[Bakong] ✗ Bakong not configured — missing ACCOUNT_ID');
      return KhqrGenerationResult(
        isSuccess: false,
        error: 'Bakong account not configured',
      );
    }

    final expiry = DateTime.now()
        .add(Duration(minutes: _qrExpiryMinutes))
        .millisecondsSinceEpoch;

    // KHQR billNumber max length is 25 chars — truncate UUID
    final shortBill = billNumber.length > 25
        ? billNumber.substring(0, 8).toUpperCase()
        : billNumber;
    debugPrint('[Bakong]   billNumber $billNumber → $shortBill');

    try {
      final info = IndividualInfo(
        bakongAccountId: _accountId,
        merchantName: _merchantName,
        merchantCity: _merchantCity,
        currency: _bakongCurrencyUSD,
        amount: amount,
        expirationTimestamp: expiry,
        billNumber: shortBill,
      );

      final result = _khqr.generateIndividual(info);
      debugPrint('[Bakong]   KHQR isSuccess=${result.isSuccess} msg=${result.status.message}');

      if (result.isSuccess && result.data != null) {
        debugPrint('[Bakong]   ✓ QR generated, md5Hash=${result.data!.md5Hash.substring(0, 16)}...');
        return KhqrGenerationResult(
          isSuccess: true,
          qr: result.data!.qr,
          md5Hash: result.data!.md5Hash,
          expiryTimestamp: expiry,
        );
      }

      debugPrint('[Bakong]   ✗ KHQR error: ${result.status.message}');
      return KhqrGenerationResult(
        isSuccess: false,
        error: 'KHQR error: ${result.status.message ?? "Unknown"}',
      );
    } catch (e) {
      debugPrint('[Bakong]   ✗ generateKhqr exception: $e');
      return KhqrGenerationResult(
        isSuccess: false,
        error: 'KHQR generation failed: $e',
      );
    }
  }

  static Future<Result<BakongTransactionStatus>> checkTransaction(
    String md5Hash,
  ) async {
    debugPrint('[Bakong] checkTransaction() md5=${md5Hash.substring(0, 16)}...');

    // Try Edge Function first (works globally if proxy is configured)
    debugPrint('[Bakong] → Trying Edge Function...');
    final edgeResult = await _checkViaEdgeFunction(md5Hash);
    if (edgeResult is Success<BakongTransactionStatus>) {
      debugPrint('[Bakong] Edge Function result: ${edgeResult.data.status}');
      if (edgeResult.data.isPaid) {
        debugPrint('[Bakong] ✓ PAID from Edge Function');
        return edgeResult;
      }
      debugPrint('[Bakong] Edge Function returned ${edgeResult.data.status} — falling through to direct');
    } else if (edgeResult is Failure<BakongTransactionStatus>) {
      debugPrint('[Bakong] Edge Function failed: ${edgeResult.error}');
    }

    // Fallback: call Bakong directly from device (works when device is in Cambodia)
    debugPrint('[Bakong] → Trying direct call from device...');
    final directResult = await _checkDirect(md5Hash);
    if (directResult is Success<BakongTransactionStatus>) {
      debugPrint('[Bakong] Direct check result: ${directResult.data.status}');
    } else if (directResult is Failure<BakongTransactionStatus>) {
      debugPrint('[Bakong] Direct check failed: ${directResult.message}');
    }
    return directResult;
  }

  static Future<Result<BakongTransactionStatus>> _checkViaEdgeFunction(
    String md5Hash,
  ) async {
    try {
      final url = Uri.parse(
        '${SupabaseConfig.supabaseUrl}/functions/v1/check-bakong-transaction',
      );
      final anonKey = SupabaseConfig.supabaseAnonKey;

      debugPrint('[Bakong]   EdgeFunction URL: $url');
      debugPrint('[Bakong]   EdgeFunction anonKey: ${anonKey.substring(0, 12)}...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'md5': md5Hash}),
      );

      debugPrint('[Bakong]   EdgeFunction HTTP ${response.statusCode}:'
          ' ${response.body.substring(0, response.body.length.clamp(0, 200))}');

      if (response.statusCode != 200) {
        debugPrint('[Bakong]   ✗ EdgeFunction returned non-200');
        return Failure(
          'Payment check failed (${response.statusCode})',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final bakongStatus = body['status'] as String? ?? '';
      debugPrint('[Bakong]   EdgeFunction parsed status: "$bakongStatus"');

      switch (bakongStatus.toUpperCase()) {
        case 'PAID':
          debugPrint('[Bakong]   ✓ PAID via EdgeFunction');
          return Success(BakongTransactionStatus.paid(
            transactionId: body['transaction_id'] as String?,
          ));
        case 'NOT_PAID':
          debugPrint('[Bakong]   - NOT_PAID via EdgeFunction');
          return Success(BakongTransactionStatus.notPaid());
        case 'FAILED':
          final reason = body['reason'] as String? ?? 'no reason';
          debugPrint('[Bakong]   ✗ FAILED via EdgeFunction: $reason');
          return Success(BakongTransactionStatus.failed(
            reason: reason,
          ));
        default:
          debugPrint('[Bakong]   ? Unexpected status "$bakongStatus" — treating as NOT_PAID');
          return Success(BakongTransactionStatus.notPaid());
      }
    } catch (e) {
      debugPrint('[Bakong]   ✗ EdgeFunction threw: $e');
      return Failure('Edge Function unreachable', error: e);
    }
  }

  /// Direct check from the device (works when device is in Cambodia).
  /// This uses the Bakong access token bundled in .env — for production,
  /// the token should live server-side and be routed through the Cambodia proxy.
  static Future<Result<BakongTransactionStatus>> _checkDirect(
    String md5Hash,
  ) async {
    final token = SupabaseConfig.bakongAccessToken;
    final apiBase = SupabaseConfig.bakongApiUrl;

    debugPrint('[Bakong]   Direct URL: $apiBase/v1/check_transaction_by_md5');
    debugPrint('[Bakong]   Direct token present: ${token.isNotEmpty}');

    if (token.isEmpty) {
      debugPrint('[Bakong]   ✗ No BAKONG_ACCESS_TOKEN in .env — skipping direct check');
      return Success(BakongTransactionStatus.notPaid());
    }

    try {
      final url = Uri.parse('$apiBase/v1/check_transaction_by_md5');
      debugPrint('[Bakong]   Calling Bakong directly...');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'md5': md5Hash}),
      );

      debugPrint('[Bakong]   Direct HTTP ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('[Bakong]   ✗ Direct ${response.statusCode}: ${response.body}');
        return Success(BakongTransactionStatus.notPaid());
      }

      final bakongJson = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('[Bakong]   Direct JSON: $bakongJson');

      final responseCode = bakongJson['responseCode'];
      final data = bakongJson['data'];

      // Bakong check_transaction_by_md5 returns responseCode=0 with populated
      // data when the transaction was paid (hash, fromAccountId, toAccountId,
      // amount, acknowledgedDateMs all present). A null/empty data or non-zero
      // responseCode means not found / unpaid.
      if (responseCode == 0 && data is Map<String, dynamic>) {
        final hash = data['hash'] as String?;
        if (hash != null && hash.isNotEmpty) {
          debugPrint('[Bakong]   ✓ PAID (responseCode=0, data.hash present)');
          return Success(BakongTransactionStatus.paid(
            transactionId: data['hash'] as String?,
          ));
        }
      }

      debugPrint('[Bakong]   - NOT_PAID (responseCode=$responseCode)');
      return Success(BakongTransactionStatus.notPaid());
    } catch (e) {
      debugPrint('[Bakong]   ✗ Direct check threw: $e');
      return Success(BakongTransactionStatus.notPaid());
    }
  }

  static Future<Result<BakongTransactionStatus>> pollTransaction({
    required String md5Hash,
    required Duration interval,
    required Duration timeout,
  }) async {
    final start = DateTime.now();
    final end = start.add(timeout);
    debugPrint('[Bakong] pollTransaction() start=$start timeout=${timeout.inSeconds}s'
        ' interval=${interval.inSeconds}s');

    int attempt = 0;
    while (DateTime.now().isBefore(end)) {
      attempt++;
      debugPrint('[Bakong]   Poll attempt #$attempt...');
      final result = await checkTransaction(md5Hash);
      if (result is Success<BakongTransactionStatus>) {
        debugPrint('[Bakong]   Attempt #$attempt: ${result.data.status}');
        if (result.data.isPaid || result.data.isFailed) {
          debugPrint('[Bakong] ✓ Terminal status reached: ${result.data.status}');
          return result;
        }
      } else if (result is Failure<BakongTransactionStatus>) {
        debugPrint('[Bakong]   Attempt #$attempt error: ${result.message} | ${result.error}');
      }
      debugPrint('[Bakong]   Waiting ${interval.inSeconds}s before next poll...');
      await Future.delayed(interval);
    }

    debugPrint('[Bakong] ✗ Timed out after $attempt attempts');
    return Success(BakongTransactionStatus.timeout());
  }
}

class KhqrGenerationResult {
  final bool isSuccess;
  final String? qr;
  final String? md5Hash;
  final int? expiryTimestamp;
  final String? error;

  const KhqrGenerationResult({
    required this.isSuccess,
    this.qr,
    this.md5Hash,
    this.expiryTimestamp,
    this.error,
  });
}

class BakongTransactionStatus {
  final String status;
  final String? transactionId;
  final String? reason;

  const BakongTransactionStatus._({
    required this.status,
    this.transactionId,
    this.reason,
  });

  factory BakongTransactionStatus.paid({String? transactionId}) =>
      BakongTransactionStatus._(
        status: 'PAID',
        transactionId: transactionId,
      );

  factory BakongTransactionStatus.notPaid() =>
      const BakongTransactionStatus._(status: 'NOT_PAID');

  factory BakongTransactionStatus.failed({String? reason}) =>
      BakongTransactionStatus._(status: 'FAILED', reason: reason);

  factory BakongTransactionStatus.timeout() =>
      const BakongTransactionStatus._(status: 'TIMEOUT');

  bool get isPaid => status == 'PAID';
  bool get isNotPaid => status == 'NOT_PAID';
  bool get isFailed => status == 'FAILED';
  bool get isTimeout => status == 'TIMEOUT';
}
