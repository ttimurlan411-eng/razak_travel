import 'package:razak_travel/core/services/supabase_service.dart';

class AdminRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<bool> verifyPassword(String password) async {
    final result = await _supabase.client.rpc(
      'verify_admin_password',
      params: <String, dynamic>{'password_in': password},
    );
    return result == true;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _supabase.client.rpc(
      'change_admin_password',
      params: <String, dynamic>{
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
    return result == true;
  }
}
