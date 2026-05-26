# 🚌 BusExpress — Open Source Bus Booking App

A full-featured bus booking mobile application built with **Flutter** and **Supabase**. Supports multiple user roles including passengers, drivers, conductors, operator admins, and super admins.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-2.0+-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/License-MIT-blue)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)

---

## 📱 Screenshots

| Passenger Home | My Tickets | Live Tracking |
|---|---|---|
| Search routes, browse popular destinations | QR ticket with real-time status | Live bus location on OpenStreetMap |

| Driver Dashboard | Conductor Scanner | Operator Panel |
|---|---|---|
| Today's trip + GPS tracking | Scan passenger QR codes | Manage buses, routes, schedules |

---

## ✨ Features

### 🧍 Passenger
- Register / Login / Forgot Password
- Search bus routes by origin, destination and date
- Browse schedules with sorting (price, time, duration)
- Visual seat selection map
- Book single or multiple seats
- Real QR ticket (scannable by conductor)
- Live bus tracking on map (OpenStreetMap, free)
- Booking cancellation (with 2-hour cutoff rule)
- Booking history (upcoming & past)

### 🚌 Driver
- View today's assigned trip
- Start / End trip with one tap
- Live GPS tracking (updates every 15 seconds)
- Passenger list per trip
- Report incidents (breakdown, delay, accident)
- View upcoming trips and stats

### 🎫 Conductor
- View today's trip and boarding progress
- Full passenger list with filter (All / Waiting / Boarded)
- QR code scanner (real camera scan)
- Validate tickets with smart checks (wrong trip, already scanned, expired)
- Manually mark passengers as boarded

### 🏢 Operator Admin
- Dashboard with fleet stats
- Manage buses (add, edit, status: active/maintenance/retired)
- Manage routes (add, edit, activate/deactivate)
- Create schedules (route + bus + driver + days + price)
- Add staff (drivers and conductors with auth accounts)

### 👑 Super Admin
- System-wide dashboard (live trips, bookings, operators)
- Manage all operators (create, suspend, activate)
- Manage all users (search, filter by role, change role, suspend)

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3.0+ (iOS & Android) |
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
| Database | PostgreSQL via Supabase |
| Auth | Supabase Auth (email/password) |
| Realtime GPS | Supabase Realtime |
| Maps | flutter_map + OpenStreetMap (free) |
| QR Code Display | qr_flutter |
| QR Code Scanner | mobile_scanner |
| GPS | geolocator |

---

## 📋 Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- A [Supabase](https://supabase.com) account (free tier works)
- Android Studio or VS Code with Flutter extension

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/bus-express.git
cd bus-express
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Set up Supabase

