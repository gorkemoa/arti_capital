import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  User? _user;
  bool _loading = true;
  String? _errorMessage;
  int _currentIndex = 0; // Varsayılan: Panel

  User? get user => _user;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  int get currentIndex => _currentIndex;

  HomeViewModel() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      _loading = true;
      notifyListeners();

      // Önce kayıtlı kullanıcı verilerini kontrol et
      final savedUserData = StorageService.getUserData();
      if (savedUserData != null) {
        // JSON string'i parse etmeye çalış
        try {
          // Bu basit bir yaklaşım, gerçek uygulamada daha güvenli JSON parsing kullanılmalı
          // Şimdilik API'den fresh data alalım
        } catch (e) {
          // JSON parse hatası, API'den fresh data al
        }
      }

      // API'den fresh kullanıcı verilerini al
      final response = await _userService.getUser();
      
      if (response.success && response.user != null) {
        _user = response.user;
        _errorMessage = null;
      } else {
        _errorMessage = response.errorMessage ?? 'Kullanıcı bilgileri alınamadı';
        _user = null;
      }
    } catch (e) {
      _errorMessage = 'Bir hata oluştu: $e';
      _user = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<void> refresh() async {
    await _loadUserData();
  }

  void setCurrentIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }
}
