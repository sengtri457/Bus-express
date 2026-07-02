import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Re-export so test files can use Supabase types
export 'package:supabase_flutter/supabase_flutter.dart' show
  SupabaseClient,
  User,
  AuthResponse,
  AuthException,
  GoTrueClient;

// ── Mocktail mocks for GoTrue (auth) ──

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockSession extends Mock implements Session {}

/// Pre-built mock for auth.
///
/// ```dart
/// final mock = SupabaseMock();
/// // mock.auth will have default mocktail behavior
/// ```
class SupabaseMock {
  late final MockGoTrueClient auth;

  SupabaseMock() {
    auth = MockGoTrueClient();
  }
}
