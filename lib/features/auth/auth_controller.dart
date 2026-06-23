import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isLoggedIn => _isAuthenticated;

  bool login(String password) {
    if (password == 'timur') {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
