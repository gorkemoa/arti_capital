import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'user_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';

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
    return _prefs?.getString(_userDataKey);
  }

  static Future<void> removeUserData() async {
    await _prefs?.remove(_userDataKey);
  }

  // Tüm kullanıcı verilerini temizle
  static Future<void> clearUserData() async {
    await removeToken();
    await removeUserId();
    await removeUserData();
  }

  // Kullanıcı giriş yapmış mı kontrol et
  static bool isLoggedIn() {
    return getToken() != null && getUserId() != null;
  }
}





