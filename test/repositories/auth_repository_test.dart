import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bus_express/core/error/result.dart';
import 'package:bus_express/models/user_model.dart';
import 'package:bus_express/repositories/auth_repository.dart';
import 'package:bus_express/supabase_config.dart';
import '../helpers/mock_supabase.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthRepository repo;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);

    SupabaseConfig.setTestClient(mockClient);
    repo = AuthRepository();
  });

  tearDown(() {
    SupabaseConfig.clearTestClient();
  });

  User _fakeUser({required String id, String? email, String? name}) {
    final u = MockUser();
    when(() => u.id).thenReturn(id);
    when(() => u.email).thenReturn(email);
    when(() => u.userMetadata)
        .thenReturn(name != null ? {'name': name} : null);
    return u;
  }

  AuthResponse _authRes({User? user}) {
    final r = MockAuthResponse();
    when(() => r.user).thenReturn(user);
    when(() => r.session).thenReturn(null);
    return r;
  }

  group('loginWithEmail', () {
    test('returns Failure on AuthException', () async {
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(const AuthException('Invalid credentials'));

      final result = await repo.loginWithEmail('bad@test.com', 'wrong');
      expect(result, isA<Failure<UserModel>>());
      expect((result as Failure).message, 'Invalid credentials');
    });

    test('returns Failure when no user returned', () async {
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => _authRes(user: null));

      final result = await repo.loginWithEmail('x@x.com', 'p');
      expect(result, isA<Failure>());
    });

    test('returns Failure when query errors', () async {
      final fakeUser = _fakeUser(id: 'u1', email: 's@t.com');
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => _authRes(user: fakeUser));

      // Make the users query fail
      when(() => mockClient.from(any())).thenThrow(Exception('DB error'));

      final result = await repo.loginWithEmail('s@t.com', 'pass');
      expect(result, isA<Failure>());
    });
  });

  group('signUp', () {
    test('returns Failure when null user', () async {
      when(() => mockAuth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => _authRes(user: null));

      final r = await repo.signUp(
        email: 'n@n.com', password: 'p', name: 'N', phone: '0',
      );
      expect(r, isA<Failure>());
    });
  });

  group('resetPassword', () {
    test('returns Success', () async {
      when(() => mockAuth.resetPasswordForEmail(any()))
          .thenAnswer((_) async {});
      expect(await repo.resetPassword('t@t.com'), isA<Success<void>>());
    });

    test('returns Failure', () async {
      when(() => mockAuth.resetPasswordForEmail(any()))
          .thenThrow(const AuthException('err'));
      expect(await repo.resetPassword('x@x.com'), isA<Failure>());
    });
  });

  group('signOut', () {
    test('returns Success', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      expect(await repo.signOut(), isA<Success<void>>());
    });
  });

  group('currentUser', () {
    test('returns null when not logged in', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(repo.currentUser, isNull);
    });

    test('returns UserModel when logged in', () {
      final fakeUser = _fakeUser(id: 'u1', email: 't@t.com', name: 'Sokha');
      when(() => mockAuth.currentUser).thenReturn(fakeUser);
      final u = repo.currentUser;
      expect(u?.id, 'u1');
      expect(u?.name, 'Sokha');
    });
  });

}
