import 'package:flutter/material.dart';
import '../models/project_models.dart';
import '../services/projects_service.dart';
import '../theme/app_colors.dart';
import 'edit_tracking_view.dart';

class TrackingDetailView extends StatefulWidget {
  final ProjectTracking tracking;
  final String projectTitle;
  final int projectID;
  final int compID;

  const TrackingDetailView({
    super.key,
    required this.tracking,
    required this.projectTitle,
    required this.projectID,
    required this.compID,
  });

  @override
  State<TrackingDetailView> createState() => _TrackingDetailViewState();
}

class _TrackingDetailViewState extends State<TrackingDetailView> {
  late ProjectTracking _tracking;
  final ProjectsService _service = ProjectsService();

  @override
  void initState() {
    super.initState();
    _tracking = widget.tracking;
  }

  Color _parseHexColor(String hexColor) {
    try {
      if (hexColor.startsWith('#')) {
        return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
      }
      return AppColors.primary;
    } catch (_) {
      return AppColors.primary;
    }
  }

  String _formatNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'push':
        return 'Push Bildirim';
      case 'email':
        return 'E-posta';
      case 'sms':
        return 'SMS';
      case 'all':
        return 'Tümü (Push, E-posta, SMS)';
      default:
        return type;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'push':
        return Icons.notifications;
      case 'email':
        return Icons.mail;
      case 'sms':
        return Icons.sms;
      case 'all':
        return Icons.hub;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _openEditPage() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditTrackingView(
          tracking: _tracking,
          projectID: widget.projectID,
          compID: widget.compID,
          projectTitle: widget.projectTitle,
        ),
      ),
    );

    if (result == true) {
      // After successful update, show success message and go back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Takip başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _deleteTracking() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      final response = await _service.deleteTracking(
        appID: widget.projectID,
        trackID: _tracking.trackID,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog'u kapat

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Takip başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Önceki sayfaya dön
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Takip silinemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog'u kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text('Takip Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_tracking.trackTitle}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bu takibi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
              style: TextStyle(
                color: AppColors.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color typeColorBg = _parseHexColor(_tracking.typeColorBg);
    Color statusColor = _parseHexColor(_tracking.statusColor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takip Detayı'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  _openEditPage();
                } else if (value == 'delete') {
                  _showDeleteConfirmation();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20 , color: AppColors.onSurface),
                      SizedBox(width: 12),
                      Text('Düzenle'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Sil', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Proje Başlığı
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proje',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.projectTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Durum ve Tip Badges
            Row(
              children: [
                Expanded(
                  child: _buildStatusBadge(
                    theme,
                    'Durum',
                    _tracking.statusName,
                    statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeBadge(
                    theme,
                    'Tip',
                    _tracking.trackTypeName,
                    typeColorBg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Başlık
            _buildSection(
              title: 'Başlık',
              child: Container(
                padding: const EdgeInsets.all(12),

                child: Text(
                  _tracking.trackTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              theme: theme,
            ),
            const SizedBox(height: 16),

            // Açıklama
            _buildSection(
              title: 'Açıklama',
              child: Container(
                padding: const EdgeInsets.all(12),

                child: Text(
                  _tracking.trackDesc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ),
              theme: theme,
            ),
            const SizedBox(height: 16),

            // Tarihler
            _buildSection(
              title: 'Tarihler',
              child: Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Bitiş Tarihi',
                      value: _tracking.trackDueDate,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailRow(
                      icon: Icons.notifications_outlined,
                      label: 'Hatırlatma Tarihi',
                      value: _tracking.trackRemindDate,
                      theme: theme,
                    ),
                  ),
                ],
              ),
              theme: theme,
            ),
            const SizedBox(height: 16),

            // Atanan Kişi
            _buildSection(
              title: 'Atanan Kişi',
              child: Container(
                padding: const EdgeInsets.all(12),
                
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _tracking.assignedUserNames,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              theme: theme,
            ),
            if (_tracking.notificationTypes.isNotEmpty) ...[
              const SizedBox(height: 16),
              // Bildirim Türü
              _buildSection(
                title: 'Bildirim Türleri',
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tracking.notificationTypes.map((type) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getNotificationIcon(type),
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatNotificationType(type),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                theme: theme,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildStatusBadge(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurface.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurface.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.onSurface.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
