import '../core/error/result.dart';
import '../models/booking_model.dart';
import 'base_repository.dart';

class BookingRepository extends BaseRepository {
  BookingRepository() : super('bookings');

  static const _passengerSelect = '''
    id, seat_number, status, total_price, booked_at,
    trips (
      id, trip_date, status,
      schedules ( departure_time, arrival_time,
        routes ( id, name, origin, destination ),
        buses ( id, plate_number, model )
      )
    ),
    tickets ( id, qr_code, status, scanned_at )
  ''';

  Future<Result<List<BookingModel>>> getPassengerBookings(String passengerId) async {
    try {
      final data = await client
          .from('bookings')
          .select(_passengerSelect)
          .eq('passenger_id', passengerId)
          .order('booked_at', ascending: false);
      return Success(data.map((e) => BookingModel.fromMap(e)).toList());
    } catch (e) {
      return Failure('Failed to load bookings', error: e);
    }
  }

  Future<Result<List<BookingModel>>> getTripBookings(String tripId) async {
    try {
      final data = await client
          .from('bookings')
          .select('''
            id, seat_number, status,
            users!bookings_passenger_id_fkey ( id, name, phone ),
            tickets ( id, qr_code, status, scanned_at )
          ''')
          .eq('trip_id', tripId)
          .order('seat_number', ascending: true);
      return Success(data.map((e) => BookingModel.fromMap(e)).toList());
    } catch (e) {
      return Failure('Failed to load trip bookings', error: e);
    }
  }

  Future<Result<List<String>>> getBookedSeats(String tripId) async {
    try {
      final data = await client
          .from('bookings')
          .select('seat_number')
          .eq('trip_id', tripId)
          .inFilter('status', ['confirmed', 'boarded', 'pending']);
      final seats = data.map((e) => e['seat_number'] as String).toList();
      return Success(seats);
    } catch (e) {
      return Failure('Failed to load booked seats', error: e);
    }
  }

  Future<Result<BookingModel>> createBooking({
    required String tripId,
    required String passengerId,
    required String seatNumber,
    required double totalPrice,
    String? passengerName,
    int? passengerAge,
    String? passengerPhone,
    String? passengerNationality,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = await client
          .from('bookings')
          .insert({
            'trip_id': tripId,
            'passenger_id': passengerId,
            'seat_number': seatNumber,
            'status': 'confirmed',
            'total_price': totalPrice,
            'booked_at': now,
            'booking_channel': 'online',
            if (passengerName != null) 'passenger_name': passengerName,
            if (passengerAge != null) 'passenger_age': passengerAge,
            if (passengerPhone != null) 'passenger_phone': passengerPhone,
            if (passengerNationality != null)
              'passenger_nationality': passengerNationality,
          })
          .select()
          .single();
      return Success(BookingModel.fromMap(data));
    } catch (e) {
      return Failure('Failed to create booking', error: e);
    }
  }

  Future<Result<void>> cancelBooking(String bookingId) async {
    try {
      await client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
      await client
          .from('tickets')
          .update({'status': 'cancelled'})
          .eq('booking_id', bookingId);
      await client
          .from('payments')
          .update({'status': 'refunded'})
          .eq('booking_id', bookingId)
          .eq('status', 'paid');
      return const Success(null);
    } catch (e) {
      return Failure('Failed to cancel booking', error: e);
    }
  }

  Future<Result<BookingModel?>> validateBookingCanCancel(String bookingId) async {
    try {
      final booking = await client
          .from('bookings')
          .select('''
            id, status,
            trips ( id, status, trip_date,
              schedules ( departure_time )
            ),
            tickets ( id, status )
          ''')
          .eq('id', bookingId)
          .single();

      final bookingStatus = booking['status'] as String;
      if (bookingStatus == 'cancelled') return const Success(null);
      if (bookingStatus == 'boarded') return const Success(null);

      final trip = booking['trips'] as Map<String, dynamic>?;
      if (trip == null) return const Success(null);

      final tripStatus = trip['status'] as String? ?? '';
      if (tripStatus == 'in_progress' || tripStatus == 'completed') {
        return const Success(null);
      }

      final schedule = trip['schedules'] as Map<String, dynamic>?;
      if (schedule != null) {
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
        if (departure.difference(DateTime.now()).inMinutes < 120) {
          return const Success(null);
        }
      }

      return Success(BookingModel.fromMap(booking));
    } catch (e) {
      return Failure('Failed to validate cancellation', error: e);
    }
  }
}
