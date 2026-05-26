import '../../../../supabase_config.dart';

enum CancelResult {
  success,
  tooLate, // less than 2 hours before departure
  alreadyBoarded, // passenger already scanned
  alreadyCancelled,
  tripStarted,
  error,
}

class CancellationService {
  // ── Cancel a booking ────────────────────────────────────────────────────────
  static Future<CancelResult> cancelBooking(String bookingId) async {
    try {
      // Step 1: Fetch booking + trip + schedule details
      final booking = await SupabaseConfig.client
          .from('bookings')
          .select('''
            id, status,
            trips (
              id, status, trip_date,
              schedules ( departure_time )
            ),
            tickets ( id, status )
          ''')
          .eq('id', bookingId)
          .single();

      final bookingStatus = booking['status'] as String;
      final trip = booking['trips'] as Map<String, dynamic>?;
      final schedule = trip?['schedules'] as Map<String, dynamic>?;
      final tickets = booking['tickets'] as List?;

      // Step 2: Guard checks
      if (bookingStatus == 'cancelled') return CancelResult.alreadyCancelled;
      if (bookingStatus == 'boarded') return CancelResult.alreadyBoarded;

      final tripStatus = trip?['status'] as String? ?? '';
      if (tripStatus == 'in_progress' || tripStatus == 'completed') {
        return CancelResult.tripStarted;
      }

      // Step 3: Check 2-hour cutoff
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
        if (diff.inMinutes < 120) return CancelResult.tooLate;
      }

      // Step 4: Cancel booking
      await SupabaseConfig.client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);

      // Step 5: Cancel ticket
      if (tickets != null && tickets.isNotEmpty) {
        await SupabaseConfig.client
            .from('tickets')
            .update({'status': 'cancelled'})
            .eq('booking_id', bookingId);
      }

      // Step 6: Mark payment as refunded (if paid)
      await SupabaseConfig.client
          .from('payments')
          .update({'status': 'refunded'})
          .eq('booking_id', bookingId)
          .eq('status', 'paid');

      return CancelResult.success;
    } catch (e) {
      return CancelResult.error;
    }
  }

  // ── Human-readable result message ───────────────────────────────────────────
  static String messageFor(CancelResult result) {
    switch (result) {
      case CancelResult.success:
        return 'Booking cancelled successfully.';
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
