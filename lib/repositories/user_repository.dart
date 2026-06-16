import '../core/error/result.dart';
import '../models/user_model.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  UserRepository() : super('users');

  Future<Result<UserModel>> getCurrentUser(String userId) async {
    try {
      final data = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return Success(UserModel.fromMap(data));
    } catch (e) {
      return Failure('Failed to load user', error: e);
    }
  }

  Future<Result<void>> updateProfile({
    required String userId,
    String? name,
    String? phone,
    int? age,
    String? nationality,
  }) async {
    try {
      await client.from('users').update({
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (age != null) 'age': age,
        if (nationality != null) 'nationality': nationality,
      }).eq('id', userId);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to update profile', error: e);
    }
  }

  Future<Result<List<UserModel>>> getStaffByOperator(
    String operatorId, {
    String? role,
  }) async {
    try {
      var query = client
          .from('users')
          .select('id, name, email, phone, role, status')
          .eq('operator_id', operatorId)
          .neq('role', 'passenger');
      if (role != null) {
        query = query.eq('role', role);
      }
      final data = await query.order('created_at', ascending: false);
      return Success(data.map((e) => UserModel.fromMap(e)).toList());
    } catch (e) {
      return Failure('Failed to load staff', error: e);
    }
  }

  Future<Result<List<UserModel>>> getAllUsers() async {
    try {
      final data = await client
          .from('users')
          .select('id, name, email, phone, role, status, created_at, operator_id')
          .order('created_at', ascending: false);
      return Success(data.map((e) => UserModel.fromMap(e)).toList());
    } catch (e) {
      return Failure('Failed to load users', error: e);
    }
  }

  Future<Result<void>> updateUserStatus(
    String userId,
    String status,
  ) async {
    try {
      await client
          .from('users')
          .update({'status': status})
          .eq('id', userId);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to update user status', error: e);
    }
  }
}
