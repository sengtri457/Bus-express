import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/tr_extension.dart';
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
  final GlobalKey _qrKey = GlobalKey();
  bool _isSavingImage = false;

  Timer? _countdownTimer;
  Timer? _pollTimer;
  int _secondsRemaining = 0;
  bool _isPolling = false;
  String _statusMessage = '';
  bool _isSuccess = false;
  bool _isExpired = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Future<void> _saveQrToGallery() async {
    if (_isSavingImage) return;
    setState(() => _isSavingImage = true);

    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final requestGranted = await Gal.requestAccess(toAlbum: true);
        if (!requestGranted) {
          _showSnackBar('Permission to save to gallery was denied', isError: true);
          setState(() => _isSavingImage = false);
          return;
        }
      }

      final boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Failed to generate image bytes');
      }
      
      final pngBytes = byteData.buffer.asUint8List();

      await Gal.putImageBytes(pngBytes, name: 'KHQR_${DateTime.now().millisecondsSinceEpoch}.png');

      if (mounted) {
        _showSnackBar('QR Code saved to gallery successfully!', isError: false);
      }
    } catch (e) {
      debugPrint('[BakongScreen] Error saving QR: $e');
      if (mounted) {
        _showSnackBar('Failed to save QR code: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingImage = false);
      }
    }
  }

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

  /// Confirms before abandoning payment, since leaving cancels the
  /// booking and frees the seats. Skipped once paid or expired — there
  /// is nothing left to lose in either case.
  Future<bool> _confirmAbandonPayment() async {
    if (_isSuccess || _isExpired) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlR),
        title: Text(
          context.tr.paymentLeaveTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(context.tr.paymentLeaveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr.paymentLeaveStay),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr.paymentLeaveCancel),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _handleAbandon() async {
    if (await _confirmAbandonPayment() && mounted) {
      Navigator.of(context).pop(const BakongPaymentResult(isSuccess: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleAbandon();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppGradients.primaryBlue),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Bakong KHQR Payment',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _isSuccess ? null : _handleAbandon,
          ),
        ),
        body: SafeArea(
          child: _isExpired ? _buildExpiredView() : _buildPaymentView(),
        ),
      ),
    );
  }

  Widget _buildPaymentView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                _buildKhqrCard(),
                const SizedBox(height: 24),
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

  Widget _buildKhqrCard() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isSuccess ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Red Header
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE52329), // Brand Red
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'KH',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'QR',
                            style: TextStyle(
                              color: Color(0xFFE52329),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Merchant & Amount Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.merchantName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            widget.amount.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'USD',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Dashed Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(
                      24,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 1.5,
                          color: index % 2 == 0 ? Colors.transparent : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. QR Code Area with center emblem
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Center(
                    child: RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: QrImageView(
                                data: widget.khqrString,
                                size: 200,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            // Center Emblem
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE52329),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '\$',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Color(0xFFF59E0B),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Open your banking app, scan this QR code, and complete the payment. Your booking will be confirmed automatically.',
              style: TextStyle(
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
          color: isLow ? const Color(0xFFFECACA) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLow ? Icons.timer_off_rounded : Icons.timer_rounded,
            size: 18,
            color: isLow ? AppColors.error : AppColors.textSecondary,
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
              color: isLow ? const Color(0xFFDC2626) : AppColors.textDark,
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
      iconColor = AppColors.successGreen;
      icon = Icons.check_circle_rounded;
      text = 'Payment confirmed! Redirecting...';
    } else if (_isPolling) {
      bgColor = const Color(0xFFEFF6FF);
      iconColor = AppColors.primaryBlue;
      icon = Icons.hourglass_top_rounded;
      text = 'Checking payment...';
    } else if (_statusMessage.contains('failed') ||
        _statusMessage.contains('Failed')) {
      bgColor = const Color(0xFFFEF2F2);
      iconColor = AppColors.error;
      icon = Icons.error_outline_rounded;
      text = _statusMessage;
    } else {
      bgColor = const Color(0xFFF9FAFB);
      iconColor = AppColors.textHint;
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
              color: AppColors.error,
            ),
            const SizedBox(height: 20),
            const Text(
              'QR Code Expired',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'The payment QR code is no longer valid. Please go back and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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
                backgroundColor: AppColors.primaryBlue,
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

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: (_isExpired || _isSuccess || _isSavingImage) ? null : _saveQrToGallery,
                    icon: _isSavingImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Save QR Code'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (_isPolling || _isExpired || _isSuccess)
                        ? null
                        : _checkNow,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Check Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF93C5FD),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
