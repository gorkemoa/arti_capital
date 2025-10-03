import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _tokenKey = 'user_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';
  static const String _twoFactorEnabledKey = 'two_factor_enabled';
  static const String _twoFactorSendTypeKey = 'two_factor_send_type';
  static const String _lastLoginAtKey = 'last_login_at';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token işlemleri
  static Future<void> saveToken(String token) async {
    await _prefs?.setString(_tokenKey, token);
  }

  static String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  static Future<void> removeToken() async {
    await _prefs?.remove(_tokenKey);
  }

  // User ID işlemleri
  static Future<void> saveUserId(int userId) async {
    await _prefs?.setInt(_userIdKey, userId);
  }

  static int? getUserId() {
    return _prefs?.getInt(_userIdKey);
  }

  static Future<void> removeUserId() async {
    await _prefs?.remove(_userIdKey);
  }

  // User data işlemleri
  static Future<void> saveUserData(String userData) async {
    await _prefs?.setString(_userDataKey, userData);
  }

  static String? getUserData() {
    final data = _prefs?.getString(_userDataKey);
    
    // Eski format kontrolü - eğer parse edilemiyorsa temizle
    if (data != null) {
      try {
        jsonDecode(data);
      } catch (e) {
        print('[STORAGE] Invalid user data format detected, clearing...');
        _prefs?.remove(_userDataKey);
        return null;
      }
    }
    
    return data;
  }

  static Future<void> removeUserData() async {
    await _prefs?.remove(_userDataKey);
  }

  // Tüm kullanıcı verilerini temizle
  static Future<void> clearUserData() async {
    await removeToken();
    await removeUserId();
    await removeUserData();
    await removeLastLoginAt();
  }

  // Kullanıcı giriş yapmış mı kontrol et
  static bool isLoggedIn() {
    return getToken() != null && getUserId() != null;
  }

  // 2FA Ayarları
  static Future<void> saveTwoFactorEnabled(bool enabled) async {
    await _prefs?.setBool(_twoFactorEnabledKey, enabled);
  }

  static bool isTwoFactorEnabled() {
    return _prefs?.getBool(_twoFactorEnabledKey) ?? false;
  }

  static Future<void> saveTwoFactorSendType(int sendType) async {
    await _prefs?.setInt(_twoFactorSendTypeKey, sendType);
  }

  static int getTwoFactorSendType() {
    return _prefs?.getInt(_twoFactorSendTypeKey) ?? 1;
  }

  // Last login time helpers
  static Future<void> saveLastLoginAt(DateTime dateTime) async {
    await _prefs?.setString(_lastLoginAtKey, dateTime.toIso8601String());
  }

  static DateTime? getLastLoginAt() {
    final value = _prefs?.getString(_lastLoginAtKey);
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeLastLoginAt() async {
    await _prefs?.remove(_lastLoginAtKey);
  }

  // Permission helpers - check user permissions (PHP isset logic)
  static bool hasPermission(String module, String action) {
    final userData = getUserData();
    if (userData == null) return false;
    
    try {
      final Map<String, dynamic> json = jsonDecode(userData);
      final permissions = json['userPermissions'] as Map<String, dynamic>?;
      if (permissions == null) return false;
      
      final modulePerms = permissions[module];
      if (modulePerms == null || modulePerms is! Map<String, dynamic>) return false;
      
      final actionPerm = modulePerms[action];
      return actionPerm == 'true' || actionPerm == true;
    } catch (e) {
      // Eski formatta kaydedilmiş veri varsa temizle
      print('[PERMISSION_CHECK] Invalid user data format, please logout and login again. Error: $e');
      return false;
    }
  }
}





