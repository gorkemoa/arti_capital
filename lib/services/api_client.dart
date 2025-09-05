import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'logger.dart';
import 'app_constants.dart';
import 'storage_service.dart';

class ApiClient {
  ApiClient._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': _basicAuthHeader(),
      },
    ),
  );

  static void initInterceptors() {
    // Tek sefer kurulması yeterli
    if (_dio.interceptors.isEmpty) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            AppLogger.i('${options.method} ${options.uri}', tag: 'REQ');
            if (options.data != null) {
              AppLogger.i(options.data.toString(), tag: 'REQ_BODY');
            }
            handler.next(options);
          },
          onResponse: (response, handler) {
            AppLogger.i('${response.statusCode} ${response.requestOptions.uri}', tag: 'RES');
            handler.next(response);
          },
          onError: (DioException e, handler) {
            AppLogger.e('${e.response?.statusCode} ${e.requestOptions.uri}', tag: 'ERR');
            
            // 403 hatası durumunda kullanıcıyı login sayfasına yönlendir
            if (e.response?.statusCode == 403) {
              _handle403Error();
            }
            
            handler.next(e);
          },
        ),
      );
    }
  }

  static String _basicAuthHeader() {
    final raw = '${AppConstants.basicUsername}:${AppConstants.basicPassword}';
    final encoded = base64Encode(utf8.encode(raw));
    return 'Basic $encoded';
  }

  static void _handle403Error() async {
    try {
      AppLogger.i('403 hatası tespit edildi - kullanıcı başka yerde oturum açmış', tag: 'AUTH');
      
      // Kullanıcı verilerini temizle
      await StorageService.clearUserData();
      
      // Login sayfasına yönlendir
      final context = _navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      AppLogger.e('403 hata yönetimi sırasında hata: $e', tag: 'AUTH');
    }
  }

  // Global navigator key - main.dart'ta tanımlanacak
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  static Future<Response<T>> postJson<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
  }) async {
    try {
      initInterceptors();
      final resp = await _dio.post<T>(
        path,
        queryParameters: query,
        data: data,
      );
      return resp;
    } on DioException catch (e) {
      if (e.response != null) {
        final status = e.response?.statusCode;
        final body = e.response?.data;
        String? msg;
        if (status == 417 && body is Map<String, dynamic>) {
          // Backend'in gönderdiği error_message'ı çıkar
          msg = body['error_message'] as String?;
        }
        throw ApiException(
          statusCode: status,
          data: body,
          message: msg ?? e.message,
        );
      }
      throw ApiException(message: e.message);
    }
  }

  static Future<Response<T>> putJson<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
  }) async {
    try {
      initInterceptors();
      final resp = await _dio.put<T>(
        path,
        queryParameters: query,
        data: data,
      );
      return resp;
    } on DioException catch (e) {
      if (e.response != null) {
        final status = e.response?.statusCode;
        final body = e.response?.data;
        String? msg;
        if (status == 417 && body is Map<String, dynamic>) {
          // Backend'in gönderdiği error_message'ı çıkar
          msg = body['error_message'] as String?;
        }
        throw ApiException(
          statusCode: status,
          data: body,
          message: msg ?? e.message,
        );
      }
      throw ApiException(message: e.message);
    }
  }

  static Future<Response<T>> getJson<T>(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      initInterceptors();
      final resp = await _dio.get<T>(
        path,
        queryParameters: query,
      );
      return resp;
    } on DioException catch (e) {
      if (e.response != null) {
        final status = e.response?.statusCode;
        final body = e.response?.data;
        String? msg;
        if (status == 417 && body is Map<String, dynamic>) {
          // Backend'in gönderdiği error_message'ı çıkar
          msg = body['error_message'] as String?;
        }
        throw ApiException(
          statusCode: status,
          data: body,
          message: msg ?? e.message,
        );
      }
      throw ApiException(message: e.message);
    }
  }
}

class ApiException implements Exception {
  final int? statusCode;
  final dynamic data;
  final String? message;

  ApiException({this.statusCode, this.data, this.message});

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message, data: $data)';
}


