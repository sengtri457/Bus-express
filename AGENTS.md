# Bus Express — AGENTS.md

## Project Overview

Flutter bus ticketing app with Supabase backend. Features passenger live tracking, trip management, booking with promo codes, and role-based access (passenger, driver, conductor, operator, super_admin).

## Tech Stack

- Flutter (Dart)
- Supabase (auth, postgres, realtime)
- Packages: supabase_flutter, geolocator, flutter_map, phone_number, http, mobile_scanner, qr_flutter, intl, flutter_dotenv

## Auth Methods Implemented

1. Email/password (login + signup)
2. Google OAuth (with web redirect fix)

## Session Summary (Jun 14, 2026)

### What Was Done

#### 1. Driver Trip Screen (`lib/features/screens/drivers/driver_trips_screen.dart`)

- Added GPS fix before setting trip to `in_progress` (passengers see bus immediately)
- Incident-aware delay calculation (20/30/45/15 min)
- End-trip time validation with countdown timer
- Disabled "End Trip" button until adjusted arrival time
- Delay info card + consolidated time formatting helpers

#### 2. Live Tracking Screen (`lib/features/screens/passengers/live_tracking_screen.dart`)

- Show "Locating bus…" (amber, GPS icon) when `busPosition` is null
- Hide LIVE badge until coordinates arrive
- Fixed `break` statements in `_StatusOverlayCard` switch

#### 3. Booking Safeguards

- `route_list_screen.dart:126` — Exclude `in_progress` trips from results
- `schedule_seat_screen.dart:29` — `_isExpired` blocks `in_progress`
- `booking_confirmation_screen.dart:227` — Safety check blocks `in_progress`/`completed`/`cancelled`

#### 4. Google OAuth

- Added `_signInWithGoogle()` method + "Continue with Google" button
- Auto-creates `users` record for new OAuth users
- Web redirect fix: `redirectTo: Uri.base.toString()` for `kIsWeb`
- **Required**: Enable Google provider + add redirect URLs in Supabase dashboard (Authentication → URL Configuration)

#### 5. Splash Screen Fix

- `splash_screen.dart`: `_navigateByRole()` now routes correctly per role

#### 6. Booking Confirmation Screen (`lib/features/screens/passengers/booking_confirmation_screen.dart`)

- Replaced read-only Passenger card with editable form fields: Full Name, Age, Phone, Nationality
- Added form validation (name required, age 1-120, phone with country code)
- Installed `phone_number` package for libphonenumber E.164 validation
- On confirm: validates phone → saves to `users` table → includes passenger info in booking insert
- **Required**: Run `lib/features/screens/passengers/add_passenger_info_columns.sql` in Supabase SQL editor to add columns (`passenger_name`, `passenger_age`, `passenger_phone`, `passenger_nationality` on bookings; `age`, `nationality` on users)

### Pending / Not Started

- **Passenger info fields** on booking screen: Analyzed only (Full name, Age, Phone, Nationality) — now implemented.

### DB Setup Notes

- Supabase URL & anon key in `.env`
- Client config in `lib/supabase_config.dart`
- `syncOverdueTrips()` auto-completes timed-out trips
- Bookings table uses `passenger_id` FK → `users.id`

## Session Summary (Jun 18, 2026) — Multi-language Support (In Progress)

### What Was Done

#### 1. pubspec.yaml — i18n dependencies added

- Added `flutter_localizations` (sdk dep) for Material/Cupertino localization
- Added `google_fonts: ^6.2.1` for Khmer font support
- Added `generate: true` under `flutter:` section to enable `flutter gen-l10n`

### Pending (Next Session)

1. Create `l10n.yaml` at project root (config for gen-l10n)
2. Create `lib/l10n/` with `app_en.arb` and `app_km.arb` (all strings must be extracted from \~47 files)
3. Run `flutter gen-l10n` to generate `AppLocalizations`
4. Create `localeProvider` in Riverpod for language switching
5. Configure `MaterialApp` with `localizationsDelegates`, `supportedLocales`, `locale`
6. Create helper extension for cleaner access (e.g., `context.tr.xxx`)
7. Replace hardcoded strings in all screens (auth, passenger, driver, conductor, operator, super admin, shared)
8. Add language switcher UI (profile screen or app drawer)
9. Run `dart analyze` and fix errors

### Running the App

```Shell
flutter run           # web
flutter run -d chrome # web (force)
flutter run -d <device-id>
```

### Code Analysis

```Shell
dart analyze lib/path/to/file.dart
```
