import 'package:flutter_test/flutter_test.dart';
import 'package:bus_express/models/models.dart';
import 'package:bus_express/models/booking_intent.dart';

void main() {
  group('UserModel', () {
    test('fromMap creates instance correctly', () {
      final now = DateTime.now().toIso8601String();
      final map = {
        'id': 'u1',
        'name': 'Sokha',
        'email': 'sokha@test.com',
        'phone': '012345678',
        'role': 'driver',
        'status': 'active',
        'operator_id': 'op1',
        'age': 30,
        'nationality': 'Khmer',
        'created_at': now,
      };
      final user = UserModel.fromMap(map);

      expect(user.id, 'u1');
      expect(user.name, 'Sokha');
      expect(user.email, 'sokha@test.com');
      expect(user.phone, '012345678');
      expect(user.role, 'driver');
      expect(user.status, 'active');
      expect(user.operatorId, 'op1');
      expect(user.age, 30);
      expect(user.nationality, 'Khmer');
      expect(user.createdAt, isNotNull);
    });

    test('fromMap handles null optionals', () {
      final map = {'id': 'u2'};
      final user = UserModel.fromMap(map);

      expect(user.id, 'u2');
      expect(user.name, isNull);
      expect(user.email, isNull);
      expect(user.role, isNull);
      expect(user.createdAt, isNull);
    });

    test('toMap excludes nulls', () {
      final user = UserModel(id: 'u3', name: 'Vichea', role: 'passenger');
      final map = user.toMap();

      expect(map['id'], isNull); // id is never included
      expect(map['name'], 'Vichea');
      expect(map['role'], 'passenger');
      expect(map.containsKey('email'), false);
      expect(map.containsKey('phone'), false);
    });

    test('role helpers', () {
      final p = UserModel(id: '1', role: 'passenger');
      final d = UserModel(id: '2', role: 'driver');
      final c = UserModel(id: '3', role: 'conductor');
      final oa = UserModel(id: '4', role: 'operator_admin');
      final sa = UserModel(id: '5', role: 'super_admin');

      expect(p.isPassenger, true);
      expect(d.isDriver, true);
      expect(c.isConductor, true);
      expect(oa.isOperatorAdmin, true);
      expect(sa.isSuperAdmin, true);
    });

    test('isActive / isSuspended', () {
      expect(UserModel(id: '1', status: 'active').isActive, true);
      expect(UserModel(id: '2', status: 'suspended').isSuspended, true);
      expect(UserModel(id: '3').isActive, false);
    });

    test('initials from name', () {
      // Single name → only first char
      expect(UserModel(id: '1', name: 'Sokha').initials, 'S');
      // Two names → first char of each
      expect(UserModel(id: '2', name: 'John Doe').initials, 'JD');
      // Single letter name
      expect(UserModel(id: '3', name: 'A').initials, 'A');
    });

    test('initials falls back to email', () {
      expect(UserModel(id: '4', email: 'test@test.com').initials, 'T');
    });

    test('initials fallback for empty name and email', () {
      expect(UserModel(id: '5').initials, '?');
    });

    test('copyWith preserves original and overrides specified', () {
      final u = UserModel(
        id: '1',
        name: 'A',
        email: 'a@a.com',
        role: 'passenger',
        status: 'active',
      );
      final copy = u.copyWith(name: 'B', status: 'suspended');

      expect(copy.id, '1');
      expect(copy.name, 'B');
      expect(copy.email, 'a@a.com');
      expect(copy.role, 'passenger');
      expect(copy.status, 'suspended');

      expect(u.name, 'A');
      expect(u.status, 'active');
    });
  });

  group('BusModel', () {
    test('fromMap and toMap round-trip', () {
      final map = {
        'id': 'b1',
        'operator_id': 'op1',
        'plate_number': 'PP-1234',
        'model': 'Toyota Hiace',
        'capacity': 16,
        'status': 'active',
      };
      final bus = BusModel.fromMap(map);
      expect(bus.plateNumber, 'PP-1234');
      expect(bus.model, 'Toyota Hiace');
      expect(bus.capacity, 16);

      final out = bus.toMap();
      expect(out['plate_number'], 'PP-1234');
      expect(out['model'], 'Toyota Hiace');
      expect(out['capacity'], 16);
    });

    test('fromMap handles missing optionals', () {
      final bus = BusModel.fromMap({
        'id': 'b2',
        'plate_number': 'PP-999',
        'model': 'Hiace',
        'capacity': 12,
      });
      expect(bus.operatorId, isNull);
      expect(bus.status, isNull);
    });
  });

  group('RouteModel', () {
    test('fromMap flattens operator relation', () {
      final map = {
        'id': 'r1',
        'name': 'PP → SR',
        'origin': 'Phnom Penh',
        'destination': 'Siem Reap',
        'distance_km': 320.5,
        'duration_min': 360,
        'operators': {'name': 'Express Co', 'logo_url': 'https://logo.url'},
      };
      final route = RouteModel.fromMap(map);
      expect(route.operatorName, 'Express Co');
      expect(route.operatorLogoUrl, 'https://logo.url');
      expect(route.distanceKm, 320.5);
    });

    test('displayName', () {
      final route = RouteModel(
        id: 'r1',
        name: 'PP → SR',
        origin: 'PP',
        destination: 'SR',
      );
      expect(route.displayName, 'PP → SR');
    });
  });

  group('ScheduleModel', () {
    test('computed minutes', () {
      final s = ScheduleModel(
        id: 's1',
        departureTime: '08:00',
        arrivalTime: '12:30',
      );
      expect(s.departureMinutes, 480);
      expect(s.arrivalMinutes, 750);
      expect(s.durationMinutes, 270);
    });

    test('durationMinutes handles overnight', () {
      final s = ScheduleModel(
        id: 's2',
        departureTime: '22:00',
        arrivalTime: '06:00',
      );
      expect(s.durationMinutes, 480);
    });

    test('fromMap nested relations', () {
      final map = {
        'id': 's1',
        'departure_time': '08:00',
        'arrival_time': '12:00',
        'price': 15.0,
        'routes': {
          'id': 'r1',
          'name': 'PP → SR',
          'origin': 'PP',
          'destination': 'SR',
        },
        'buses': {
          'id': 'b1',
          'plate_number': 'PP-123',
          'model': 'Hiace',
          'capacity': 16,
        },
      };
      final s = ScheduleModel.fromMap(map);
      expect(s.route?.name, 'PP → SR');
      expect(s.bus?.plateNumber, 'PP-123');
      expect(s.price, 15.0);
    });
  });

  group('TripModel', () {
    test('fromMap full', () {
      final map = {
        'id': 't1',
        'trip_date': '2025-06-15',
        'status': 'in_progress',
        'departed_at': '2025-06-15T08:00:00',
        'latitude': 11.55,
        'longitude': 104.91,
      };
      final trip = TripModel.fromMap(map);
      expect(trip.tripDate, '2025-06-15');
      expect(trip.isInProgress, true);
      expect(trip.latitude, 11.55);
      expect(trip.longitude, 104.91);
      expect(trip.departedAt, isNotNull);
    });

    test('status helpers', () {
      expect(TripModel(id: '1', tripDate: '2025-01-01', status: 'scheduled').isScheduled, true);
      expect(TripModel(id: '2', tripDate: '2025-01-01', status: 'in_progress').isInProgress, true);
      expect(TripModel(id: '3', tripDate: '2025-01-01', status: 'completed').isCompleted, true);
      expect(TripModel(id: '4', tripDate: '2025-01-01', status: 'cancelled').isCancelled, true);
    });

    test('toMap excludes nulls', () {
      final trip = TripModel(id: 't1', tripDate: '2025-06-15', status: 'scheduled');
      final map = trip.toMap();
      expect(map['departed_at'], isNull);
      expect(map['arrived_at'], isNull);
      expect(map['schedules'], isNull);
    });
  });

  group('BookingModel', () {
    test('fromMap with nested trip and ticket', () {
      final map = {
        'id': 'b1',
        'trip_id': 't1',
        'passenger_id': 'u1',
        'seat_number': 'A1',
        'status': 'confirmed',
        'total_price': 25.0,
        'passenger_name': 'Sokha',
        'passenger_age': 28,
        'passenger_phone': '012345',
        'passenger_nationality': 'Khmer',
        'trips': {
          'id': 't1',
          'trip_date': '2025-06-15',
          'status': 'scheduled',
          'schedules': {'id': 's1', 'departure_time': '08:00', 'arrival_time': '12:00'},
        },
        'tickets': [
          {'id': 'tk1', 'qr_code': 'qr1', 'status': 'valid'},
        ],
      };
      final b = BookingModel.fromMap(map);
      expect(b.id, 'b1');
      expect(b.isConfirmed, true);
      expect(b.trip?.tripDate, '2025-06-15');
      expect(b.tickets?.length, 1);
      expect(b.passengerName, 'Sokha');
      expect(b.canCancel, true);
    });

    test('canCancel only for confirmed or pending', () {
      final make = (String s) => BookingModel(id: '1', status: s);
      expect(make('confirmed').canCancel, true);
      expect(make('pending').canCancel, true);
      expect(make('cancelled').canCancel, false);
      expect(make('boarded').canCancel, false);
    });
  });

  group('TicketModel', () {
    test('status helpers', () {
      expect(TicketModel(id: '1', status: 'valid').isValid, true);
      expect(TicketModel(id: '2', status: 'used').isUsed, true);
      expect(TicketModel(id: '3', status: 'cancelled').isCancelled, true);
    });
  });

  group('OperatorModel', () {
    test('initials', () {
      expect(OperatorModel(id: '1', name: 'Express Co').initials, 'EC');
      expect(OperatorModel(id: '2', name: 'A').initials, 'A');
    });

    test('initials fallback', () {
      expect(OperatorModel(id: '3', name: '').initials, 'OP');
    });
  });

  group('NotificationItem', () {
    test('fromMap default type and isRead', () {
      final n = NotificationItem.fromMap({
        'id': 'n1',
        'user_id': 'u1',
        'title': 'Test',
        'body': 'Hello',
        'created_at': '2025-06-15T10:00:00',
      });
      expect(n.type, 'general');
      expect(n.isRead, false);
    });
  });

  group('IncidentModel', () {
    test('delayMinutes per type', () {
      expect(IncidentModel(
        id: '1', tripId: 't1', reportedBy: 'u1',
        type: 'delay', description: '', createdAt: DateTime.now(),
      ).delayMinutes, 20);

      expect(IncidentModel(
        id: '2', tripId: 't1', reportedBy: 'u1',
        type: 'breakdown', description: '', createdAt: DateTime.now(),
      ).delayMinutes, 30);

      expect(IncidentModel(
        id: '3', tripId: 't1', reportedBy: 'u1',
        type: 'accident', description: '', createdAt: DateTime.now(),
      ).delayMinutes, 45);

      expect(IncidentModel(
        id: '4', tripId: 't1', reportedBy: 'u1',
        type: 'traffic', description: '', createdAt: DateTime.now(),
      ).delayMinutes, 15);
    });
  });

  group('PaymentModel', () {
    test('helpers', () {
      expect(PaymentModel(id: '1', method: 'cash', status: 'paid').isPaid, true);
      expect(PaymentModel(id: '2', method: 'cash', status: 'pending').isPending, true);
      expect(PaymentModel(id: '3', method: 'cash', status: 'refunded').isRefunded, true);
      expect(PaymentModel(id: '4', method: 'bakong', status: 'paid').isBakong, true);
    });
  });

  group('PromotionModel', () {
    test('isPercentage / isFixed', () {
      expect(PromotionModel(id: '1', code: 'P10', discountType: 'percentage', discountValue: 10).isPercentage, true);
      expect(PromotionModel(id: '2', code: 'F5', discountType: 'fixed', discountValue: 5).isFixed, true);
    });

    test('applyDiscount percentage', () {
      final p = PromotionModel(id: '1', code: 'P10', discountType: 'percentage', discountValue: 10);
      expect(p.applyDiscount(100), 90.0);
    });

    test('applyDiscount fixed', () {
      final p = PromotionModel(id: '2', code: 'F5', discountType: 'fixed', discountValue: 5);
      expect(p.applyDiscount(100), 95.0);
    });

    test('applyDiscount returns full amount when expired', () {
      final p = PromotionModel(
        id: '3', code: 'X', discountType: 'fixed', discountValue: 10,
        isActive: false,
      );
      expect(p.applyDiscount(100), 100);
    });
  });

  group('WalletModel / WalletTransactionModel', () {
    test('WalletModel fromMap', () {
      final w = WalletModel.fromMap({
        'user_id': 'u1',
        'balance': 50.0,
        'updated_at': '2025-06-15T10:00:00Z',
      });
      expect(w.balance, 50.0);
      expect(w.userId, 'u1');
    });

    test('WalletTransactionModel isCredit / isDebit', () {
      final credit = WalletTransactionModel(
        id: '1', userId: 'u1', amount: 20, type: 'top_up', createdAt: DateTime.now(),
      );
      final debit = WalletTransactionModel(
        id: '2', userId: 'u1', amount: -15, type: 'payment', createdAt: DateTime.now(),
      );
      expect(credit.isCredit, true);
      expect(credit.isDebit, false);
      expect(debit.isDebit, true);
      expect(debit.isCredit, false);
    });
  });

  group('ReviewModel', () {
    test('fromMap with nested driver', () {
      final map = {
        'id': 'rv1',
        'booking_id': 'b1',
        'trip_id': 't1',
        'user_id': 'u1',
        'rating': 5,
        'comment': 'Great!',
        'created_at': '2025-06-15T10:00:00',
        'trips': {'id': 't1', 'trip_date': '2025-06-15', 'status': 'completed'},
      };
      final r = ReviewModel.fromMap(map);
      expect(r.rating, 5);
      expect(r.comment, 'Great!');
      expect(r.trip?.isCompleted, true);
    });

    test('toInsertMap excludes id', () {
      final r = ReviewModel(
        id: 'rv1', bookingId: 'b1', tripId: 't1', userId: 'u1',
        rating: 4, comment: 'Good', createdAt: DateTime.now(),
      );
      final insert = r.toInsertMap();
      expect(insert.containsKey('id'), false);
      expect(insert['rating'], 4);
    });
  });

  group('ChatMessage', () {
    test('default isError false', () {
      final m = ChatMessage(
        id: '1', role: ChatMessageRole.assistant,
        content: 'hello', timestamp: DateTime.now(),
      );
      expect(m.isError, false);
      expect(m.role, ChatMessageRole.assistant);
    });
  });

  group('BookingIntent', () {
    test('isComplete requires origin and destination', () {
      expect(const BookingIntent(origin: 'PP', destination: 'SR').isComplete, true);
      expect(const BookingIntent(origin: 'PP').isComplete, false);
      expect(const BookingIntent().isComplete, false);
    });

    test('resolveDate parses words', () {
      final now = DateTime.now();
      expect(BookingIntent(dateStr: 'today').resolveDate()?.day, now.day);
      expect(BookingIntent(dateStr: 'tomorrow').resolveDate()?.day, now.add(const Duration(days: 1)).day);
    });

    test('resolveDate parses ISO', () {
      final d = BookingIntent(dateStr: '2025-12-25').resolveDate();
      expect(d?.year, 2025);
      expect(d?.month, 12);
      expect(d?.day, 25);
    });

    test('resolveDate returns null for garbage', () {
      expect(BookingIntent(dateStr: 'xyz').resolveDate(), isNull);
    });

    test('extractDate finds date keywords', () {
      expect(BookingIntent.extractDate('book for today'), 'today');
      expect(BookingIntent.extractDate('going tomorrow'), 'tomorrow');
    });

    test('tryParse extracts [BOOKING] JSON', () {
      final result = BookingIntent.tryParse(
        'some text [BOOKING]{"origin":"PP","destination":"SR","passengers":2}[/BOOKING] trailing',
      );
      expect(result?.origin, 'PP');
      expect(result?.destination, 'SR');
      expect(result?.passengers, 2);
    });

    test('tryParse returns null for invalid JSON', () {
      expect(BookingIntent.tryParse('[BOOKING]bad-json[/BOOKING]'), isNull);
    });

    test('stripBookingTag removes tag', () {
      expect(
        BookingIntent.stripBookingTag('hello [BOOKING]...[/BOOKING] world'),
        'hello  world',
      );
    });

    test('extractFromUserMessage parses "PP to SR for 3 people"', () {
      final result = BookingIntent.extractFromUserMessage(
        'I want to go from Phnom Penh to Siem Reap for 3 people tomorrow',
      );
      expect(result?.origin, 'Phnom Penh');
      expect(result?.destination, 'Siem Reap');
      expect(result?.passengers, 3);
      expect(result?.dateStr, 'tomorrow');
    });

    test('detectDateOnly', () {
      expect(BookingIntent.detectDateOnly('today'), true);
      expect(BookingIntent.detectDateOnly('this monday'), true);
      expect(BookingIntent.detectDateOnly('PP to SR'), false);
    });

    test('copyWith', () {
      final a = const BookingIntent(origin: 'PP', passengers: 2);
      final b = a.copyWith(destination: 'SR', dateStr: 'tomorrow');
      expect(b.origin, 'PP');
      expect(b.destination, 'SR');
      expect(b.passengers, 2);
      expect(b.dateStr, 'tomorrow');
      expect(a.destination, isNull);
    });
  });
}
