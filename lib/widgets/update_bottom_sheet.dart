import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateBottomSheet extends StatelessWidget {
  final VersionStatus versionStatus;
  final VoidCallback? onDismiss;
  final bool isMandatory;

  const UpdateBottomSheet({
    super.key,
    required this.versionStatus,
    this.onDismiss,
    this.isMandatory = false,
  });

  /// Bottom sheet'i gösterir
  static Future<void> show(
    BuildContext context, {
    required VersionStatus versionStatus,
    bool isMandatory = false,
    VoidCallback? onDismiss,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: !isMandatory,
      enableDrag: !isMandatory,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => UpdateBottomSheet(
        versionStatus: versionStatus,
        onDismiss: onDismiss,
        isMandatory: isMandatory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async => !isMandatory,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.system_update,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yeni Versiyon Kullanılabilir',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${versionStatus.localVersion} → ${versionStatus.storeVersion}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isMandatory
                              ? 'Bu güncelleme zorunludur. Lütfen güncellemek için uygulamayı ziyaret edin.'
                              : 'Yeni özellikler ve iyileştirmeler için uygulamayı güncelleyin.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // What's New Section
                Text(
                  'Bu Sürümde Neler Var',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WhatsNewItem(
                        icon: Icons.check_circle_outline,
                        text: 'Yeni özellikler ve iyileştirmeler',
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 8),
                      _WhatsNewItem(
                        icon: Icons.construction_outlined,
                        text: 'Hata düzeltmeleri',
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 8),
                      _WhatsNewItem(
                        icon: Icons.speed,
                        text: 'Performans iyileştirmeleri',
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    if (!isMandatory)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDismiss?.call();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: colorScheme.outline.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Daha Sonra',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (!isMandatory) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _launchAppStore(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.download,
                              size: 18,
                              color: colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Güncelle',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchAppStore(BuildContext context) async {
    try {
      if (versionStatus.appStoreLink.isNotEmpty) {
        if (await canLaunchUrl(Uri.parse(versionStatus.appStoreLink))) {
          await launchUrl(
            Uri.parse(versionStatus.appStoreLink),
            mode: LaunchMode.externalApplication,
          );
          if (!isMandatory && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      debugPrint('Error launching app store: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uygulama mağazası açılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _WhatsNewItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;

  const _WhatsNewItem({
    required this.icon,
    required this.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
