import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'logger.dart';

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static bool _initialized = false;

  /// Remote Config'i başlat
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Varsayılan değerleri ÖNCE ayarla
      await _remoteConfig.setDefaults(const {
        'nace_codes_url': 'https://projects.office701.com/arti-capital/upload/static/nace_codes.json',
        'base_url_android': 'https://api.office701.com/arti-capital',
        'base_url_ios': 'https://api.office701.com/arti-capital',
      });

      // Remote Config ayarlarını konfigure et
      // Cache'i disable et, her zaman Firebase'ten çek
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: Duration.zero, // Cache'i tamamen kapat
        ),
      );

      // İlk kez fetch yap - hata olsa bile devam et
      try {
        await _remoteConfig.fetchAndActivate();
        AppLogger.i('Remote Config başarıyla fetch edildi', tag: 'REMOTE_CONFIG');
      } catch (fetchError) {
        AppLogger.e('Remote Config fetch hatası (varsayılanlar kullanılacak): $fetchError', tag: 'REMOTE_CONFIG');
      }

      _initialized = true;
      AppLogger.i('Remote Config başlatıldı', tag: 'REMOTE_CONFIG');
    } catch (e) {
      AppLogger.e('Remote Config başlatılamadı: $e', tag: 'REMOTE_CONFIG');
      _initialized = true; // Varsayılan değerler yine de kullanılacak
    }
  }

  /// Base URL'i platforma göre al (Android/iOS)
  static String getBaseUrl() {
    try {
      String key;
      String defaultUrl = 'https://api.office701.com/arti-capital';
      
      // Platform kontrolü
      if (Platform.isAndroid) {
        key = 'base_url_android';
      } else if (Platform.isIOS) {
        key = 'base_url_ios';
      } else {
        // Diğer platformlar için varsayılan
        return defaultUrl;
      }
      
      final remoteValue = _remoteConfig.getValue(key);
      final value = remoteValue.asString();
      
      if (value.isEmpty) {
        AppLogger.i('Base URL boş, varsayılan kullanılıyor', tag: 'REMOTE_CONFIG');
        return defaultUrl;
      }
      
      return value;
    } catch (e) {
      AppLogger.e('Base URL alınamadı: $e', tag: 'REMOTE_CONFIG');
      return 'https://api.office701.com/arti-capital';
    }
  }

  /// NACE Codes URL'ini al
  static String getNaceCodesUrl() {
    try {
      // getValue kullanarak daha güvenli erişim
      final remoteValue = _remoteConfig.getValue('nace_codes_url');
      final value = remoteValue.asString();
      
      // Boş string kontrol et
      if (value.isEmpty) {
        AppLogger.i('NACE URL boş, varsayılan kullanılıyor', tag: 'REMOTE_CONFIG');
        return '';
      }
      return value;
    } catch (e) {
      AppLogger.e('NACE Codes URL alınamadı: $e', tag: 'REMOTE_CONFIG');
      // Boş string dön
      return '';
    }
  }

  /// Remote Config'i yenile (manuel güncelleme)
  static Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      AppLogger.i('Remote Config yenilendi', tag: 'REMOTE_CONFIG');
    } catch (e) {
      AppLogger.e('Remote Config yenilemesi başarısız: $e', tag: 'REMOTE_CONFIG');
    }
  }

  /// Force refresh - yapılandırma değiştiğinde hemen güncelle (cache'siz)
  static Future<void> forceRefresh() async {
    if (!_initialized) {
      AppLogger.i('Remote Config henüz başlatılmadı, refresh atlanıyor', tag: 'REMOTE_CONFIG');
      return;
    }
    
    try {
      // fetchAndActivate ile hemen güncelle - timeout 5 sn
      final updated = await _remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          AppLogger.i('Remote Config fetch timeout (varsayılanlar kullanılacak)', tag: 'REMOTE_CONFIG');
          return false;
        },
      );
      
      if (updated) {
        AppLogger.i('Remote Config force yenilendi', tag: 'REMOTE_CONFIG');
      }
    } catch (e) {
      // Hata olsa bile devam et, varsayılan değerler kullanılır
      AppLogger.i('Remote Config refresh atlandı (varsayılanlar kullanılıyor): $e', tag: 'REMOTE_CONFIG');
    }
  }

  /// Belirli bir key için string değer al
  static String getString(String key, {String defaultValue = ''}) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      AppLogger.i('String değer alınamadı ($key): $e', tag: 'REMOTE_CONFIG');
      return defaultValue;
    }
  }

  /// Belirli bir key için boolean değer al
  static bool getBool(String key, {bool defaultValue = false}) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      AppLogger.i('Boolean değer alınamadı ($key): $e', tag: 'REMOTE_CONFIG');
      return defaultValue;
    }
  }

  /// Belirli bir key için integer değer al
  static int getInt(String key, {int defaultValue = 0}) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      AppLogger.i('Integer değer alınamadı ($key): $e', tag: 'REMOTE_CONFIG');
      return defaultValue;
    }
  }

  /// Belirli bir key için double değer al
  static double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      AppLogger.i('Double değer alınamadı ($key): $e', tag: 'REMOTE_CONFIG');
      return defaultValue;
    }
  }
}
