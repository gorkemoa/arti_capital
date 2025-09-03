import 'package:arti_capital/models/login_models.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({AuthService? authService}) : _authService = authService ?? AuthService();

  final AuthService _authService;

  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final FocusNode userFocusNode = FocusNode();
  final FocusNode passFocusNode = FocusNode();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool get loading => _loading;

  bool _obscure = true;
  bool get obscure => _obscure;

  void toggleObscure() {
    _obscure = !_obscure;
    notifyListeners();
  }

  Future<LoginResponse> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      throw Exception('Form geçersiz');
    }
    _loading = true;
    notifyListeners();
    try {
      final req = LoginRequest(
        userName: userController.text.trim(),
        password: passController.text,
      );
      final resp = await _authService.login(req);
      return resp;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    userFocusNode.dispose();
    passFocusNode.dispose();
    super.dispose();
  }
}


