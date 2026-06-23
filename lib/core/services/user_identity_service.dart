import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserIdentityService {
  UserIdentityService._();

  static final UserIdentityService instance = UserIdentityService._();
  static const _storageKey = 'booking_user_id';
  static const _legacyStorageKey = 'favorites_user_id';
  static const Uuid _uuid = Uuid();

  String? _cachedUserId;

  Future<String> getUserId() async {
    final cachedUserId = _cachedUserId;
    if (cachedUserId != null && cachedUserId.isNotEmpty) {
      return cachedUserId;
    }

    final preferences = await SharedPreferences.getInstance();
    final storedUserId = preferences.getString(_storageKey) ??
        preferences.getString(_legacyStorageKey);
    if (storedUserId != null && storedUserId.isNotEmpty) {
      _cachedUserId = storedUserId;
      await preferences.setString(_storageKey, storedUserId);
      return storedUserId;
    }

    final generatedUserId = _uuid.v4();
    await preferences.setString(_storageKey, generatedUserId);
    _cachedUserId = generatedUserId;
    return generatedUserId;
  }
}
