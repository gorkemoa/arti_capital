import 'package:arti_capital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'edit_appointment_view.dart';
import '../services/appointments_service.dart';
import '../services/storage_service.dart';

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
    this.appointmentDateRaw,
    this.statusID,
  });

  final String title;
  final String companyName;
  final String time;
  final String statusName;
  final Color statusColor;
  final String description;
  final int? appointmentID;
  final int? compID;
  final String? appointmentDateRaw;
  final int? statusID;

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
      location: companyName,
      startDate: start,
      endDate: end,
      androidParams: const AndroidParams(emailInvites: []),
      iosParams: const IOSParams(reminder: Duration(minutes: 30)),
    );
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
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.black),
                              const SizedBox(width: 6),
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 13,
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

              const SizedBox(height: 12),
              _SectionCard(
                leading: const Icon(Icons.description_outlined, color: Colors.black54),
                title: 'Açıklama',
                content: description.isNotEmpty ? description : 'Açıklama bulunmuyor.',
                multiline: true,
              ),
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


