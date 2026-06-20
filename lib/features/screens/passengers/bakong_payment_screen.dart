import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/bakong_payment_service.dart';

class BakongPaymentResult {
  final bool isSuccess;
  final String? transactionId;

  const BakongPaymentResult({required this.isSuccess, this.transactionId});
}

class BakongPaymentScreen extends StatefulWidget {
  final String khqrString;
  final String md5Hash;
  final double amount;
  final int expiryTimestamp;
  final String merchantName;

  const BakongPaymentScreen({
    super.key,
    required this.khqrString,
    required this.md5Hash,
    required this.amount,
    required this.expiryTimestamp,
    this.merchantName = 'Bus Express',
  });

  @override
  State<BakongPaymentScreen> createState() => _BakongPaymentScreenState();
}

class _BakongPaymentScreenState extends State<BakongPaymentScreen>
    with TickerProviderStateMixin {
  Timer? _countdownTimer;
  Timer? _pollTimer;
  int _secondsRemaining = 0;
  bool _isPolling = false;
  String _statusMessage = '';
  bool _isSuccess = false;
  bool _isExpired = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = max(
      0,
      (widget.expiryTimestamp - DateTime.now().millisecondsSinceEpoch) ~/ 1000,
    );
    _statusMessage = 'Scan to pay';
    _startCountdown();
    _startPolling();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startCountdown() {
    debugPrint('[BakongScreen] _startCountdown() ${_secondsRemaining}s remaining');
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _isExpired = true;
          _statusMessage = 'QR code expired';
          debugPrint('[BakongScreen] QR expired');
          _countdownTimer?.cancel();
          _pollTimer?.cancel();
        }
      });
    });
  }

  void _startPolling() {
    debugPrint('[BakongScreen] _startPolling() every 5s md5=${widget.md5Hash.substring(0, 16)}...');
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_isExpired || _isSuccess || !mounted) return;
      if (_isPolling) return;
      _isPolling = true;

      debugPrint('[BakongScreen] Polling check...');
      final result = await BakongPaymentService.checkTransaction(
        widget.md5Hash,
      );
      if (result is Success<BakongTransactionStatus>) {
        debugPrint('[BakongScreen] Poll result: ${result.data.status}');
      } else if (result is Failure<BakongTransactionStatus>) {
        debugPrint('[BakongScreen] Poll error: ${result.message}');
      }

      if (!mounted) return;

      if (result is Success<BakongTransactionStatus>) {
        final status = result.data;
        if (status.isPaid) {
          debugPrint('[BakongScreen] ✓ PAID detected!');
          _isPolling = false;
          _onPaymentSuccess(status.transactionId);
        } else if (status.isFailed) {
          debugPrint('[BakongScreen] ✗ FAILED: ${status.reason}');
          _isPolling = false;
          setState(() {
            _statusMessage = status.reason ?? 'Payment failed';
          });
        } else {
          _isPolling = false;
          debugPrint('[BakongScreen] - Still waiting... (${status.status})');
        }
      } else {
        debugPrint('[BakongScreen] Poll error: ${(result as Failure).message}');
        _isPolling = false;
      }
    });
  }

  void _onPaymentSuccess(String? transactionId) {
    _isSuccess = true;
    _countdownTimer?.cancel();
    _pollTimer?.cancel();

    setState(() {
      _statusMessage = 'Payment received!';
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _pulseController.stop();
      Navigator.of(context).pop(
        BakongPaymentResult(isSuccess: true, transactionId: transactionId),
      );
    });
  }

  Future<void> _checkNow() async {
    if (_isPolling || _isExpired || _isSuccess) return;
    debugPrint('[BakongScreen] _checkNow() manual check triggered');
    setState(() => _isPolling = true);

    final result = await BakongPaymentService.checkTransaction(widget.md5Hash);
    if (result is Success<BakongTransactionStatus>) {
      debugPrint('[BakongScreen] Manual check result: ${result.data.status}');
    } else if (result is Failure<BakongTransactionStatus>) {
      debugPrint('[BakongScreen] Manual check error: ${result.message}');
    }

    if (!mounted) return;

    if (result is Success<BakongTransactionStatus>) {
      final status = result.data;
      if (status.isPaid) {
        debugPrint('[BakongScreen] ✓ Manual check: PAID!');
        _onPaymentSuccess(status.transactionId);
      } else if (status.isNotPaid) {
        debugPrint('[BakongScreen] Manual check: NOT_PAID');
        setState(() {
          _statusMessage = 'Waiting for payment...';
          _isPolling = false;
        });
      } else {
        debugPrint('[BakongScreen] Manual check: FAILED — ${status.reason}');
        setState(() {
          _statusMessage = status.reason ?? 'Check failed';
          _isPolling = false;
        });
      }
    } else if (result is Failure<BakongTransactionStatus>) {
      debugPrint('[BakongScreen] Manual check error: ${result.message}');
      setState(() {
        _statusMessage = result.message;
        _isPolling = false;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _formattedTimer {
    final min = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final sec = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.primaryBlue),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Bakong KHQR Payment',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _isSuccess
              ? null
              : () => Navigator.of(context).pop(
                    const BakongPaymentResult(isSuccess: false),
                  ),
        ),
      ),
      body: SafeArea(
        child: _isExpired ? _buildExpiredView() : _buildPaymentView(),
      ),
    );
  }

  Widget _buildPaymentView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                _buildMerchantHeader(),
                const SizedBox(height: 24),
                _buildAmountCard(),
                const SizedBox(height: 24),
                _buildQrCard(),
                const SizedBox(height: 20),
                _buildInstruction(),
                const SizedBox(height: 16),
                _buildTimerBar(),
                const SizedBox(height: 16),
                _buildStatusCard(),
              ],
            ),
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildMerchantHeader() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: Color(0xFF2563EB),
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.merchantName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          const Text(
            'Amount to Pay',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFF065F46),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'USD',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isSuccess ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: QrImageView(
                    data: widget.khqrString,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF111827),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.security_rounded,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Scan with any Bakong-enabled app',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstruction() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Open your banking app, scan this QR code, and complete the payment. Your booking will be confirmed automatically.',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final isLow = _secondsRemaining < 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLow ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLow ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLow ? Icons.timer_off_rounded : Icons.timer_rounded,
            size: 18,
            color: isLow ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLow ? 'Expiring soon' : 'QR code valid for',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isLow ? const Color(0xFF991B1B) : const Color(0xFF374151),
              ),
            ),
          ),
          Text(
            _formattedTimer,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: isLow ? const Color(0xFFDC2626) : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color bgColor;
    Color iconColor;
    IconData icon;
    String text;

    if (_isSuccess) {
      bgColor = const Color(0xFFF0FDF4);
      iconColor = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
      text = 'Payment confirmed! Redirecting...';
    } else if (_isPolling) {
      bgColor = const Color(0xFFEFF6FF);
      iconColor = const Color(0xFF2563EB);
      icon = Icons.hourglass_top_rounded;
      text = 'Checking payment...';
    } else if (_statusMessage.contains('failed') ||
        _statusMessage.contains('Failed')) {
      bgColor = const Color(0xFFFEF2F2);
      iconColor = const Color(0xFFEF4444);
      icon = Icons.error_outline_rounded;
      text = _statusMessage;
    } else {
      bgColor = const Color(0xFFF9FAFB);
      iconColor = const Color(0xFF9CA3AF);
      icon = Icons.qr_code_scanner_rounded;
      text = 'Waiting for you to scan & pay';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: iconColor,
              ),
            ),
          ),
          if (_isPolling)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildExpiredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timer_off_rounded,
              size: 72,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 20),
            const Text(
              'QR Code Expired',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'The payment QR code is no longer valid. Please go back and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(
                const BakongPaymentResult(isSuccess: false),
              ),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (_isPolling || _isExpired || _isSuccess)
                  ? null
                  : _checkNow,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('I\'ve Paid — Check Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF93C5FD),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: (_isSuccess)
                ? null
                : () => Navigator.of(context).pop(
                      const BakongPaymentResult(isSuccess: false),
                    ),
            child: const Text(
              'Cancel Payment',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
