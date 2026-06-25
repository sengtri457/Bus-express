import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error/result.dart';
import '../models/user_model.dart';
import 'base_repository.dart';

class AuthRepository extends BaseRepository {
  AuthRepository() : super('users');

  Future<Result<UserModel>> loginWithEmail(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) return const Failure('No user returned');

      final data = await client
          .from('users')
          .select('role, status')
          .eq('id', user.id)
          .single();
      final status = data['status'] as String?;
      if (status == 'suspended') {
        await client.auth.signOut();
        return const Failure('Account suspended');
      }
      final userData = await client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      return Success(UserModel.fromMap(userData));
    } on AuthException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Login failed', error: e);
    }
  }

  Future<Result<UserModel>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
      );
      final user = response.user;
      if (user == null) return const Failure('Sign up failed');

      final data = await client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      return Success(UserModel.fromMap(data));
    } on AuthException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Sign up failed', error: e);
    }
  }

  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo:
            kIsWeb ? Uri.base.toString() : 'io.supabase.busbooking://login-callback/',
      );

      final user = client.auth.currentUser;
      if (user == null) return const Failure('Google sign in failed');

      final existing = await client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        await client.from('users').insert({
          'id': user.id,
          'name': user.userMetadata?['full_name'] ?? 'User',
          'email': user.email,
          'role': 'passenger',
          'status': 'active',
        });
        return Success(UserModel(
          id: user.id,
          name: user.userMetadata?['full_name'] ?? 'User',
          email: user.email,
          role: 'passenger',
          status: 'active',
        ));
      }

      return Success(UserModel.fromMap(existing));
    } catch (e) {
      return Failure('Google sign in failed', error: e);
    }
  }

  Future<Result<void>> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
      return const Success(null);
    } on AuthException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Reset password failed', error: e);
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await client.auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure('Sign out failed', error: e);
    }
  }

  UserModel? get currentUser {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.userMetadata?['name'] as String?,
    );
  }
}
