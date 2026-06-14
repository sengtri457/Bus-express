import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../services/notification_service.dart';
import '../../../supabase_config.dart';

class ConductorScannerScreen extends StatefulWidget {
  final String tripId;
  const ConductorScannerScreen({super.key, required this.tripId});

  @override
  State<ConductorScannerScreen> createState() => _ConductorScannerScreenState();
}

class _ConductorScannerScreenState extends State<ConductorScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();

  bool _isProcessing = false;
  _ScanResult? _lastResult;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _processQRCode(String qrCode) async {
    // 1. Prevent duplicate rapid scans of the same/next QR code while the result card is visible
    if (_isProcessing || _lastResult != null) return;
    setState(() => _isProcessing = true);

    try {
      // Step 1: Find ticket by QR code
      final ticketData = await SupabaseConfig.client
          .from('tickets')
          .select('''
            id, status, scanned_at,
            bookings (
              id, status, seat_number, trip_id,
              users!bookings_passenger_id_fkey ( name, phone )
            )
          ''')
          .eq('qr_code', qrCode)
          .maybeSingle();

      if (ticketData == null) {
        _showResult(
          _ScanResult(
            success: false,
            message: 'Invalid QR Code',
            subMessage: 'This ticket was not found in the system.',
            icon: Icons.qr_code_rounded,
          ),
        );
        return;
      }

      // Defensively parse booking data to handle both Map and List responses from PostgREST
      final bookingRaw = ticketData['bookings'];
      Map<String, dynamic>? booking;
      if (bookingRaw is List && bookingRaw.isNotEmpty) {
        booking = bookingRaw.first as Map<String, dynamic>?;
      } else if (bookingRaw is Map) {
        booking = bookingRaw as Map<String, dynamic>?;
      }

      if (booking == null) {
        _showResult(
          _ScanResult(
            success: false,
            message: 'No Booking Found',
            subMessage: 'This ticket is not associated with a booking.',
            icon: Icons.error_outline_rounded,
          ),
        );
        return;
      }

      final ticketStatus = ticketData['status'] as String;
      final bookingTripId = booking['trip_id'] as String?;

      // Step 2: Check ticket belongs to this trip
      if (bookingTripId != widget.tripId) {
        _showResult(
          _ScanResult(
            success: false,
            message: 'Wrong Trip',
            subMessage:
                'This ticket is not for this trip. Please check the bus.',
            icon: Icons.wrong_location_rounded,
          ),
        );
        return;
      }

      // Step 3: Check ticket status
      if (ticketStatus == 'used') {
        final scannedAt = ticketData['scanned_at'] as String?;
        _showResult(
          _ScanResult(
            success: false,
            message: 'Already Scanned',
            subMessage: scannedAt != null
                ? 'Scanned at ${_formatTimestamp(scannedAt)}'
                : 'This ticket has already been used.',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFF59E0B),
          ),
        );
        return;
      }

      if (ticketStatus == 'cancelled' || ticketStatus == 'expired') {
        _showResult(
          _ScanResult(
            success: false,
            message: 'Invalid Ticket',
            subMessage: 'This ticket is $ticketStatus and cannot be used.',
            icon: Icons.cancel_rounded,
          ),
        );
        return;
      }

      // Step 4: Valid! Mark as boarded
      final conductorId = SupabaseConfig.client.auth.currentUser?.id;

      await SupabaseConfig.client
          .from('tickets')
          .update({
            'status': 'used',
            'scanned_at': DateTime.now().toIso8601String(),
            'scanned_by': conductorId,
          })
          .eq('id', ticketData['id']);

      await SupabaseConfig.client
          .from('bookings')
          .update({'status': 'boarded'})
          .eq('id', booking['id']);

      final passengerId = booking['passenger_id'] as String?;
      if (passengerId != null) {
        unawaited(
          NotificationService.instance.insertNotification(
            userId: passengerId,
            title: 'Ticket Validated',
            body:
                'Your ticket for seat ${booking['seat_number']} has been scanned. Enjoy your trip!',
            type: 'ticket_scanned',
            referenceType: 'booking',
            referenceId: booking['id'] as String?,
          ),
        );
      }

      // Defensively parse passenger (users) data to handle both 'users' and alias keys
      final passengerRaw =
          booking['users'] ?? booking['users!bookings_passenger_id_fkey'];
      Map<String, dynamic>? passenger;
      if (passengerRaw is List && passengerRaw.isNotEmpty) {
        passenger = passengerRaw.first as Map<String, dynamic>?;
      } else if (passengerRaw is Map) {
        passenger = passengerRaw as Map<String, dynamic>?;
      }

      _showResult(
        _ScanResult(
          success: true,
          message: 'Boarded! ✅',
          subMessage:
              '${passenger?['name'] ?? 'Passenger'} • Seat ${booking['seat_number']}',
          icon: Icons.check_circle_rounded,
          passengerName: passenger?['name'],
          seatNumber: booking['seat_number'],
        ),
      );
    } catch (e) {
      _showResult(
        _ScanResult(
          success: false,
          message: 'Scan Error',
          subMessage: e.toString(),
          icon: Icons.error_outline_rounded,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showResult(_ScanResult result) {
    setState(() => _lastResult = result);
    // Auto clear after 3 seconds and resume scanning
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _lastResult = null);
    });
  }

  String _formatTimestamp(String ts) {
    final dt = DateTime.parse(ts).toLocal();
    final h = dt.hour;
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scan Ticket',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processQRCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Scan overlay
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scan frame
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _lastResult == null
                          ? Colors.white
                          : _lastResult!.success
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Corner decorations
                      _Corner(Alignment.topLeft),
                      _Corner(Alignment.topRight),
                      _Corner(Alignment.bottomLeft),
                      _Corner(Alignment.bottomRight),

                      // Scan line animation
                      if (_lastResult == null) const _ScanLine(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isProcessing
                        ? 'Processing...'
                        : 'Point camera at passenger QR code',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // Result overlay
          if (_lastResult != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ResultCard(result: _lastResult!),
            ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Scan Result ──────────────────────────────────────────────────────────────

class _ScanResult {
  final bool success;
  final String message;
  final String subMessage;
  final IconData icon;
  final Color? color;
  final String? passengerName;
  final String? seatNumber;

  const _ScanResult({
    required this.success,
    required this.message,
    required this.subMessage,
    required this.icon,
    this.color,
    this.passengerName,
    this.seatNumber,
  });
}

// ─── Result Card ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _ScanResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final color =
        result.color ??
        (result.success ? const Color(0xFF10B981) : const Color(0xFFEF4444));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(result.icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.subMessage,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan Line Animation ──────────────────────────────────────────────────────

class _ScanLine extends StatefulWidget {
  const _ScanLine();

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _) => Positioned(
        top: _animation.value * 240,
        left: 10,
        right: 10,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                const Color(0xFF7C3AED),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Corner Decoration ────────────────────────────────────────────────────────

class _Corner extends StatelessWidget {
  final AlignmentGeometry alignment;
  const _Corner(this.alignment);

  @override
  Widget build(BuildContext context) {
    const size = 24.0;
    const thickness = 4.0;
    const color = Color(0xFF7C3AED);
    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    final isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CornerPainter(
            isLeft: isLeft,
            isTop: isTop,
            color: color,
            thickness: thickness,
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isLeft;
  final bool isTop;
  final Color color;
  final double thickness;

  _CornerPainter({
    required this.isLeft,
    required this.isTop,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = isLeft ? 0.0 : size.width;
    final y = isTop ? 0.0 : size.height;
    final dx = isLeft ? size.width : -size.width;
    final dy = isTop ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
