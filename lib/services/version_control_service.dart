import 'package:new_version_plus/new_version_plus.dart';
import 'package:flutter/material.dart';

class VersionControlService {
  static final VersionControlService _instance = VersionControlService._internal();

  factory VersionControlService() {
    return _instance;
  }

  VersionControlService._internal();

  final NewVersionPlus _newVersion = NewVersionPlus(
    iOSId: 'com.office701.arti_capital',
    androidId: 'com.office701.arti_capital',
  );

  /// Yeni versiyon kontrolü yapan ve sonucu döndüren metod
  Future<VersionStatus?> checkForNewVersion() async {
    try {
      final status = await _newVersion.getVersionStatus();
      return status;
    } catch (e) {
      debugPrint('Version check error: $e');
      return null;
    }
  }

  /// Platform-specific alert'i otomatik gösterir
  Future<void> showUpdateAlert(BuildContext context) async {
    try {
      await _newVersion.showAlertIfNecessary(context: context);
    } catch (e) {
      debugPrint('Show alert error: $e');
    }
  }

  /// Custom dialog göstermek için versiyon bilgisi alır
  Future<VersionStatus?> getVersionStatus() async {
    try {
      return await _newVersion.getVersionStatus();
    } catch (e) {
      debugPrint('Get version status error: $e');
      return null;
    }
  }

  /// Custom dialog gösterir
  Future<void> showCustomUpdateDialog(
    BuildContext context, {
    required VersionStatus versionStatus,
    String? dialogTitle,
    String? dialogText,
    String? updateButtonText,
    String? dismissButtonText,
    VoidCallback? dismissAction,
  }) async {
    try {
      _newVersion.showUpdateDialog(
        context: context,
        versionStatus: versionStatus,
        dialogTitle: dialogTitle ?? 'Yeni Versiyon Kullanılabilir',
        dialogText: dialogText ?? 'Lütfen uygulamayı güncelleyin',
        updateButtonText: updateButtonText ?? 'Güncelle',
        dismissButtonText: dismissButtonText ?? 'Kapat',
        dismissAction: dismissAction,
      );
    } catch (e) {
      debugPrint('Show custom dialog error: $e');
    }
  }
}
