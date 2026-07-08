import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../l10n/tr_extension.dart';
import '../../../services/bakong_payment_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/receipt_service.dart';
import '../../../services/resend_email_service.dart';
import '../../../supabase_config.dart';
import 'bakong_payment_screen.dart';
import 'passenger_main_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;
  final DateTime date;
  final List<String> seatNumbers;

  const BookingConfirmationScreen({
    super.key,
    required this.schedule,
    required this.date,
    required this.seatNumbers,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Passenger info controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _hasStoredInfo = false;
  bool _useStoredInfo = true;
  String _savedName = '';
  String _savedAge = '';
  String _savedPhone = '';
  String _savedNationality = '';
  String _savedEmail = '';

  String get _savedInfoPreview {
    if (_savedName.isEmpty) return '';
    final parts = <String>[_savedName];
    if (_savedPhone.isNotEmpty) parts.add(_savedPhone);
    return parts.join(' • ');
  }

  // Promo code state
  final TextEditingController _promoCodeController = TextEditingController();
  String? _appliedPromoCode;
  String? _appliedPromotionId;
  double _discountAmount = 0;
  String _discountLabel = '';
  bool _isPromoApplied = false;
  bool _isValidatingPromo = false;
  String? _promoError;

  // Always Bakong QR (cash on board removed)

  double get _pricePerSeat => (widget.schedule['price'] as num).toDouble();
  double get _totalPrice => _pricePerSeat * widget.seatNumbers.length;
  double get _finalPrice => _totalPrice - _discountAmount;
  double get _discountPerSeat =>
      widget.seatNumbers.isEmpty ? 0 : _discountAmount / widget.seatNumbers.length;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    _emailController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final data = await SupabaseConfig.client
          .from('users')
          .select('name, phone, email, age, nationality')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (data != null) {
        _savedName = data['name'] as String? ?? '';
        _savedPhone = data['phone'] as String? ?? '';
        _savedEmail = data['email'] as String? ?? user.email ?? '';
        _savedAge = data['age']?.toString() ?? '';
        _savedNationality = data['nationality'] as String? ?? '';
      } else {
        _savedEmail = user.email ?? '';
      }

      _fillControllersFromSaved();
      final hasInfo = _savedName.isNotEmpty;
      setState(() {
        _hasStoredInfo = hasInfo;
        _useStoredInfo = hasInfo;
      });
    } catch (e) {
      debugPrint('[BookingConfirm] Failed to load user info: $e');
    }
  }

  void _fillControllersFromSaved() {
    _nameController.text = _savedName;
    _phoneController.text = _savedPhone;
    _emailController.text = _savedEmail;
    _ageController.text = _savedAge;
    _nationalityController.text = _savedNationality;
  }

  void _clearControllers() {
    _nameController.clear();
    _phoneController.clear();
    _ageController.clear();
    _nationalityController.clear();
    _emailController.clear();
  }

  Future<void> _validatePromoCode() async {
    HapticFeedback.lightImpact();
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _promoError = context.tr.bookingPromoCodeRequired);
      return;
    }

    setState(() {
      _isValidatingPromo = true;
      _promoError = null;
    });

    try {
      final promo = await SupabaseConfig.client
          .from('promotions')
          .select()
          .ilike('code', code)
          .maybeSingle();

      if (promo == null) {
        setState(() {
          _isValidatingPromo = false;
          _promoError = context.tr.bookingPromoInvalid;
        });
        return;
      }

      final isActive = promo['is_active'] as bool? ?? true;
      if (!isActive) {
        setState(() {
          _isValidatingPromo = false;
          _promoError = context.tr.bookingPromoInactive;
        });
        return;
      }

      final expiresAt = promo['expires_at'] as String?;
      if (expiresAt != null && DateTime.now().isAfter(DateTime.parse(expiresAt))) {
        setState(() {
          _isValidatingPromo = false;
          _promoError = context.tr.bookingPromoExpired;
        });
        return;
      }

      final minPurchase = (promo['min_purchase'] as num?)?.toDouble();
      if (minPurchase != null && _totalPrice < minPurchase) {
        setState(() {
          _isValidatingPromo = false;
          _promoError = context.tr.bookingMinPurchase('\$${minPurchase.toStringAsFixed(2)}');
        });
        return;
      }

      final maxUsage = promo['max_usage'] as int?;
      final usedCount = promo['used_count'] as int? ?? 0;
      if (maxUsage != null && usedCount >= maxUsage) {
        setState(() {
          _isValidatingPromo = false;
          _promoError = context.tr.bookingPromoMaxUsage;
        });
        return;
      }

      // Per-account usage limit
      final maxPerUser = promo['max_per_user'] as int?;
      if (maxPerUser != null) {
        final userId = SupabaseConfig.client.auth.currentUser?.id;
        if (userId != null) {
          final promoId = promo['id'] as String;
          final userUsage = await SupabaseConfig.client
              .from('promotion_usages')
              .select('id')
              .eq('promotion_id', promoId)
              .eq('user_id', userId);
          final userCount = (userUsage as List).length;
          if (userCount >= maxPerUser) {
            setState(() {
              _isValidatingPromo = false;
              _promoError = context.tr.bookingPromoPerUser(userCount, maxPerUser);
            });
            return;
          }
        }
      }

      final discountType = promo['discount_type'] as String;
      final discountValue = (promo['discount_value'] as num).toDouble();
      double discountAmount;
      String discountLabel;

      if (discountType == 'percentage') {
        discountAmount = _totalPrice * (discountValue / 100);
        discountLabel = context.tr.bookingPromoPercentage(discountValue.toStringAsFixed(0));
      } else {
        discountAmount = discountValue.clamp(0, _totalPrice);
        discountLabel = context.tr.bookingPromoFixed(discountValue.toStringAsFixed(2));
      }

      setState(() {
        _isPromoApplied = true;
        _appliedPromoCode = promo['code'] as String;
        _appliedPromotionId = promo['id'] as String;
        _discountAmount = discountAmount;
        _discountLabel = discountLabel;
        _promoError = null;
      });
    } catch (_) {
      setState(() => _promoError = context.tr.bookingPromoFailed);
    } finally {
      if (mounted) setState(() => _isValidatingPromo = false);
    }
  }

  void _removePromoCode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPromoApplied = false;
      _appliedPromoCode = null;
      _appliedPromotionId = null;
      _discountAmount = 0;
      _discountLabel = '';
      _promoError = null;
      _promoCodeController.clear();
    });
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Validate phone number with phone_numbers_parser (pure Dart, works on web)
      try {
        final phone = PhoneNumber.parse(_phoneController.text.trim());
        if (!phone.isValid()) {
          throw Exception(context.tr.bookingInvalidPhoneFormat);
        }
      } catch (_) {
        throw Exception(context.tr.bookingInvalidPhoneMessage);
      }

      // Validate email
      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
        if (!emailRegex.hasMatch(email)) {
          throw Exception(context.tr.bookingInvalidEmail);
        }
      }

      // Save passenger info to user profile (insert or update)
      final profileData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': email,
        'age': int.tryParse(_ageController.text.trim()),
        'nationality': _nationalityController.text.trim(),
      };
      try {
        await SupabaseConfig.client.from('users').insert({
          'id': user.id,
          ...profileData,
        });
        debugPrint('[BookingConfirm] User profile created');
      } catch (_) {
        // Record already exists — update instead
        await SupabaseConfig.client.from('users')
            .update(profileData)
            .eq('id', user.id);
        debugPrint('[BookingConfirm] User profile updated');
      }

      final scheduleId = widget.schedule['id'] as String;
      final tripDate = widget.date.toIso8601String().split('T')[0];

      // Step 1: Get or create trip
      String tripId;
      final existingTrip = await SupabaseConfig.client
          .from('trips')
          .select('id, status')
          .eq('schedule_id', scheduleId)
          .eq('trip_date', tripDate)
          .maybeSingle();

      if (existingTrip != null) {
        tripId = existingTrip['id'] as String;

        // Safety check: ensure the existing trip has not already started, ended, or been cancelled
        final tripStatus = existingTrip['status'] as String?;
        if (tripStatus == 'in_progress' || tripStatus == 'completed' || tripStatus == 'cancelled') {
          final reason = tripStatus == 'in_progress'
              ? context.tr.bookingTripDeparted
              : tripStatus == 'completed'
                  ? context.tr.bookingTripEnded
                  : context.tr.bookingTripCancelled;
          throw Exception(context.tr.bookingTripNotBookable(reason));
        }
      } else {
        // FIX 1: was .single() — crashes if RLS blocks the insert or
        // the DB returns 0 rows. Use .maybeSingle() and check for null.
        final newTrip = await SupabaseConfig.client
            .from('trips')
            .insert({
              'schedule_id': scheduleId,
              'trip_date': tripDate,
              'bus_id': widget.schedule['buses']?['id'],
              'driver_id': widget.schedule['driver_id'],
              'conductor_id': widget.schedule['conductor_id'],
              'status': 'scheduled',
            })
            .select('id')
            .maybeSingle();

        if (newTrip == null) {
          throw Exception(context.tr.bookingFailedCreateTrip);
        }
        tripId = newTrip['id'] as String;
      }

      // Step 2: Bakong QR payment (cash on board removed)
      await _startBakongBooking(tripId: tripId, user: user);
    } on PostgrestException catch (e) {
      _showError(context.tr.bookingFailedGeneric(e.message));
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startBakongBooking({
    required String tripId,
    required User user,
  }) async {
    final nowStr = DateTime.now().toIso8601String();
    final List<String> bookingIds = [];

    // 1. Create bookings as 'pending' (no payments, no tickets yet)
    for (final seat in widget.seatNumbers) {
      final booking = await SupabaseConfig.client
          .from('bookings')
          .insert({
            'trip_id': tripId,
            'passenger_id': user.id,
            'seat_number': seat,
            'status': 'pending',
            'total_price': _pricePerSeat,
            'booked_at': nowStr,
            'booking_channel': 'online',
            'passenger_name': _nameController.text.trim(),
            'passenger_age': int.tryParse(_ageController.text.trim()),
            'passenger_phone': _phoneController.text.trim(),
            'passenger_nationality': _nationalityController.text.trim(),
          })
          .select('id')
          .maybeSingle();

      if (booking == null) {
        throw Exception(context.tr.bookingFailedCreateBooking(seat));
      }
      bookingIds.add(booking['id'] as String);
    }

    // 2. Generate KHQR
    final khqr = BakongPaymentService.generateKhqr(
      amount: _finalPrice,
      billNumber: bookingIds.first,
    );

    if (!khqr.isSuccess) {
      await _cancelPendingBookings(bookingIds);
      throw Exception(khqr.error ?? 'Failed to generate payment QR');
    }

    if (!mounted) {
      await _cancelPendingBookings(bookingIds);
      return;
    }

    setState(() => _isLoading = false);

    // 3. Navigate to Bakong payment screen
    final paymentResult = await Navigator.push<BakongPaymentResult>(
      context,
      MaterialPageRoute(
        builder: (_) => BakongPaymentScreen(
          khqrString: khqr.qr!,
          md5Hash: khqr.md5Hash!,
          amount: _finalPrice,
          expiryTimestamp: khqr.expiryTimestamp!,
        ),
      ),
    );

    if (!mounted) {
      await _cancelPendingBookings(bookingIds);
      return;
    }

    setState(() => _isLoading = true);

    if (paymentResult != null && paymentResult.isSuccess) {
      // 4a. Payment successful — finalize bookings
      await _finalizeBakongBookings(
        bookingIds: bookingIds,
        tripId: tripId,
        userId: user.id,
        transactionId: paymentResult.transactionId,
      );

      await _trackPromoUsage(user.id);
      _sendBookingNotification(user.id, bookingIds.first);

      final receiptBookings = await _buildReceiptData(
        bookingIds: bookingIds,
        tripId: tripId,
      );
      await _sendReceiptIfNeeded(receiptBookings);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PassengerMainScreen(
            initialIndex: 1,
            newBookingId: bookingIds.first,
            newSeatCount: widget.seatNumbers.length,
          ),
        ),
        (route) => route.isFirst,
      );
    } else {
      // 4b. Payment failed — cancel pending bookings
      await _cancelPendingBookings(bookingIds);
      _showError('Payment cancelled or timed out. Please try again.');
    }
  }

  Future<void> _cancelPendingBookings(List<String> bookingIds) async {
    for (final id in bookingIds) {
      await SupabaseConfig.client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', id);
    }
  }

  Future<void> _finalizeBakongBookings({
    required List<String> bookingIds,
    required String tripId,
    required String userId,
    String? transactionId,
  }) async {
    final nowStr = DateTime.now().toIso8601String();

    for (final bookingId in bookingIds) {
      // Update booking status to confirmed
      await SupabaseConfig.client
          .from('bookings')
          .update({'status': 'confirmed'})
          .eq('id', bookingId);

      // Create payment record
      await SupabaseConfig.client.from('payments').insert({
        'booking_id': bookingId,
        'amount': _pricePerSeat - _discountPerSeat,
        'method': 'bakong',
        'status': 'paid',
        'transaction_id': transactionId,
        'paid_at': nowStr,
      });

      // Create ticket
      final qrCode =
          'BUS-$bookingId-${DateTime.now().millisecondsSinceEpoch}';
      await SupabaseConfig.client.from('tickets').insert({
        'booking_id': bookingId,
        'qr_code': qrCode,
        'status': 'valid',
      });
    }

    try {
      await SupabaseConfig.client
          .from('seat_holds')
          .delete()
          .eq('trip_id', tripId)
          .eq('passenger_id', userId)
          .inFilter('seat_number', widget.seatNumbers);
    } catch (e) {
      debugPrint('[BookingConfirm] Failed to delete holds: $e');
    }
  }

  Future<void> _trackPromoUsage(String userId) async {
    if (!_isPromoApplied || _appliedPromotionId == null) return;

    final promo = await SupabaseConfig.client
        .from('promotions')
        .select('used_count')
        .eq('id', _appliedPromotionId!)
        .maybeSingle();

    if (promo != null) {
      final current = promo['used_count'] as int? ?? 0;
      await SupabaseConfig.client
          .from('promotions')
          .update({'used_count': current + 1})
          .eq('id', _appliedPromotionId!);
      await SupabaseConfig.client.from('promotion_usages').insert({
        'promotion_id': _appliedPromotionId,
        'user_id': userId,
      });
    }
  }

  void _sendBookingNotification(String userId, String bookingId) {
    final route = widget.schedule['routes'] as Map<String, dynamic>?;
    unawaited(
      NotificationService.instance.insertNotification(
        userId: userId,
        title: context.tr.bookingNotificationTitle,
        body: context.tr.bookingNotificationBody(
          widget.seatNumbers.length,
          route?['origin'] ?? 'N/A',
          route?['destination'] ?? 'N/A',
          _formatTime(widget.schedule['departure_time'] as String),
        ),
        type: 'booking',
        referenceType: 'booking',
        referenceId: bookingId,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _buildReceiptData({
    required List<String> bookingIds,
    required String tripId,
  }) async {
    final List<Map<String, dynamic>> receiptBookings = [];
    for (int i = 0; i < bookingIds.length; i++) {
      receiptBookings.add({
        'id': bookingIds[i],
        'seat_number': widget.seatNumbers[i],
        'status': 'confirmed',
        'total_price': _pricePerSeat,
        'booked_at': DateTime.now().toIso8601String(),
        'trips': {
          'id': tripId,
          'trip_date': widget.date.toIso8601String().split('T')[0],
          'status': 'scheduled',
          'schedules': widget.schedule,
        },
      });
    }
    return receiptBookings;
  }

  Future<void> _sendReceiptIfNeeded(
    List<Map<String, dynamic>> receiptBookings,
  ) async {
    if (receiptBookings.isEmpty) return;
    final receiptEmail = _emailController.text.trim();
    if (receiptEmail.isEmpty) return;

    await _sendReceiptEmail(
      to: receiptEmail,
      bookings: receiptBookings,
      passengerName: _nameController.text.trim(),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {},
    );
  }

  void _onUseSavedInfoChanged(bool useSaved) {
    setState(() {
      _useStoredInfo = useSaved;
      if (_useStoredInfo) {
        _fillControllersFromSaved();
      } else {
        _clearControllers();
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _sendReceiptEmail({
    required String to,
    required List<Map<String, dynamic>> bookings,
    required String passengerName,
  }) async {
    final route = widget.schedule['routes'] as Map<String, dynamic>?;
    final origin = route?['origin'] as String? ?? '?';
    final destination = route?['destination'] as String? ?? '?';
    final bookingRef =
        '#${(bookings.first['id'] as String).substring(0, 8).toUpperCase()}';
    final tripDate = DateHelpers.formatFullDate(
      widget.date.toIso8601String().split('T')[0],
    );
    final departureTime =
        _formatTime(widget.schedule['departure_time'] as String);

    final pdfResult = await ReceiptService.generate(bookings: bookings);

    switch (pdfResult) {
      case Success<Uint8List>(:final data):
        final emailResult = await ResendEmailService.sendReceipt(
          to: to,
          pdfBytes: data,
          bookingRef: bookingRef,
          origin: origin,
          destination: destination,
          tripDate: tripDate,
          departureTime: departureTime,
          seatCount: bookings.length,
          totalPrice:
              bookings.fold<double>(0, (s, b) => s + (b['total_price'] as num).toDouble()),
          passengerName: passengerName,
        );
        if (emailResult is Success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.bookingReceiptSent),
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (emailResult is Failure) {
          debugPrint('[Email] Failed to send receipt: ${emailResult.message}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(emailResult.message),
                backgroundColor: Colors.orange.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      case Failure<Uint8List>(:final message):
        debugPrint('[Email] Failed to generate receipt PDF: $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.schedule['routes'] as Map<String, dynamic>;
    final bus = widget.schedule['buses'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.primaryBlue),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          context.tr.bookingConfirmTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Trip Details
            _SectionCard(
              title: context.tr.bookingTripDetails,
              icon: Icons.directions_bus_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTime(widget.schedule['departure_time']),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            route['origin'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${route['duration_min']} min',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 1.5,
                                  color: AppColors.border,
                                ),
                                const Icon(
                                  Icons.directions_bus_rounded,
                                  size: 16,
                                  color: AppColors.primaryBlue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(widget.schedule['arrival_time']),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            route['destination'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: context.tr.bookingDate,
                    value: _formatDate(widget.date),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.event_seat_rounded,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.tr.bookingSeats,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          children: widget.seatNumbers.map((seat) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlueLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryBlueBorder,
                                ),
                              ),
                              child: Text(
                                seat,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  if (bus != null) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.directions_bus_outlined,
                      label: context.tr.bookingBus,
                      value: '${bus['model']} • ${bus['plate_number']}',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Passenger Info
            _SectionCard(
              title: context.tr.bookingPassenger,
              icon: Icons.person_outline_rounded,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_hasStoredInfo)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _useStoredInfo,
                                onChanged: (v) => _onUseSavedInfoChanged(v ?? true),
                                activeColor: AppColors.primaryBlue,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _onUseSavedInfoChanged(!_useStoredInfo),
                              child: RichText(
                                text: TextSpan(
                                  text: context.tr.bookingUseSavedInfo,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                  children: [
                                    if (_savedInfoPreview.isNotEmpty)
                                      TextSpan(
                                        text: ' ($_savedInfoPreview)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        label: context.tr.fullNameLabel,
                        icon: Icons.person_rounded,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? context.tr.bookingEnterFullName : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _ageController,
                      decoration: _inputDecoration(
                        label: context.tr.bookingAgeLabel,
                        icon: Icons.numbers_rounded,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return context.tr.bookingEnterAge;
                        final age = int.tryParse(v);
                        if (age == null || age < 1 || age > 120) return context.tr.bookingEnterValidAge;
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration(
                        label: context.tr.bookingPhoneLabel,
                        icon: Icons.phone_outlined,
                        helperText: context.tr.bookingPhoneHelper,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return context.tr.bookingEnterPhone;
                        final phone = v.trim();
                        if (!phone.startsWith('+')) return context.tr.bookingIncludeCountryCode;
                        final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
                        if (digitsOnly.length < 8 || digitsOnly.length > 15) {
                          return context.tr.bookingEnterValidPhone;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nationalityController,
                      decoration: _inputDecoration(
                        label: context.tr.bookingNationalityLabel,
                        icon: Icons.flag_rounded,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? context.tr.bookingEnterNationality : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration(
                        label: context.tr.bookingEmailHolder,
                        icon: Icons.email_outlined,
                        helperText: context.tr.bookingEmailHelper,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(v.trim())) {
                          return context.tr.bookingEnterValidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Text(
                          context.tr.bookingDetailsSaved,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment
            _SectionCard(
              title: context.tr.bookingPayment,
              icon: Icons.qr_code_rounded,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.successGreenBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_rounded, color: AppColors.successGreen, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bakong KHQR',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.successGreen,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Pay now via Bakong-enabled banking app',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Promo Code
                  if (_isPromoApplied)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.successGreenBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.successGreenLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.discount_rounded,
                              color: AppColors.successGreen,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _discountLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.successGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _appliedPromoCode!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _removePromoCode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.successGreenLight,
                                ),
                              ),
                              child: Text(
                                context.tr.bookingPromoRemove,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _promoCodeController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: context.tr.bookingPromoCodeHint,
                                    hintStyle: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 14,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.background,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _isValidatingPromo
                                      ? null
                                      : _validatePromoCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        AppColors.primaryBlue.withValues(alpha: 0.6),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                  ),
                                  child: _isValidatingPromo
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          context.tr.bookingPromoApply,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          if (_promoError != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8, left: 2),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 14,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _promoError!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  _InfoRow(
                    icon: Icons.confirmation_number_outlined,
                    label: context.tr.bookingPricePerSeat,
                    value: '\$${_pricePerSeat.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.event_seat_rounded,
                    label: context.tr.bookingNumberOfSeats,
                    value: '${widget.seatNumbers.length}',
                  ),
                  if (_isPromoApplied) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.discount_rounded,
                      label: context.tr.bookingDiscount,
                      value: '-\$${_discountAmount.toStringAsFixed(2)}',
                      valueColor: AppColors.successGreen,
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppColors.border),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr.bookingTotal,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_isPromoApplied)
                            Text(
                              '\$${_totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textHint,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '\$${_finalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: _isPromoApplied ? 20 : 20,
                              fontWeight: FontWeight.w700,
                              color: _isPromoApplied
                                  ? AppColors.successGreen
                                  : AppColors.primaryBlue,
                            ),
                          ),
                          if (widget.seatNumbers.length > 1)
                            Text(
                              '\$${_pricePerSeat.toStringAsFixed(2)} × ${widget.seatNumbers.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr.bookingNotice,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.warningText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.seatNumbers.length > 1
                        ? context.tr.bookingConfirmCountSeats(widget.seatNumbers.length)
                        : context.tr.bookingConfirmButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      helperText: helperText,
      helperStyle: const TextStyle(fontSize: 11, color: AppColors.textHint),
      prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryBlue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
