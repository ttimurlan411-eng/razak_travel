import 'package:razak_travel/core/services/supabase_service.dart';
import 'package:razak_travel/data/models/user_model.dart';

class UserRepository {
  UserRepository()
      : _supabase = SupabaseService.instance;

  final SupabaseService _supabase;

  Future<UserModel> ensureUserExists({
    required String uid,
    required String email,
  }) async {
    final userId = uid.trim();
    final userEmail = email.trim();

    if (userId.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'User id cannot be empty.');
    }

    if (userEmail.isEmpty) {
      throw ArgumentError.value(email, 'email', 'Email cannot be empty.');
    }

    final existing = await _supabase.querySingleEq(
      _supabase.client.from('users'),
      'id',
      userId,
    );

    if (existing == null) {
      final user = UserModel(
        id: userId,
        email: userEmail,
      );
      await _supabase.insert(
        _supabase.client.from('users'),
        {'id': userId, ...user.toJson()},
      );
      return user;
    }

    return UserModel.fromMap(userId, existing);
  }

  Future<UserModel?> getUserById(String uid) async {
    final userId = uid.trim();
    if (userId.isEmpty) {
      return null;
    }

    final data = await _supabase.querySingleEq(
      _supabase.client.from('users'),
      'id',
      userId,
    );

    if (data == null) {
      return null;
    }

    return UserModel.fromMap(userId, data);
  }

  Future<List<UserModel>> getAllUsers() async {
    final data = await _supabase.query(
      _supabase.client.from('users'),
      order: 'email',
    );
    return data.map((json) => UserModel.fromMap(json['id'], json)).toList();
  }

  Future<UserModel> updateUserRole({
    required String userId,
    required UserRole role,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User id cannot be empty.');
    }

    final existing = await _supabase.querySingleEq(
      _supabase.client.from('users'),
      'id',
      normalizedUserId,
    );

    if (existing == null) {
      throw StateError('User not found.');
    }

    final user = UserModel.fromMap(normalizedUserId, existing);
    if (user.role == UserRole.owner && role != UserRole.owner) {
      throw StateError('Owner role cannot be changed.');
    }

    final updatedUser = user.copyWith(role: role);
    await _supabase.update(
      _supabase.client.from('users'),
      updatedUser.toJson(),
      'id',
      normalizedUserId,
    );
    return updatedUser;
  }

  Future<UserModel> updateUserBanStatus({
    required String userId,
    required bool isBanned,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User id cannot be empty.');
    }

    final existing = await _supabase.querySingleEq(
      _supabase.client.from('users'),
      'id',
      normalizedUserId,
    );

    if (existing == null) {
      throw StateError('User not found.');
    }

    final user = UserModel.fromMap(normalizedUserId, existing);
    if (user.role == UserRole.owner && isBanned) {
      throw StateError('Owner cannot be banned.');
    }

    final updatedUser = user.copyWith(isBanned: isBanned);
    await _supabase.update(
      _supabase.client.from('users'),
      updatedUser.toJson(),
      'id',
      normalizedUserId,
    );
    return updatedUser;
  }
}
