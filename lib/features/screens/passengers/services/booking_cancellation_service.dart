import 'package:flutter/foundation.dart';

import '../../../../services/wallet_service.dart';
import '../../../../supabase_config.dart';

enum CancelResult {
  success,
  successWithRefund,
  tooLate,
  alreadyBoarded,
  alreadyCancelled,
  tripStarted,
  error,
}

class CancellationService {
  static Future<({CancelResult result, double? refundAmount})> cancelBooking(
    String bookingId,
  ) async {
    try {
      final booking = await SupabaseConfig.client
          .from('bookings')
          .select('''
            id, status, passenger_id, total_price,
            trips (
              id, status, trip_date,
              schedules ( departure_time )
            ),
            tickets ( id, status ),
            payments ( id, amount, method, status )
          ''')
          .eq('id', bookingId)
          .single();

      final bookingStatus = booking['status'] as String;
      final trip = booking['trips'] as Map<String, dynamic>?;
      final schedule = trip?['schedules'] as Map<String, dynamic>?;
      final tickets = booking['tickets'] as List?;
      final payments = booking['payments'] as List?;

      if (bookingStatus == 'cancelled') {
        return (result: CancelResult.alreadyCancelled, refundAmount: null);
      }
      if (bookingStatus == 'boarded') {
        return (result: CancelResult.alreadyBoarded, refundAmount: null);
      }

      final tripStatus = trip?['status'] as String? ?? '';
      if (tripStatus == 'in_progress' || tripStatus == 'completed') {
        return (result: CancelResult.tripStarted, refundAmount: null);
      }

      if (trip != null && schedule != null) {
        final tripDate = trip['trip_date'] as String;
        final depTime = schedule['departure_time'] as String;
        final depParts = depTime.split(':');
        final departure = DateTime(
          int.parse(tripDate.split('-')[0]),
          int.parse(tripDate.split('-')[1]),
          int.parse(tripDate.split('-')[2]),
          int.parse(depParts[0]),
          int.parse(depParts[1]),
        );

        final now = DateTime.now();
        final diff = departure.difference(now);
        if (diff.inMinutes < 120) {
          return (result: CancelResult.tooLate, refundAmount: null);
        }
      }

      final passengerId = booking['passenger_id'] as String?;

      await SupabaseConfig.client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);

      if (tickets != null && tickets.isNotEmpty) {
        await SupabaseConfig.client
            .from('tickets')
            .update({'status': 'cancelled'})
            .eq('booking_id', bookingId);
      }

      // Refund: credit wallet for all paid payments (Bakong only, cash removed)
      double totalRefund = 0;
      if (payments != null && payments.isNotEmpty) {
        for (final payment in payments) {
          if (payment['status'] == 'paid' && passengerId != null) {
            await SupabaseConfig.client
                .from('payments')
                .update({'status': 'refunded'})
                .eq('id', payment['id'] as String);

            final refundAmount = (payment['amount'] as num?)?.toDouble() ?? 0;
            if (refundAmount > 0) {
              final ok = await WalletService.credit(
                userId: passengerId,
                amount: refundAmount,
                type: 'refund',
                referenceType: 'booking',
                referenceId: bookingId,
                description: 'Refund for cancelled booking',
              );
              if (ok) totalRefund += refundAmount;
            }
          }
        }
      }

      if (totalRefund > 0) {
        debugPrint('[CancellationService] Refunded \$$totalRefund'
            ' to wallet for booking $bookingId');
        return (result: CancelResult.successWithRefund, refundAmount: totalRefund);
      }

      return (result: CancelResult.success, refundAmount: null);
    } catch (e) {
      debugPrint('[CancellationService] Error: $e');
      return (result: CancelResult.error, refundAmount: null);
    }
  }

  static String messageFor(CancelResult result, {double? refundAmount}) {
    switch (result) {
      case CancelResult.success:
        return 'Booking cancelled successfully.';
      case CancelResult.successWithRefund:
        final amt = refundAmount?.toStringAsFixed(2) ?? '0.00';
        return 'Booking cancelled. \$$amt refunded to your wallet.';
      case CancelResult.tooLate:
        return 'Cannot cancel — departure is less than 2 hours away.';
      case CancelResult.alreadyBoarded:
        return 'Cannot cancel — you have already boarded this bus.';
      case CancelResult.alreadyCancelled:
        return 'This booking is already cancelled.';
      case CancelResult.tripStarted:
        return 'Cannot cancel — the trip has already started or completed.';
      case CancelResult.error:
        return 'Something went wrong. Please try again.';
    }
  }
}
