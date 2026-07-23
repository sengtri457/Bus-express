# 📡 BusExpress API Documentation

&#x20;

This document covers all Supabase database operations used in the BusExpress app. Since the app uses Supabase's auto-generated REST API, all endpoints follow the PostgREST convention.

**Base URL:** `https://YOUR_PROJECT.supabase.co`

**Authentication:** All requests require the `Authorization: Bearer <jwt_token>` header obtained after login.

**Anon Key Header:** `apikey: YOUR_SUPABASE_ANON_KEY`

***

## 📋 Table of Contents

1. [Authentication](https://claude.ai/chat/2b32515a-7ae7-4b99-914c-3731090cef67#1-authentication)
2. [Users](https://claude.ai/chat/2b32515a-7ae7-4b99-914c-3731090cef67#2-users)
3. [Operators](https://claude.ai/chat/2b32515a-7ae7-4b99-914c-3731090cef67#3-operators)
4. [Routes](https://claude.ai/chat/2b32515a-7ae7-4b99-914c-3731090cef67#4-routes)
5. [Buses](https://claude.ai/chat/2b32515a-7ae7-4b99-914c-3731090cef67#5-buses)
6. [Schedules](https://claude.ai/chat/2b32515a-7ae7-4b99-914c-3731090cef67#6-schedules)
7. [Trips](https://claude.ai/chat/2b32515a-7ae7-4b99-914c-3731090cef67#7-trips)
8. [Bookings](https://claude.ai/chat/2b32515a-7ae7-4b99-914c-3731090cef67#8-bookings)
9. [Tickets](https://claude.ai/chat/2b32515a-7ae7-4b99-914c-3731090cef67#9-tickets)
10. [Payments](https://claude.ai/chat/2b32515a-7ae7-4b99-914c-3731090cef67#10-payments)
11. [Incidents](https://claude.ai/chat/2b32515a-7ae7-4b99-914c-3731090cef67#11-incidents)
12. [Stops](https://claude.ai/chat/2b32515a-7ae7-4b99-914c-3731090cef67#12-stops)

***

## 1. Authentication

All auth is handled via Supabase Auth endpoints.

### Register

```
POST /auth/v1/signup

```

**Request Body:**

```
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "data": {
    "name": "Sok Dara",
    "phone": "012 345 678"
  }
}

```

**Response:**

```
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "created_at": "2025-01-01T00:00:00Z"
  },
  "session": {
    "access_token": "jwt_token",
    "refresh_token": "refresh_token"
  }
}

```

**Flutter:**

```
final response = await supabase.auth.signUp(
  email: email,
  password: password,
  data: {'name': name, 'phone': phone},
);

```

***

### Login

```
POST /auth/v1/token?grant_type=password

```

**Request Body:**

```
{
  "email": "user@example.com",
  "password": "SecurePass123"
}

```

**Flutter:**

```
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
final jwt = response.session?.accessToken;

```

***

### Logout

```
POST /auth/v1/logout

```

**Flutter:**

```
await supabase.auth.signOut();

```

***

### Reset Password

```
POST /auth/v1/recover

```

**Request Body:**

```
{
  "email": "user@example.com"
}

```

**Flutter:**

```
await supabase.auth.resetPasswordForEmail(email);

```

***

## 2. Users

### Get current user profile

```
GET /rest/v1/users?id=eq.{user_id}&select=*

```

**Flutter:**

```
final data = await supabase
    .from('users')
    .select('id, name, email, phone, role, status')
    .eq('id', supabase.auth.currentUser!.id)
    .single();

```

**Response:**

```
{
  "id": "uuid",
  "name": "Sok Dara",
  "email": "user@example.com",
  "phone": "012 345 678",
  "role": "passenger",
  "operator_id": null,
  "status": "active",
  "created_at": "2025-01-01T00:00:00Z"
}

```

***

### Update user profile

```
PATCH /rest/v1/users?id=eq.{user_id}

```

**Flutter:**

```
await supabase
    .from('users')
    .update({'name': 'New Name', 'phone': '012 999 888'})
    .eq('id', userId);

```

***

### Get all users (Super Admin only)

```
GET /rest/v1/users?select=*&order=created_at.desc

```

**Flutter:**

```
final data = await supabase
    .from('users')
    .select('id, name, email, phone, role, status, created_at')
    .order('created_at', ascending: false);

```

***

### Update user role (Super Admin only)

```
PATCH /rest/v1/users?id=eq.{user_id}

```

**Flutter:**

```
await supabase
    .from('users')
    .update({'role': 'driver', 'operator_id': operatorId})
    .eq('id', userId);

```

**Role values:** `passenger` | `driver` | `conductor` | `operator_admin` | `super_admin`

**Status values:** `active` | `inactive` | `suspended`

***

## 3. Operators

### Get all active operators

```
GET /rest/v1/operators?status=eq.active&select=*

```

**Flutter:**

```
final data = await supabase
    .from('operators')
    .select('id, name, contact, status')
    .eq('status', 'active');

```

***

### Create operator (Super Admin only)

```
POST /rest/v1/operators

```

**Request Body:**

```
{
  "name": "Capitol Express",
  "contact": "+855 23 123 456",
  "status": "active"
}

```

**Flutter:**

```
await supabase.from('operators').insert({
  'name': name,
  'contact': contact,
  'status': 'active',
});

```

***

### Update operator status (Super Admin only)

```
PATCH /rest/v1/operators?id=eq.{operator_id}

```

**Flutter:**

```
await supabase
    .from('operators')
    .update({'status': 'inactive'})
    .eq('id', operatorId);

```

***

## 4. Routes

### Get active routes

```
GET /rest/v1/routes?status=eq.active&select=*

```

**Flutter:**

```
final data = await supabase
    .from('routes')
    .select('id, name, origin, destination, distance_km, duration_min')
    .eq('status', 'active');

```

***

### Search routes by origin and destination

```
GET /rest/v1/routes?origin=ilike.*Phnom Penh*&destination=ilike.*Siem Reap*&status=eq.active

```

**Flutter:**

```
final data = await supabase
    .from('routes')
    .select('id, origin, destination, distance_km, duration_min')
    .ilike('origin', '%$origin%')
    .ilike('destination', '%$destination%')
    .eq('status', 'active');

```

***

### Create route (Operator Admin)

```
POST /rest/v1/routes

```

**Request Body:**

```
{
  "operator_id": "uuid",
  "name": "Phnom Penh → Siem Reap",
  "origin": "Phnom Penh",
  "destination": "Siem Reap",
  "distance_km": 314,
  "duration_min": 360,
  "status": "active"
}

```

***

### Update route

```
PATCH /rest/v1/routes?id=eq.{route_id}

```

**Flutter:**

```
await supabase
    .from('routes')
    .update({'status': 'inactive'})
    .eq('id', routeId);

```

***

## 5. Buses

### Get operator's buses

```
GET /rest/v1/buses?operator_id=eq.{operator_id}&select=*

```

**Flutter:**

```
final data = await supabase
    .from('buses')
    .select('id, plate_number, model, capacity, status')
    .eq('operator_id', operatorId);

```

***

### Create bus

```
POST /rest/v1/buses

```

**Request Body:**

```
{
  "operator_id": "uuid",
  "plate_number": "PP-1234-AA",
  "model": "Hyundai Universe",
  "capacity": 40,
  "status": "active"
}

```

**Status values:** `active` | `maintenance` | `retired`

***

### Update bus status

```
PATCH /rest/v1/buses?id=eq.{bus_id}

```

**Flutter:**

```
await supabase
    .from('buses')
    .update({'status': 'maintenance'})
    .eq('id', busId);

```

***

## 6. Schedules

### Get active schedules for a route

```
GET /rest/v1/schedules?route_id=eq.{route_id}&status=eq.active&select=*,routes(*),buses(*),users!schedules_driver_id_fkey(name)

```

**Flutter (with joins):**

```
final data = await supabase
    .from('schedules')
    .select('''
      id, departure_time, arrival_time, days_of_week, price, status,
      routes!inner ( id, origin, destination, operator_id ),
      buses ( model, plate_number, capacity ),
      users!schedules_driver_id_fkey ( name )
    ''')
    .eq('routes.operator_id', operatorId)
    .eq('status', 'active');

```

**Response:**

```
[
  {
    "id": "uuid",
    "departure_time": "07:00:00",
    "arrival_time": "13:00:00",
    "days_of_week": "1,2,3,4,5,6,7",
    "price": 12.00,
    "status": "active",
    "routes": { "origin": "Phnom Penh", "destination": "Siem Reap" },
    "buses": { "model": "Hyundai Universe", "plate_number": "PP-1234-AA" }
  }
]

```

**`days_of_week`** **format:** Comma-separated numbers `1=Mon ... 7=Sun` e.g. `"1,2,3,4,5"` = Weekdays, `"1,2,3,4,5,6,7"` = Every day

***

### Create schedule

```
POST /rest/v1/schedules

```

**Request Body:**

```
{
  "route_id": "uuid",
  "bus_id": "uuid",
  "driver_id": "uuid",
  "conductor_id": "uuid",
  "departure_time": "07:00:00",
  "arrival_time": "13:00:00",
  "days_of_week": "1,2,3,4,5,6,7",
  "price": 12.00,
  "status": "active"
}

```

***

## 7. Trips

### Get today's trip for driver

```
GET /rest/v1/trips?driver_id=eq.{driver_id}&trip_date=eq.{today}&select=*,schedules(*)

```

**Flutter:**

```
final today = DateTime.now().toIso8601String().split('T')[0];
final data = await supabase
    .from('trips')
    .select('''
      id, trip_date, status, departed_at, arrived_at, latitude, longitude,
      schedules (
        departure_time, arrival_time,
        routes ( origin, destination, distance_km, duration_min ),
        buses ( model, plate_number, capacity )
      )
    ''')
    .eq('driver_id', driverId)
    .eq('trip_date', today)
    .maybeSingle();

```

***

### Get or create trip instance

```
GET /rest/v1/trips?schedule_id=eq.{schedule_id}&trip_date=eq.{date}
POST /rest/v1/trips

```

**Flutter (get or create):**

```
// Try to find existing trip
final existing = await supabase
    .from('trips')
    .select('id')
    .eq('schedule_id', scheduleId)
    .eq('trip_date', tripDate)
    .maybeSingle();

if (existing == null) {
  // Create new trip instance
  final newTrip = await supabase
      .from('trips')
      .insert({
        'schedule_id': scheduleId,
        'trip_date': tripDate,
        'bus_id': busId,
        'driver_id': driverId,
        'status': 'scheduled',
      })
      .select('id')
      .single();
}

```

***

### Start trip (Driver)

```
PATCH /rest/v1/trips?id=eq.{trip_id}

```

**Request Body:**

```
{
  "status": "in_progress",
  "departed_at": "2025-01-01T07:05:00Z"
}

```

***

### Update GPS location (Driver — every 15 seconds)

```
PATCH /rest/v1/trips?id=eq.{trip_id}

```

**Request Body:**

```
{
  "latitude": 11.5564,
  "longitude": 104.9282
}

```

**Flutter:**

```
await supabase.from('trips').update({
  'latitude': position.latitude,
  'longitude': position.longitude,
}).eq('id', tripId);

```

***

### End trip (Driver)

```
PATCH /rest/v1/trips?id=eq.{trip_id}

```

**Request Body:**

```
{
  "status": "completed",
  "arrived_at": "2025-01-01T13:10:00Z"
}

```

***

### Subscribe to live GPS (Passenger — Realtime)

**Flutter:**

```
supabase
    .from('trips')
    .stream(primaryKey: ['id'])
    .eq('id', tripId)
    .listen((data) {
      final lat = data.first['latitude'];
      final lng = data.first['longitude'];
      // Update map marker
    });

```

***

## 8. Bookings

### Create booking

```
POST /rest/v1/bookings

```

**Request Body:**

```
{
  "trip_id": "uuid",
  "passenger_id": "uuid",
  "seat_number": "1A",
  "status": "confirmed",
  "total_price": 12.00,
  "booked_at": "2025-01-01T10:00:00Z",
  "booking_channel": "online"
}

```

**`booking_channel`** **values:** `online` | `counter` | `conductor`

***

### Get passenger's bookings

```
GET /rest/v1/bookings?passenger_id=eq.{user_id}&status=neq.cancelled&select=*,trips(*,schedules(*,routes(*)))

```

**Flutter:**

```
final data = await supabase
    .from('bookings')
    .select('''
      id, seat_number, status, total_price, booked_at,
      trips (
        id, trip_date, status,
        schedules (
          departure_time, arrival_time,
          routes ( origin, destination )
        )
      ),
      tickets ( id, qr_code, status )
    ''')
    .eq('passenger_id', userId)
    .not('status', 'eq', 'cancelled')
    .order('booked_at', ascending: false);

```

***

### Get booked seats for a trip (seat availability)

```
GET /rest/v1/bookings?trip_id=eq.{trip_id}&status=in.(confirmed,pending,boarded)&select=seat_number

```

**Flutter:**

```
final bookings = await supabase
    .from('bookings')
    .select('seat_number')
    .eq('trip_id', tripId)
    .inFilter('status', ['confirmed', 'pending', 'boarded']);

final bookedSeats = bookings.map((b) => b['seat_number'] as String).toList();

```

***

### Cancel booking (Passenger)

```
PATCH /rest/v1/bookings?id=eq.{booking_id}

```

**Request Body:**

```
{
  "status": "cancelled"
}

```

**Flutter:**

```
await supabase
    .from('bookings')
    .update({'status': 'cancelled'})
    .eq('id', bookingId);

```

***

### Mark passenger as boarded (Conductor)

```
PATCH /rest/v1/bookings?id=eq.{booking_id}

```

**Request Body:**

```
{
  "status": "boarded"
}

```

**Booking status flow:**

```
pending → confirmed → boarded
                   ↘ cancelled

```

***

## 9. Tickets

### Create ticket

```
POST /rest/v1/tickets

```

**Request Body:**

```
{
  "booking_id": "uuid",
  "qr_code": "BUS-{booking_id}-{timestamp}",
  "status": "valid"
}

```

**QR code format:** `BUS-{booking_uuid}-{unix_timestamp}`

***

### Look up ticket by QR code (Conductor scan)

```
GET /rest/v1/tickets?qr_code=eq.{scanned_value}&select=*,bookings(id,status,seat_number,trip_id,users!bookings_passenger_id_fkey(name,phone))

```

**Flutter:**

```
final ticket = await supabase
    .from('tickets')
    .select('''
      id, status, scanned_at,
      bookings (
        id, status, seat_number, trip_id,
        users!bookings_passenger_id_fkey ( name, phone )
      )
    ''')
    .eq('qr_code', scannedValue)
    .maybeSingle();

```

***

### Scan / validate ticket (Conductor)

```
PATCH /rest/v1/tickets?id=eq.{ticket_id}

```

**Request Body:**

```
{
  "status": "used",
  "scanned_at": "2025-01-01T07:15:00Z",
  "scanned_by": "conductor_uuid"
}

```

**Ticket status values:** `valid` | `used` | `expired` | `cancelled`

***

### Cancel ticket

```
PATCH /rest/v1/tickets?booking_id=eq.{booking_id}

```

**Request Body:**

```
{
  "status": "cancelled"
}

```

***

## 10. Payments

### Create payment record

```
POST /rest/v1/payments

```

**Request Body:**

```
{
  "booking_id": "uuid",
  "amount": 12.00,
  "method": "cash",
  "status": "pending"
}

```

**`method`** **values:** `cash` | `card` | `e-wallet` | `bank_transfer`

**`status`** **values:** `pending` | `paid` | `failed` | `refunded`

***

### Get payment for a booking

```
GET /rest/v1/payments?booking_id=eq.{booking_id}&select=*

```

**Flutter:**

```
final payment = await supabase
    .from('payments')
    .select('id, amount, method, status, paid_at')
    .eq('booking_id', bookingId)
    .maybeSingle();

```

***

### Mark payment as refunded (on cancellation)

```
PATCH /rest/v1/payments?booking_id=eq.{booking_id}&status=eq.paid

```

**Request Body:**

```
{
  "status": "refunded"
}

```

***

## 11. Incidents

### Report incident (Driver)

```
POST /rest/v1/incidents

```

**Request Body:**

```
{
  "trip_id": "uuid",
  "reported_by": "driver_uuid",
  "type": "delay",
  "description": "Heavy traffic near Skun. 20-minute delay expected.",
  "created_at": "2025-01-01T09:30:00Z"
}

```

**`type`** **values:** `breakdown` | `delay` | `accident` | `other`

***

### Get incidents for a trip

```
GET /rest/v1/incidents?trip_id=eq.{trip_id}&select=*&order=created_at.desc

```

**Flutter:**

```
final data = await supabase
    .from('incidents')
    .select('id, type, description, created_at')
    .eq('trip_id', tripId)
    .order('created_at', ascending: false);

```

***

## 12. Stops

### Get stops for a route (ordered)

```
GET /rest/v1/stops?route_id=eq.{route_id}&select=*&order=order_no.asc

```

**Flutter:**

```
final stops = await supabase
    .from('stops')
    .select('id, name, latitude, longitude, order_no')
    .eq('route_id', routeId)
    .order('order_no');

```

**Response:**

```
[
  { "id": "uuid", "name": "Phnom Penh Station", "latitude": 11.5564, "longitude": 104.9282, "order_no": 1 },
  { "id": "uuid", "name": "Kampong Thom",       "latitude": 12.7111, "longitude": 104.8882, "order_no": 2 },
  { "id": "uuid", "name": "Siem Reap Station",   "latitude": 13.3671, "longitude": 103.8448, "order_no": 3 }
]

```

***

## ⚠️ Error Handling

All Supabase operations throw typed exceptions:

```
try {
  final data = await supabase.from('bookings').select().single();
} on PostgrestException catch (e) {
  // Database / RLS errors
  print('DB Error: ${e.message} | Code: ${e.code}');
  // PGRST116 = no rows found (.single() with no result)
  // 42501     = RLS policy violation
} on AuthException catch (e) {
  // Auth errors
  print('Auth Error: ${e.message}');
} catch (e) {
  // Network or unexpected errors
  print('Error: $e');
}

```

**Common error codes:**

| Code       | Meaning                           | Fix                               |
| :--------- | :-------------------------------- | :-------------------------------- |
| `PGRST116` | No rows returned from `.single()` | Use `.maybeSingle()` instead      |
| `23505`    | Unique constraint violation       | Duplicate seat/email/plate number |
| `42501`    | RLS policy denied                 | User doesn't have permission      |
| `23503`    | Foreign key violation             | Referenced ID doesn't exist       |

***

## 🔄 Realtime Subscriptions

Supabase Realtime allows listening to database changes live.

### Listen to trip GPS updates

```
final subscription = supabase
    .from('trips')
    .stream(primaryKey: ['id'])
    .eq('id', tripId)
    .listen((List<Map<String, dynamic>> data) {
      if (data.isEmpty) return;
      final lat = data.first['latitude'];
      final lng = data.first['longitude'];
      final status = data.first['status'];
      // Update UI
    });

// Cancel when done
subscription.cancel();

```

### Listen to booking status changes

```
final subscription = supabase
    .from('bookings')
    .stream(primaryKey: ['id'])
    .eq('passenger_id', userId)
    .listen((data) {
      // Handle booking updates
    });

```

***

## 📊 Database Relationships

```
operators
  ├── buses (operator_id)
  ├── routes (operator_id)
  └── users (operator_id) [staff only]

routes
  ├── stops (route_id)
  └── schedules (route_id)
      ├── trips (schedule_id)
      │   ├── bookings (trip_id)
      │   │   ├── tickets (booking_id)
      │   │   └── payments (booking_id)
      │   └── incidents (trip_id)
      ├── buses (bus_id)
      └── users as driver (driver_id)
          users as conductor (conductor_id)

```

***

_Generated for BusExpress v1.0.0 — Built with Flutter + Supabase_
