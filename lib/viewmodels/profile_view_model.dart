import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _user;
  bool _loading = true;
  String? _errorMessage;

  User? get user => _user;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  ProfileViewModel() {
    _load();
  }

  Future<void> _load() async {
    try {
      _loading = true;
      notifyListeners();
      final resp = await _userService.getUser();
      if (resp.success && resp.user != null) {
        _user = resp.user;
        _errorMessage = null;
      } else {
        _user = null;
        _errorMessage = resp.errorMessage;
      }
    } catch (e) {
      _user = null;
      _errorMessage = 'Bir hata oluştu: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}


