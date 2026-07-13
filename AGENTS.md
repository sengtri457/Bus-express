# Bus Express — AGENTS.md

Flutter bus ticketing app with Supabase backend. Roles: passenger, driver, conductor, operator_admin, super_admin.

## Commands

```sh
flutter pub get                          # install deps
flutter gen-l10n                         # regenerate AppLocalizations after .arb changes
dart analyze lib/path/to/file.dart       # lint single file
flutter run -d chrome                    # web
flutter test                             # run tests
```

## Architecture

- **Screens**: `lib/features/screens/{passengers,drivers,conductors,operators,superAdmin}/` — NOT under `lib/features/passenger/` as README says
- **Auth screens**: `lib/features/auth/` (separate from screens dir)
- **Entrypoint**: `lib/main.dart` — loads `.env`, inits Supabase (`AuthFlowType.implicit`), sets up Riverpod `ProviderScope`
- **State**: Riverpod (`flutter_riverpod`) — providers in `lib/providers/`
- **Database layer**: `lib/repositories/` extend `BaseRepository` (which gets client from `SupabaseConfig.client`)
- **Result pattern**: `lib/core/error/result.dart` — sealed `Result<T>` with `Success`/`Failure`
- **Design tokens**: `lib/core/theme/app_theme.dart` — use `AppColors`, `AppTheme`, `AppSpacing`, `AppRadius`, `AppAnimations`, `AppShadows`
- **Font**: `GoogleFonts.notoSansKhmerTextTheme()` — Khmer support via google_fonts
- **Shared widgets**: `lib/shared/widgets/` — `avatar_widget`, `empty_state`, `loading_overlay`, `stat_card`, `trip_status_badge`, etc.
- **Barrel exports** exist for core, models, and repositories — prefer importing from these

## Critical flows

- **Password reset**: Listens for `AuthChangeEvent.passwordRecovery` in `main.dart` and pushes `ResetPasswordScreen` via global `navigatorKey`
- **Deep links**: Cold-start deep links (password reset) must be handled manually — `main.dart` captures `initialUri` with `app_links` before Supabase init
- **Google OAuth**: Web → `Uri.base.toString()`. Mobile → `io.supabase.busbooking://login-callback/`
- **Trip states**: `scheduled` → `in_progress` → `completed` / `cancelled`. Booking screens block `in_progress`/`completed`/`cancelled`
- **Trip auto-completion**: `SupabaseConfig.syncOverdueTrips()` auto-completes timed-out trips (called externally)
- **Driver GPS**: Updates every 15s. Passengers subscribe via Supabase Realtime
- **Conductor**: Must allow trip start when bus not full. Driver can't end trip until bus is full without conductor permission
- **Bakong KHQR**: Bill numbers truncated to 25 chars. `BAKONG_ACCESS_TOKEN` is server-side only (Edge Function secret). SIT sandbox: `https://sit-api-bakong.nbc.org.kh`

## L10n (already set up)

- `l10n.yaml` at root, ARB files in `lib/l10n/` (`app_en.arb`, `app_km.arb`)
- `localeProvider` (Riverpod) with `SharedPreferences` persistence
- `MaterialApp` configured with `AppLocalizations.localizationsDelegates` and `supportedLocales`
- After editing ARB files, run `flutter gen-l10n` to regenerate
- Use `context.tr.xxx` access pattern — see `booking*` keys for plural support

## Testing

- **Framework**: `flutter_test` + `mocktail`
- **Mock helper**: `test/helpers/mock_supabase.dart` — `SupabaseMock` with `MockGoTrueClient`
- **Client override**: `SupabaseConfig.setTestClient(client)` / `clearTestClient()` — `@visibleForTesting`
- Tests are minimal (placeholder `widget_test.dart`)

## Conventions

- **Strings**: Single quotes (`prefer_single_quotes`) — linter enforces this
- **Imports**: Relative over package (`prefer_relative_imports`)
- **Const**: Prefer `const` constructors and declarations
- **Final**: Prefer `final` locals over `var`
- **Printing**: Use `debugPrint`, never `print` — linter enforces `avoid_print`
- **Comments**: Do NOT add comments unless asked
- **SQL migrations**: Run in Supabase SQL Editor or via `supabase db push`. Migrations in `supabase/migrations/`
- **Supabase local dev**: `supabase/` has `config.toml` — supports `supabase start` / `supabase db push`
- **Edge Functions**: 4 functions in `supabase/functions/` — deploy with `supabase functions deploy <name>`
