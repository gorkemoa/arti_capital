import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

import '../models/notification_models.dart';
import 'api_client.dart';
import 'app_constants.dart';
import 'logger.dart';
import 'storage_service.dart';

class NotificationsService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _fcmToken;


  // FCM Token'ı al
  static Future<String?> getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode && _fcmToken != null) {
        AppLogger.i('FCM Token: $_fcmToken', tag: 'FCM_TOKEN');
      }
      return _fcmToken;
    } catch (e) {
      AppLogger.e('FCM Token alınamadı: $e', tag: 'FCM_TOKEN');
      return null;
    }
  }

  // Push bildirim izinlerini iste
  static Future<bool> requestPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.i('Bildirim izni durumu: ${settings.authorizationStatus}', tag: 'FCM_PERMISSION');
      
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      AppLogger.e('Bildirim izni alınamadı: $e', tag: 'FCM_PERMISSION');
      return false;
    }
  }

  // FCM token'ı sunucuya gönder
  static Future<bool> sendTokenToServer() async {
    try {
      final token = await getFCMToken();
      if (token == null) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Foreground mesajlarını dinle
  static void setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Custom bildirim göster
      _showLocalNotification(message);
    });
  }

  // Background mesajlarını dinle
  static Future<void> setupBackgroundMessageHandler() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Background mesaj handler'ı
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Background mesaj işleme
  }

  // Local notifications'ı başlat
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings);
    
    // Android için bildirim kanalı oluştur
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  // Local bildirim göster
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Bildirim',
        message.notification?.body ?? 'Yeni mesaj',
        notificationDetails,
      );
    } catch (e) {
      // Sessizce hata yönetimi
    }
  }

  // Token yenileme dinleyicisi
  static void setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      _fcmToken = token;
      if (kDebugMode) {
        AppLogger.i('FCM Token yenilendi: $token', tag: 'FCM_TOKEN');
      }
      sendTokenToServer();
    });
  }

  // Bildirim tıklama dinleyicisi
  static void setupNotificationTapHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Bildirime tıklandığında yapılacak işlemler
    });
  }

  // Tüm FCM servislerini başlat
  static Future<void> initialize() async {
    try {
      // Local notifications'ı başlat
      await _initializeLocalNotifications();
      
      // İzinleri iste
      await requestPermission();
      
      // Token'ı al
      await getFCMToken();
      
      // Token'ı sunucuya gönder
      await sendTokenToServer();
      
      // Dinleyicileri kur
      setupForegroundMessageHandler();
      setupBackgroundMessageHandler();
      setupTokenRefreshListener();
      setupNotificationTapHandler();
    } catch (e) {
      // Sessizce hata yönetimi
    }
  }

  Future<GetNotificationsResponse> getNotifications() async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return GetNotificationsResponse(
          error: true,
          success: false,
          notifications: const [],
          errorMessage: 'Token bulunamadı',
        );
      }


      final userId = StorageService.getUserId();
      if (userId == null) {
        return GetNotificationsResponse(
          error: true,
          success: false,
          notifications: const [],
          errorMessage: 'Kullanıcı ID bulunamadı',
        );
      }

      final endpoint = AppConstants.getNotificationsFor(userId);

      AppLogger.i('GET $endpoint', tag: 'GET_NOTIFS');

      final resp = await ApiClient.getJson(
        endpoint,
      );

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_NOTIFS');
          return GetNotificationsResponse(
            error: true,
            success: false,
            notifications: const [],
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'GET_NOTIFS');
        return GetNotificationsResponse(
          error: true,
          success: false,
          notifications: const [],
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_NOTIFS');
      AppLogger.i(body.toString(), tag: 'GET_NOTIFS_RES');

      return GetNotificationsResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Get notifications error ${e.statusCode} ${e.message}', tag: 'GET_NOTIFS');
      return GetNotificationsResponse(
        error: true,
        success: false,
        notifications: const [],
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in getNotifications: $e', tag: 'GET_NOTIFS');
      return GetNotificationsResponse(
        error: true,
        success: false,
        notifications: const [],
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<BaseSimpleResponse> allReadNotifications() async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return BaseSimpleResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.allReadNotifications;

      AppLogger.i('PUT $endpoint', tag: 'ALL_READ_NOTIFS');

      final resp = await ApiClient.putJson(endpoint, data: {
        'userToken': token,
      });

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'ALL_READ_NOTIFS');
          return BaseSimpleResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'ALL_READ_NOTIFS');
        return BaseSimpleResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'ALL_READ_NOTIFS');
      AppLogger.i(body.toString(), tag: 'ALL_READ_NOTIFS_RES');

      return BaseSimpleResponse(
        error: body['error'] as bool? ?? false,
        success: body['success'] as bool? ?? false,
        message: (body['success_message'] as String?) ?? (body['error_message'] as String?),
        statusCode: resp.statusCode,
      );
    } on ApiException catch (e) {
      AppLogger.e('All read notifs error ${e.statusCode} ${e.message}', tag: 'ALL_READ_NOTIFS');
      return BaseSimpleResponse(
        error: true,
        success: false,
        message: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in allReadNotifications: $e', tag: 'ALL_READ_NOTIFS');
      return BaseSimpleResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<BaseSimpleResponse> deleteNotification({required int notID}) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return BaseSimpleResponse(error: true, success: false, message: 'Token bulunamadı');
      }

      final endpoint = AppConstants.deleteNotification;
      AppLogger.i('DELETE $endpoint', tag: 'DEL_NOTIF');

      final resp = await ApiClient.deleteJson(endpoint, data: {
        'userToken': token,
        'notID': notID,
      });

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'DEL_NOTIF');
          return BaseSimpleResponse(error: true, success: false, message: 'Sunucudan geçersiz yanıt alındı');
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'DEL_NOTIF');
        return BaseSimpleResponse(error: true, success: false, message: 'Sunucudan beklenmeyen yanıt türü alındı');
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'DEL_NOTIF');
      AppLogger.i(body.toString(), tag: 'DEL_NOTIF_RES');

      return BaseSimpleResponse(
        error: body['error'] as bool? ?? false,
        success: body['success'] as bool? ?? false,
        message: (body['success_message'] as String?) ?? (body['error_message'] as String?),
        statusCode: resp.statusCode,
      );
    } on ApiException catch (e) {
      AppLogger.e('Delete notif error ${e.statusCode} ${e.message}', tag: 'DEL_NOTIF');
      return BaseSimpleResponse(error: true, success: false, message: e.message, statusCode: e.statusCode);
    } catch (e) {
      AppLogger.e('Unexpected error in deleteNotification: $e', tag: 'DEL_NOTIF');
      return BaseSimpleResponse(error: true, success: false, message: 'Beklenmeyen bir hata oluştu');
    }
  }

  Future<BaseSimpleResponse> deleteAllNotifications() async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return BaseSimpleResponse(error: true, success: false, message: 'Token bulunamadı');
      }

      final endpoint = AppConstants.deleteAllNotifications;
      AppLogger.i('PUT $endpoint', tag: 'DEL_ALL_NOTIF');

      final resp = await ApiClient.deleteJson(endpoint, data: {
        'userToken': token,
      });

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'DEL_ALL_NOTIF');
          return BaseSimpleResponse(error: true, success: false, message: 'Sunucudan geçersiz yanıt alındı');
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'DEL_ALL_NOTIF');
        return BaseSimpleResponse(error: true, success: false, message: 'Sunucudan beklenmeyen yanıt türü alındı');
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'DEL_ALL_NOTIF');
      AppLogger.i(body.toString(), tag: 'DEL_ALL_NOTIF_RES');

      return BaseSimpleResponse(
        error: body['error'] as bool? ?? false,
        success: body['success'] as bool? ?? false,
        message: (body['success_message'] as String?) ?? (body['error_message'] as String?),
        statusCode: resp.statusCode,
      );
    } on ApiException catch (e) {
      AppLogger.e('Delete all notifs error ${e.statusCode} ${e.message}', tag: 'DEL_ALL_NOTIF');
      return BaseSimpleResponse(error: true, success: false, message: e.message, statusCode: e.statusCode);
    } catch (e) {
      AppLogger.e('Unexpected error in deleteAllNotifications: $e', tag: 'DEL_ALL_NOTIF');
      return BaseSimpleResponse(error: true, success: false, message: 'Beklenmeyen bir hata oluştu');
    }
  }
 } 

