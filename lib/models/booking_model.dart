import 'trip_model.dart';
import 'user_model.dart';
import 'ticket_model.dart';

class BookingModel {
  final String id;
  final String? tripId;
  final String? passengerId;
  final String? seatNumber;
  final String status;
  final double? totalPrice;
  final DateTime? bookedAt;
  final String? bookingChannel;
  final String? passengerName;
  final int? passengerAge;
  final String? passengerPhone;
  final String? passengerNationality;
  final TripModel? trip;
  final UserModel? passenger;
  final List<TicketModel>? tickets;

  const BookingModel({
    required this.id,
    this.tripId,
    this.passengerId,
    this.seatNumber,
    required this.status,
    this.totalPrice,
    this.bookedAt,
    this.bookingChannel,
    this.passengerName,
    this.passengerAge,
    this.passengerPhone,
    this.passengerNationality,
    this.trip,
    this.passenger,
    this.tickets,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    List<TicketModel>? ticketList;
    if (map['tickets'] != null) {
      ticketList = (map['tickets'] as List)
          .map((e) => TicketModel.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return BookingModel(
      id: map['id'] as String,
      tripId: map['trip_id'] as String?,
      passengerId: map['passenger_id'] as String?,
      seatNumber: map['seat_number'] as String?,
      status: map['status'] as String,
      totalPrice: (map['total_price'] as num?)?.toDouble(),
      bookedAt: map['booked_at'] != null
          ? DateTime.parse(map['booked_at'] as String).toLocal()
          : null,
      bookingChannel: map['booking_channel'] as String?,
      passengerName: map['passenger_name'] as String?,
      passengerAge: map['passenger_age'] as int?,
      passengerPhone: map['passenger_phone'] as String?,
      passengerNationality: map['passenger_nationality'] as String?,
      trip: map['trips'] != null
          ? TripModel.fromMap(map['trips'] as Map<String, dynamic>)
          : null,
      passenger: map['users'] != null
          ? UserModel.fromMap(map['users'] as Map<String, dynamic>)
          : null,
      tickets: ticketList,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    if (tripId != null) 'trip_id': tripId,
    if (passengerId != null) 'passenger_id': passengerId,
    if (seatNumber != null) 'seat_number': seatNumber,
    'status': status,
    if (totalPrice != null) 'total_price': totalPrice,
    if (bookedAt != null) 'booked_at': bookedAt!.toIso8601String(),
    if (bookingChannel != null) 'booking_channel': bookingChannel,
    if (passengerName != null) 'passenger_name': passengerName,
    if (passengerAge != null) 'passenger_age': passengerAge,
    if (passengerPhone != null) 'passenger_phone': passengerPhone,
    if (passengerNationality != null) 'passenger_nationality': passengerNationality,
  };

  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isBoarded => status == 'boarded';
  bool get isPending => status == 'pending';

  bool get canCancel => isConfirmed || isPending;
}
