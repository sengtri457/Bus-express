import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../services/notification_service.dart';
import '../../../services/receipt_service.dart';
import '../../../services/resend_email_service.dart';
import '../../../supabase_config.dart';
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

  bool _hasSavedInfo = false;
  bool _useSavedInfo = true;
  String _savedName = '';
  String _savedAge = '';
  String _savedPhone = '';
  String _savedNationality = '';
  String _savedEmail = '';

  // Promo code state
  final TextEditingController _promoCodeController = TextEditingController();
  String? _appliedPromoCode;
  String? _appliedPromotionId;
  double _discountAmount = 0;
  String _discountLabel = '';
  bool _isPromoApplied = false;
  bool _isValidatingPromo = false;
  String? _promoError;

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
      if (mounted && data != null) {
        _savedName = data['name'] ?? '';
        _savedPhone = data['phone'] ?? '';
        _savedEmail = data['email'] ?? user.email ?? '';
        _savedAge = data['age']?.toString() ?? '';
        _savedNationality = data['nationality'] ?? '';
        _nameController.text = _savedName;
        _phoneController.text = _savedPhone;
        _emailController.text = _savedEmail;
        _ageController.text = _savedAge;
        _nationalityController.text = _savedNationality;
        final hasInfo = _savedName.isNotEmpty;
        setState(() {
          _hasSavedInfo = hasInfo;
          _useSavedInfo = hasInfo;
        });
      } else if (mounted) {
        _savedEmail = user.email ?? '';
        _emailController.text = _savedEmail;
      }
    } catch (e) {
      debugPrint('[BookingConfirm] Failed to load user info: $e');
    }
  }

  Future<void> _validatePromoCode() async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _promoError = 'Please enter a promo code');
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
          _promoError = 'Invalid promo code';
        });
        return;
      }

      final isActive = promo['is_active'] as bool? ?? true;
      if (!isActive) {
        setState(() {
          _isValidatingPromo = false;
          _promoError = 'This promo code is no longer active';
        });
        return;
      }

      final expiresAt = promo['expires_at'] as String?;
      if (expiresAt != null && DateTime.now().isAfter(DateTime.parse(expiresAt))) {
        setState(() {
          _isValidatingPromo = false;
          _promoError = 'This promo code has expired';
        });
        return;
      }

      final minPurchase = (promo['min_purchase'] as num?)?.toDouble();
      if (minPurchase != null && _totalPrice < minPurchase) {
        setState(() {
          _isValidatingPromo = false;
          _promoError =
              'Minimum purchase of \$${minPurchase.toStringAsFixed(2)} required';
        });
        return;
      }

      final maxUsage = promo['max_usage'] as int?;
      final usedCount = promo['used_count'] as int? ?? 0;
      if (maxUsage != null && usedCount >= maxUsage) {
        setState(() {
          _isValidatingPromo = false;
          _promoError = 'This promo code has reached its usage limit';
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
              _promoError =
                  'You have used this promo code $userCount out of $maxPerUser times';
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
        discountLabel = '${discountValue.toStringAsFixed(0)}% OFF';
      } else {
        discountAmount = discountValue.clamp(0, _totalPrice);
        discountLabel = '\$${discountValue.toStringAsFixed(2)} OFF';
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
      setState(() => _promoError = 'Failed to validate promo code');
    } finally {
      if (mounted) setState(() => _isValidatingPromo = false);
    }
  }

  void _removePromoCode() {
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

    setState(() => _isLoading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Validate phone number with phone_numbers_parser (pure Dart, works on web)
      try {
        final phone = PhoneNumber.parse(_phoneController.text.trim());
        if (!phone.isValid()) {
          throw Exception('Invalid phone number format.');
        }
      } catch (_) {
        throw Exception('Invalid phone number. Enter a real number with correct country code (e.g. +1234567890).');
      }

      // Validate email
      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
        if (!emailRegex.hasMatch(email)) {
          throw Exception('Enter a valid email address.');
        }
      }

      // Save passenger info to user profile
      await SupabaseConfig.client
          .from('users')
          .update({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': email,
            'age': int.tryParse(_ageController.text.trim()),
            'nationality': _nationalityController.text.trim(),
          })
          .eq('id', user.id);

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
              ? 'already departed'
              : tripStatus == 'completed'
                  ? 'already ended'
                  : 'been cancelled';
          throw Exception('This trip has $reason and cannot be booked.');
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
          throw Exception(
            'Failed to create trip. Check RLS policies on trips table.',
          );
        }
        tripId = newTrip['id'] as String;
      }

      // Step 2: Create one booking per seat
      String firstBookingId = '';
      final List<Map<String, dynamic>> receiptBookings = [];
      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      for (final seat in widget.seatNumbers) {
        // FIX 2: was .single() — same issue. If the booking insert is
        // blocked or returns nothing, this would crash.
        final booking = await SupabaseConfig.client
            .from('bookings')
            .insert({
              'trip_id': tripId,
              'passenger_id': user.id,
              'seat_number': seat,
              'status': 'confirmed',
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
          throw Exception(
            'Failed to create booking for seat $seat. Check RLS policies on bookings table.',
          );
        }

        final bookingId = booking['id'] as String;
        if (firstBookingId.isEmpty) firstBookingId = bookingId;

        // Step 3: Payment per seat (cash)
        await SupabaseConfig.client.from('payments').insert({
          'booking_id': bookingId,
          'amount': _pricePerSeat - _discountPerSeat,
          'method': 'cash',
          'status': 'pending',
        });

        // Step 4: Ticket with QR per seat
        final qrCode =
            'BUS-$bookingId-${DateTime.now().millisecondsSinceEpoch}';
        await SupabaseConfig.client.from('tickets').insert({
          'booking_id': bookingId,
          'qr_code': qrCode,
          'status': 'valid',
        });

        receiptBookings.add({
          'id': bookingId,
          'seat_number': seat,
          'status': 'confirmed',
          'total_price': _pricePerSeat,
          'booked_at': nowStr,
          'trips': {
            'id': tripId,
            'trip_date': widget.date.toIso8601String().split('T')[0],
            'status': 'scheduled',
            'schedules': widget.schedule,
          },
        });
      }

      // Step 5: Track promo usage
      if (_isPromoApplied && _appliedPromotionId != null) {
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
            'user_id': user.id,
          });
        }
      }

      final route = widget.schedule['routes'] as Map<String, dynamic>?;
      unawaited(
        NotificationService.instance.insertNotification(
          userId: user.id,
          title: 'Booking Confirmed',
          body:
              '${widget.seatNumbers.length} seat(s) on ${route?['origin'] ?? 'N/A'} → ${route?['destination'] ?? 'N/A'} '
              '(${_formatTime(widget.schedule['departure_time'] as String)})',
          type: 'booking',
          referenceType: 'booking',
          referenceId: firstBookingId,
        ),
      );

      final receiptEmail = _emailController.text.trim();
      if (receiptEmail.isNotEmpty && receiptBookings.isNotEmpty) {
        await _sendReceiptEmail(
          to: receiptEmail,
          bookings: receiptBookings,
          passengerName: _nameController.text.trim(),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {},
        );
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PassengerMainScreen(
            initialIndex: 1,
            newBookingId: firstBookingId,
            newSeatCount: widget.seatNumbers.length,
          ),
        ),
        (route) => route.isFirst,
      );
    } on PostgrestException catch (e) {
      _showError('Booking failed: ${e.message}');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onUseSavedInfoChanged(bool useSaved) {
    setState(() {
      _useSavedInfo = useSaved;
      if (_useSavedInfo) {
        _nameController.text = _savedName;
        _ageController.text = _savedAge;
        _phoneController.text = _savedPhone;
        _nationalityController.text = _savedNationality;
        _emailController.text = _savedEmail;
      } else {
        _nameController.clear();
        _ageController.clear();
        _phoneController.clear();
        _nationalityController.clear();
        _emailController.clear();
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
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
            const SnackBar(
              content: Text('Receipt sent to your email'),
              duration: Duration(seconds: 3),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.primaryBlue),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Confirm Booking',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Trip Details
            _SectionCard(
              title: 'Trip Details',
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
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            route['origin'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
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
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 1.5,
                                  color: const Color(0xFFE5E7EB),
                                ),
                                const Icon(
                                  Icons.directions_bus_rounded,
                                  size: 16,
                                  color: Color(0xFF2563EB),
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
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            route['destination'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _formatDate(widget.date),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.event_seat_rounded,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Seats',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
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
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Text(
                                seat,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
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
                      label: 'Bus',
                      value: '${bus['model']} • ${bus['plate_number']}',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Passenger Info
            _SectionCard(
              title: 'Passenger',
              icon: Icons.person_outline_rounded,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_hasSavedInfo)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _useSavedInfo,
                                  onChanged: (v) => _onUseSavedInfoChanged(v ?? true),
                                  activeColor: const Color(0xFF2563EB),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => _onUseSavedInfoChanged(!_useSavedInfo),
                                child: const Text(
                                'Use my saved information',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        label: 'Full Name',
                        icon: Icons.person_rounded,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter your full name' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _ageController,
                      decoration: _inputDecoration(
                        label: 'Age',
                        icon: Icons.numbers_rounded,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter your age';
                        final age = int.tryParse(v);
                        if (age == null || age < 1 || age > 120) return 'Enter a valid age';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration(
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        helperText: 'Include country code (e.g. +1XXXXXXXXX) for OTP',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter your phone number';
                        final phone = v.trim();
                        if (!phone.startsWith('+')) return 'Include country code (e.g. +1XXXXXXXXX)';
                        final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
                        if (digitsOnly.length < 8 || digitsOnly.length > 15) {
                          return 'Enter a valid phone number (8–15 digits)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nationalityController,
                      decoration: _inputDecoration(
                        label: 'Nationality',
                        icon: Icons.flag_rounded,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter your nationality' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration(
                        label: 'Email',
                        icon: Icons.email_outlined,
                        helperText: 'Receipt will be sent here',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment
            _SectionCard(
              title: 'Payment',
              icon: Icons.payment_rounded,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          color: Color(0xFF10B981),
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cash on Board',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF065F46),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Pay the conductor when boarding',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
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
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.discount_rounded,
                              color: Color(0xFF10B981),
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
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _appliedPromoCode!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF059669),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFD1FAE5),
                                ),
                              ),
                              child: const Text(
                                'Remove',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF4444),
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
                                    hintText: 'Promo code',
                                    hintStyle: TextStyle(
                                      color: const Color(0xFF9CA3AF),
                                      fontSize: 14,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2563EB),
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
                                        const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0xFF93C5FD),
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
                                      : const Text(
                                          'Apply',
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
                                    color: Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _promoError!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFEF4444),
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
                    label: 'Price per seat',
                    value: '\$${_pricePerSeat.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.event_seat_rounded,
                    label: 'Number of seats',
                    value: '${widget.seatNumbers.length}',
                  ),
                  if (_isPromoApplied) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.discount_rounded,
                      label: 'Discount',
                      value: '-\$${_discountAmount.toStringAsFixed(2)}',
                      valueColor: const Color(0xFF10B981),
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFFE5E7EB)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
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
                                color: Color(0xFF9CA3AF),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '\$${_finalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: _isPromoApplied ? 20 : 20,
                              fontWeight: FontWeight.w700,
                              color: _isPromoApplied
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                          if (widget.seatNumbers.length > 1)
                            Text(
                              '\$${_pricePerSeat.toStringAsFixed(2)} × ${widget.seatNumbers.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
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
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Arrive 15 minutes before departure. Show your QR ticket to the conductor when boarding.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF92400E),
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
          color: Colors.white,
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
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF93C5FD),
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
                    'Confirm ${widget.seatNumbers.length > 1 ? '${widget.seatNumbers.length} Seats' : 'Booking'}',
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
        color: Color(0xFF6B7280),
      ),
      helperText: helperText,
      helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
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
        color: Colors.white,
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
              Icon(icon, color: const Color(0xFF2563EB), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
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
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
