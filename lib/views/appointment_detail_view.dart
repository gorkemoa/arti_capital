import 'package:arti_capital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'edit_appointment_view.dart';
import '../services/appointments_service.dart';
import '../services/storage_service.dart';
import '../models/appointment_models.dart';

class AppointmentDetailView extends StatelessWidget {
  const AppointmentDetailView({
    super.key,
    required this.title,
    required this.companyName,
    required this.time,
    required this.statusName,
    required this.statusColor,
    required this.description,
    this.appointmentID,
    this.compID,
    this.titleID,
    this.remindID,
    this.remindTitle,
    this.appointmentDateRaw,
    this.appointmentRemindDate,
    this.statusID,
    this.location,
    this.priority,
    this.priorityName,
    this.priorityColor,
    this.assignedPersonIDs,
    this.assignedPersonNames,
    this.logs,
    this.isAppointment,
    this.trackingType,
    this.trackingTypeColor,
    this.trackingTypeColorBg,
    this.remindDate,
    this.notificationType,
    this.assignedUserNames,
    this.assignedUserIDs,
    this.updatedDate,
  });

  final String title;
  final String companyName;
  final String time;
  final String statusName;
  final Color statusColor;
  final String description;
  final int? appointmentID;
  final int? compID;
  final int? titleID;
  final int? remindID;
  final String? remindTitle;
  final String? appointmentDateRaw;
  final String? appointmentRemindDate;
  final int? statusID;
  final String? location;
  final int? priority;
  final String? priorityName;
  final Color? priorityColor;
  final List<int>? assignedPersonIDs;
  final List<String>? assignedPersonNames;
  final List<AppointmentLog>? logs;
  final bool? isAppointment;
  final String? trackingType;
  final String? trackingTypeColor;
  final String? trackingTypeColorBg;
  final String? remindDate;
  final List<String>? notificationType;
  final String? assignedUserNames;
  final List<String>? assignedUserIDs;
  final String? updatedDate;

  Event _toCalendarEvent() {
    // Zamanı ayırmak için basit ayrıştırma beklenen format: ".. · HH:MM" veya "HH:MM"
    // title ve description'ı ekleyerek temel bir etkinlik oluşturur
    // Not: Uygulamada daha doğru başlangıç/bitiş saatleri varsa burada kullanılabilir
    DateTime now = DateTime.now();
    DateTime start = now;
    DateTime end = now.add(const Duration(hours: 1));
    try {
      final parts = time.split('·');
      final String timePart = parts.length > 1 ? parts[1].trim() : time.trim();
      final tm = timePart.split(':');
      if (tm.length >= 2) {
        final h = int.tryParse(tm[0]) ?? now.hour;
        final m = int.tryParse(tm[1]) ?? now.minute;
        // Eğer gün bilgisi varsa bugünün ayına/yılına göre set etmeyelim; burada sadece saat kullanıyoruz
        start = DateTime(now.year, now.month, now.day, h, m);
        end = start.add(const Duration(hours: 1));
      }
    } catch (_) {}

    return Event(
      title: title,
      description: description.isNotEmpty ? description : companyName,
      location: location?.isNotEmpty == true ? location : companyName,
      startDate: start,
      endDate: end,
      androidParams: const AndroidParams(emailInvites: []),
      iosParams: const IOSParams(reminder: Duration(minutes: 30)),
    );
  }

