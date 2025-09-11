import 'dart:io';

import 'package:flutter/services.dart';

class AppGroupService {
  AppGroupService._();

  static const MethodChannel _channel = MethodChannel('app_group_prefs');

  static const String _groupId = 'group.com.office701.articapital';

  static Future<bool> setLoggedInUserName(String userName) async {
    if (!Platform.isIOS) return false;
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
}