1. Go to [supabase.com](https://supabase.com) and create a free project
2. Go to **SQL Editor** and run the schema files in this order:

```bash
# Run in Supabase SQL Editor:
1. schema.sql              ← creates all tables
2. test_data.sql           ← adds sample operators, routes, schedules
3. cancellation_policies.sql  ← RLS for cancellations
4. operator_admin_setup.sql   ← RLS for operator admin
5. super_admin_setup.sql      ← RLS for super admin
```

### 4. Configure Supabase credentials

Open `lib/supabase_config.dart` and replace with your project values:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

Find these in:
```
Supabase Dashboard → Project Settings → API
```

### 5. Configure permissions

**Android** — add to `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- GPS -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<!-- Camera (QR Scanner) -->
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS** — add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to track bus location for passengers.</string>
<key>NSCameraUsageDescription</key>
<string>Used to scan passenger QR tickets.</string>
```

### 6. Run the app

```bash
flutter run
```

---

## 🗄 Database Schema

The app uses 11 tables:

```
operators       — Bus companies
users           — All users (passengers, drivers, conductors, admins)
buses           — Bus fleet per operator
routes          — Route definitions (origin → destination)
stops           — Waypoints along a route
schedules       — Recurring trip schedules (days, times, price)
trips           — Real trip instances per date
bookings        — Passenger seat reservations
tickets         — QR tickets per booking
payments        — Payment records
incidents       — Driver-reported incidents
```

See `schema.sql` for full table definitions with relationships.

---

## 👥 User Roles & Test Accounts

After running `test_data.sql`, set up test accounts:

| Role | How to Create |
|---|---|
| **Passenger** | Register normally in the app |
| **Driver** | Create in Supabase Auth → set `role = 'driver'` in users table |
| **Conductor** | Create in Supabase Auth → set `role = 'conductor'` |
| **Operator Admin** | Create in Supabase Auth → set `role = 'operator_admin'` + `operator_id` |
| **Super Admin** | Set `role = 'super_admin'` on any existing user |

Quick SQL to promote your account:
```sql
UPDATE users SET role = 'super_admin' WHERE email = 'your@email.com';
```

---

## 📁 Project Structure

```
lib/
├── main.dart
├── supabase_config.dart
└── features/
    ├── auth/
    │   ├── screens/
    │   │   ├── splash_screen.dart
    │   │   ├── login_screen.dart
    │   │   ├── signup_screen.dart
    │   │   └── forgot_password_screen.dart
    │   └── widgets/
    │       └── auth_text_field.dart
    ├── passenger/
    │   ├── screens/
    │   │   ├── passenger_home_screen.dart
    │   │   ├── route_list_screen.dart
    │   │   ├── schedule_seat_screen.dart
    │   │   ├── booking_confirmation_screen.dart
    │   │   ├── my_tickets_screen.dart
    │   │   └── live_tracking_screen.dart
    │   ├── services/
    │   │   └── booking_cancellation_service.dart
    │   └── widgets/
    │       └── cancel_booking_sheet.dart
    ├── driver/
    │   └── screens/
    │       ├── driver_home_screen.dart
    │       ├── driver_trip_screen.dart
    │       └── driver_incident_screen.dart
    ├── conductor/
    │   └── screens/
    │       ├── conductor_home_screen.dart
    │       ├── conductor_passengers_screen.dart
    │       └── conductor_scanner_screen.dart
    ├── operator/
    │   └── screens/
    │       ├── operator_home_screen.dart
    │       ├── operator_routes_screen.dart
    │       ├── operator_buses_screen.dart
    │       ├── operator_schedules_screen.dart
    │       └── operator_staff_screen.dart
    ├── super_admin/
    │   └── screens/
    │       ├── super_admin_home_screen.dart
    │       ├── super_admin_operators_screen.dart
    │       └── super_admin_users_screen.dart
    └── notifications/
        ├── notification_service.dart
        └── notification_triggers.dart
```

---

## 🔐 Row Level Security (RLS)

All tables have RLS enabled. Key policies:

| Table | Passenger | Driver | Conductor | Operator Admin | Super Admin |
|---|---|---|---|---|---|
| routes | Read active | Read | Read | Full CRUD | Full CRUD |
| bookings | Own only | Own trips | Own trips | Read all | Read all |
| tickets | Own only | — | Scan/update | Read all | Read all |
| trips | Read all | Own trips | Own trips | Read all | Read all |
| users | Own profile | Own profile | Own profile | Own operator | Full CRUD |

---

## 🗺 Live Tracking

The app uses **OpenStreetMap** via `flutter_map` — completely free, no API key required.

- Driver app sends GPS coordinates every 15 seconds
- Passenger app subscribes via Supabase Realtime
- Bus marker pulses green when trip is in progress

---

## 📦 Dependencies

```yaml
supabase_flutter: ^2.3.0      # Backend + Auth + Realtime
geolocator: ^11.0.0           # GPS for driver tracking
flutter_map: ^6.1.0           # Map display (OpenStreetMap)
latlong2: ^0.9.0              # Coordinates helper
mobile_scanner: ^5.0.0        # QR code scanner (conductor)
qr_flutter: ^4.1.0            # QR code display (passenger ticket)
```

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Ideas for contributions
- [ ] Online payment integration (Stripe / local gateways)
- [ ] Push notifications (Firebase FCM)
- [ ] Passenger profile screen
- [ ] Booking history with filters
- [ ] Rating and review system
- [ ] Multi-language support (Khmer / English)
- [ ] Dark mode
- [ ] Web admin dashboard

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 BusExpress Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🙏 Acknowledgements

- [Flutter](https://flutter.dev) — UI framework
- [Supabase](https://supabase.com) — Backend as a Service
- [OpenStreetMap](https://openstreetmap.org) — Free map tiles
- [flutter_map](https://github.com/fleaflet/flutter_map) — Map widget
- [qr_flutter](https://github.com/theyakka/qr.flutter) — QR generation

---

## 📬 Support

If you find a bug or want to request a feature, please [open an issue](https://github.com/yourusername/bus-express/issues).
