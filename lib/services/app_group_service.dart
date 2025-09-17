import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class AppGroupService {
  AppGroupService._();

  static const MethodChannel _channel = MethodChannel('app_group_prefs');

  static const String _groupId = 'group.com.office701.articapital';

  // Share Extension -> Host app JSON payload okuma
  static Future<Map<String, dynamic>?> readSharePayload() async {
    if (!(Platform.isIOS || Platform.isAndroid)) return null;
    try {
      final String? raw = await _channel.invokeMethod('getString', {
        'group': _groupId,
        'key': 'ShareMediaJSON',
      });
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Paylaşım payload'ını temizle (işlendikten sonra)
  static Future<void> clearSharePayload() async {
    if (!(Platform.isIOS || Platform.isAndroid)) return;
    try {
      await _channel.invokeMethod('remove', {
        'group': _groupId,
        'key': 'ShareMediaJSON',
      });
    } catch (_) {}
  }

  static Future<bool> setLoggedInUserName(String userName) async {
    if (!(Platform.isIOS || Platform.isAndroid)) return false;
    if (userName.trim().isEmpty) return false;
    try {
      final bool result = await _channel.invokeMethod('setString', {
        'group': _groupId,
        'key': 'LoggedInUserName',
        'value': userName.trim(),
      });
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setUserRank(String rank) async {
    if (!(Platform.isIOS || Platform.isAndroid)) return false;
    try {
      final bool result = await _channel.invokeMethod('setString', {
        'group': _groupId,
        'key': 'UserRank',
        'value': rank,
      });
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setCompanies(List<String> companies) async {
    if (!(Platform.isIOS || Platform.isAndroid)) return false;
    try {
      final bool result = await _channel.invokeMethod('setString', {
        'group': _groupId,
        'key': 'Companies',
        'value': companies.join('|'),
      });
      return result;
    } catch (_) {
      return false;
    }
  }
}


