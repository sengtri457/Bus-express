# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Bus Express is a Flutter bus-ticketing app with a Supabase backend. Five user roles drive the whole app: `passenger`, `driver`, `conductor`, `operator_admin`, `super_admin`. A detailed companion doc lives in [AGENTS.md](AGENTS.md) — keep the two in sync when architecture changes.

## Commands

```Shell
flutter pub get                          # install deps
flutter run                              # run on connected device/emulator
flutter run -d chrome                    # run on web
flutter gen-l10n                         # regenerate AppLocalizations after editing .arb files
flutter analyze                          # lint whole project
dart analyze lib/path/to/file.dart       # lint a single file
flutter test                             # run all tests
flutter test test/widget_test.dart       # run a single test file
```

Supabase (from `supabase/`):

```Shell
supabase start                           # local stack
supabase db push                         # apply migrations in supabase/migrations/
supabase functions deploy <name>         # deploy an edge function
```

## Configuration

* Credentials come from a **`.env`** **file at repo root** (gitignored, listed as a Flutter asset in `pubspec.yaml`). The README's instruction to hardcode values in `supabase_config.dart` is **outdated** — `SupabaseConfig` reads everything via `dotenv`.
* Keys used: `supabaseUrl`, `supabaseAnonKey`, `BAKONG_ACCOUNT_ID`, `BAKONG_MERCHANT_NAME`, `BAKONG_API_URL`. `BAKONG_ACCESS_TOKEN` is **server-side only** (a Supabase Edge Function secret), never shipped in the app.
* The README's "Project Structure" section is also **stale** — screens moved from `lib/features/<role>/` to `lib/features/screens/<role>s/` (see below).

## Architecture

**Entrypoint** — [lib/main.dart](lib/main.dart): loads `.env`, captures cold-start deep links via `app_links` *before* Supabase init, initializes Supabase with `AuthFlowType.implicit`, inits `NotificationService`, wraps the app in `DevicePreview` + Riverpod `ProviderScope`. A global `navigatorKey` enables navigation from outside the widget tree (used for password-recovery redirects).

**Layering** (state flows top-down):

* **Screens** — `lib/features/screens/{passengers,drivers,conductors,operators,superAdmin}/`, plus `lib/features/auth/` (login/signup/reset) and `lib/features/onboarding/`. Per-role `widgets/` and `services/` subfolders.
* **Providers** — `lib/providers/` — Riverpod (`flutter_riverpod`). This is the state layer screens watch.
* **Repositories** — `lib/repositories/` — all extend `BaseRepository`, which exposes `client` (from `SupabaseConfig.client`) and a `table` query builder. This is the only layer that talks to Supabase tables directly.
* **Services** — `lib/services/` — cross-cutting integrations (Bakong payments, notifications, receipts/PDF, wallet, LLM, email, web/native download helpers via conditional import).
* **Models** — `lib/models/` — plain data classes.
* **Core** — `lib/core/` — `error/result.dart` (sealed `Result<T>` = `Success<T>` | `Failure<T>`), `theme/app_theme.dart` (design tokens), `utils/`.
* **Shared** — `lib/shared/widgets/` — reusable UI (avatar, empty state, loading overlay, stat card, trip status badge, …).

**Barrel exports** exist and should be preferred for imports: `lib/core/core.dart`, `lib/models/models.dart`, `lib/repositories/repositories.dart`.

**Design system** — use tokens from `app_theme.dart`: `AppColors`, `AppTheme`, `AppSpacing`, `AppRadius`, `AppAnimations`, `AppShadows`. Fonts use `GoogleFonts.notoSansKhmer*` for Khmer support.

## Critical flows

* **Trip lifecycle**: `scheduled` → `in_progress` → `completed` / `cancelled`. Booking screens block seats on `in_progress`/`completed`/`cancelled`. `SupabaseConfig.syncOverdueTrips()` auto-completes trips whose scheduled departure (if never started) or arrival (if in progress) has passed — it handles overnight trips where arrival < departure.
* **Password reset**: `main.dart` listens for `AuthChangeEvent.passwordRecovery` and pushes `ResetPasswordScreen` via `navigatorKey`. Cold-start recovery deep links are handled manually in `main()` before Supabase init (supabase\_flutter skips them on mobile).
* **Google OAuth redirect**: web → `Uri.base.toString()`; mobile → `io.supabase.busbooking://login-callback/`.
* **Driver GPS**: pushes location every 15s; passengers subscribe via Supabase Realtime.
* **Conductor/driver gating**: a driver cannot end a trip until the bus is full without conductor permission; conductor can allow starting a not-full trip.
* **Bakong KHQR payments**: bill numbers truncated to 25 chars. SIT sandbox base is `https://sit-api-bakong.nbc.org.kh`; prod default `https://api-bakong.nbc.gov.kh`. Transaction verification runs in the `check-bakong-transaction` edge function. `bakong-regional-proxy/` is a small standalone Node proxy.

## Supabase backend

* **Migrations**: `supabase/migrations/` (RLS policies, seat holds, promotions, reviews, notifications, OTP, etc.). RLS is enabled on all tables.
* **Edge Functions**: `supabase/functions/` — `check-bakong-transaction`, `send-otp`, `verify-otp`, `send-receipt`.

## Localization

* `l10n.yaml` at root; ARB files in `lib/l10n/` (`app_en.arb`, `app_km.arb`), template is `app_en.arb`, generated class is `AppLocalizations`.
* Access strings via the `context.tr.xxx` pattern. Plurals exist (see `booking*` keys).
* `localeProvider` (Riverpod) persists the choice with `SharedPreferences`.
* **After editing any ARB file, run** **`flutter gen-l10n`.**

## Testing

* `flutter_test` + `mocktail`. Helper at `test/helpers/mock_supabase.dart` (`SupabaseMock` with `MockGoTrueClient`).
* Inject a mock client via `SupabaseConfig.setTestClient(client)` / `clearTestClient()` (both `@visibleForTesting`).
* Test coverage is currently minimal (mostly the placeholder `widget_test.dart`).

## Conventions (enforced by `analysis_options.yaml`)

* **Single quotes** for strings (`prefer_single_quotes`).
* **Relative imports** over package imports (`prefer_relative_imports`).
* Prefer `const` constructors/declarations and `final` locals.
* Use `debugPrint`, **never** **`print`** (`avoid_print` is on).
* Do **not** add code comments unless asked.

