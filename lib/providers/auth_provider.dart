import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error/result.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

final authStateProvider = StreamProvider<UserModel?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((event) {
    final supabaseUser = event.session?.user;
    if (supabaseUser == null) return null;
    return UserModel(
      id: supabaseUser.id,
      email: supabaseUser.email,
      name: supabaseUser.userMetadata?['name'] as String?,
    );
  });
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final supabaseUser = Supabase.instance.client.auth.currentUser;
  if (supabaseUser == null) return null;
  final userRepo = ref.watch(userRepositoryProvider);
  final result = await userRepo.getCurrentUser(supabaseUser.id);
  return result is Success<UserModel> ? result.data : null;
});

final loginProvider = FutureProvider.family<UserModel, LoginParams>(
  (ref, params) async {
    final authRepo = ref.watch(authRepositoryProvider);
    final result = await authRepo.loginWithEmail(params.email, params.password);
    if (result is Success<UserModel>) return result.data;
    throw Exception((result as Failure).message);
  },
);

final signUpProvider = FutureProvider.family<UserModel, SignUpParams>(
  (ref, params) async {
    final authRepo = ref.watch(authRepositoryProvider);
    final result = await authRepo.signUp(
      email: params.email,
      password: params.password,
      name: params.name,
      phone: params.phone,
    );
    if (result is Success<UserModel>) return result.data;
    throw Exception((result as Failure).message);
  },
);

class LoginParams {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});
}

class SignUpParams {
  final String email;
  final String password;
  final String name;
  final String phone;
  const SignUpParams({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
  });
}