  static Color _parseColor(String raw) {
    // Parse hex color: #RRGGBB or #AARRGGBB
    final fallback = AppColors.primary;
    final s = raw.trim();
    if (s.isEmpty) return fallback;
    String hex = s.startsWith('#') ? s.substring(1) : s;
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    try {
      final value = int.parse(hex, radix: 16);
      return Color(value);
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = AppColors.primary;
    return Scaffold(
      backgroundColor: AppColors.onPrimary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: const Text(
          'Randevu Detayı',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onPrimary, fontSize: 15),
        ),
        centerTitle: true,
        actions: [
          // Removed edit and delete buttons from AppBar
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: Colors.black),
                              const SizedBox(width: 6),
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusName,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (priorityName != null && priorityName!.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Text("Öncelik:" , style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Text(
                                    priorityName!,
                                    style: TextStyle(
                                      color: priorityColor ?? Colors.grey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _SectionCard(
                leading: const Icon(Icons.apartment, color: Colors.black54),
                title: 'Şirket',
                content: companyName,
              ),

              if (location != null && location!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  leading: const Icon(Icons.location_on_outlined, color: Colors.black54),
                  title: 'Konum',
                  content: location!,
                ),
              ],

              // Reminder information (for appointments)
              if (isAppointment == true) ...[
                if (remindTitle != null && remindTitle!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    leading: const Icon(Icons.notifications_outlined, color: Colors.black54),
                    title: 'Hatırlatma',
                    content: remindTitle!,
                  ),
                ],
                if (appointmentRemindDate != null && appointmentRemindDate!.isNotEmpty && appointmentRemindDate != '30.11.-0001 00:00') ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    leading: const Icon(Icons.access_time_outlined, color: Colors.black54),
                    title: 'Hatırlatma Zamanı',
                    content: appointmentRemindDate!,
                  ),
                ],
                if (assignedPersonNames != null && assignedPersonNames!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    leading: const Icon(Icons.people_outline, color: Colors.black54),
                    title: 'Atanan Kişiler',
                    content: assignedPersonNames!.join(', '),
                  ),
                ],
              ],

              // Tracking fields (only for isAppointment = false)
              if (isAppointment == false) ...[
                if (trackingType != null && trackingType!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 24, height: 24, child: Center(child: Icon(Icons.category_outlined, color: Colors.black54))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Takip Türü',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: trackingTypeColorBg != null 
                                      ? _parseColor(trackingTypeColorBg!)
                                      : AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  trackingType!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: trackingTypeColor != null
                                        ? _parseColor(trackingTypeColor!)
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (remindDate != null && remindDate!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    leading: const Icon(Icons.notifications_outlined, color: Colors.black54),
                    title: 'Hatırlatma Tarihi',
                    content: remindDate!,
                  ),
                ],
                if (assignedUserNames != null && assignedUserNames!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    leading: const Icon(Icons.person_outline, color: Colors.black54),
                    title: 'Atanan Kullanıcılar',
                    content: assignedUserNames!,
                  ),
                ],
                if (notificationType != null && notificationType!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _NotificationTypeCard(types: notificationType!),
                ],
                if (updatedDate != null && updatedDate!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    leading: const Icon(Icons.update_outlined, color: Colors.black54),
                    title: 'Son Güncelleme',
                    content: updatedDate!,
                  ),
                ],
              ],

              const SizedBox(height: 12),
              _SectionCard(
                leading: const Icon(Icons.description_outlined, color: Colors.black54),
                title: 'Açıklama',
                content: description.isNotEmpty ? description : 'Açıklama bulunmuyor.',
                multiline: true,
              ),

              if (logs != null && logs!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _LogsSection(logs: logs!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final event = _toCalendarEvent();
                    await Add2Calendar.addEvent2Cal(event);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Takvime ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              
              // Edit and Delete buttons
              if (appointmentID != null && (compID != null || appointmentID != null))
                const SizedBox(height: 16),
              if (appointmentID != null && (compID != null || appointmentID != null))
                Row(
                  children: [
                    // Edit button (left)
                    if (appointmentID != null && compID != null && StorageService.hasPermission('appointments', 'update'))
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _editAppointment(context),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Güncelle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    
                    // Spacing between buttons
                    if (appointmentID != null && compID != null && StorageService.hasPermission('appointments', 'update') && 
                        appointmentID != null && StorageService.hasPermission('appointments', 'delete'))
                      const SizedBox(width: 12),
                    
                    // Delete button (right)
                    if (appointmentID != null && StorageService.hasPermission('appointments', 'delete'))
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteAppointment(context),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Sil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editAppointment(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditAppointmentView(
          appointmentID: appointmentID!,
          compID: compID!,
          initialTitle: title,
          initialDesc: description,
          initialDateTimeStr: appointmentDateRaw ?? '',
          initialStatusID: statusID,
          initialLocation: location,
          initialPriority: priority,
          initialTitleID: titleID,
          initialRemindID: remindID,
          initialPersonIDs: assignedPersonIDs,
        ),
      ),
    );
    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Randevu güncellendi')),
      );
      // Return to parent with refresh indicator
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteAppointment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Randevuyu Sil'),
        content: const Text('Bu randevuyu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
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

    if (confirmed != true || !context.mounted) return;

    try {
      final service = AppointmentsService();
      final response = await service.deleteAppointment(appointmentID: appointmentID!);

      if (!context.mounted) return;

      if (response.success && !response.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message.isNotEmpty ? response.message : 'Randevu başarıyla silindi')),
        );
        Navigator.of(context).pop(true); // Return true to indicate deletion and refresh needed
      } else {
        // Handle 417 status code and error_message specifically
        String errorMsg = 'Randevu silinirken hata oluştu';
        if (response.statusCode == 417) {
          // For 417 errors, prioritize message field, then errorMessage
          errorMsg = response.message.isNotEmpty 
              ? response.message 
              : (response.errorMessage?.isNotEmpty == true 
                  ? response.errorMessage! 
                  : 'İşlem başarısız oldu (417)');
        } else if (response.errorMessage?.isNotEmpty == true) {
          errorMsg = response.errorMessage!;
        } else if (response.message.isNotEmpty) {
          errorMsg = response.message;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beklenmeyen hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.leading,
    required this.title,
    required this.content,
    this.multiline = false,
  });

  final Widget leading;
  final String title;
  final String content;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, height: 24, child: Center(child: leading)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.35),
                  maxLines: multiline ? null : 2,
                  overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogsSection extends StatelessWidget {
  const _LogsSection({required this.logs});

  final List<AppointmentLog> logs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              const Text(
                'Geçmiş',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...logs.asMap().entries.map((entry) {
            final index = entry.key;
            final log = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 16),
                _LogItem(log: log),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  const _LogItem({required this.log});

  final AppointmentLog log;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                log.logTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              log.logDate,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        if (log.logDesc.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            log.logDesc,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
        ],
        if (log.logUser.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.black54),
              const SizedBox(width: 4),
              Text(
                log.logUser,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _NotificationTypeCard extends StatelessWidget {
  const _NotificationTypeCard({required this.types});

  final List<String> types;

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'push':
        return Icons.notifications_outlined;
      case 'email':
        return Icons.email_outlined;
      case 'sms':
        return Icons.sms_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _getLabel(String type) {
    switch (type.toLowerCase()) {
      case 'push':
        return 'Push Bildirimi';
      case 'email':
        return 'E-posta';
      case 'sms':
        return 'SMS';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 24, height: 24, child: Center(child: Icon(Icons.notifications_active_outlined, color: Colors.black54))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bildirim Türleri',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: types.map((type) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getIcon(type), size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            _getLabel(type),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


