import 'package:flutter/foundation.dart';
import 'package:razak_travel/data/repositories/admin_repository.dart';

class AuthController extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isLoggedIn => _isAuthenticated;

  Future<bool> login(String password) async {
    final valid = await AdminRepository().verifyPassword(password);
    if (valid) {
      _isAuthenticated = true;
      notifyListeners();
    }
    return valid;
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
