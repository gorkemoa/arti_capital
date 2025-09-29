import 'package:arti_capital/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppointmentDetailView extends StatelessWidget {
  const AppointmentDetailView({
    super.key,
    required this.title,
    required this.companyName,
    required this.time,
    required this.statusName,
    required this.statusColor,
    required this.description,
  });

  final String title;
  final String companyName;
  final String time;
  final String statusName;
  final Color statusColor;
  final String description;

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
            ],
          ),
        ),
      ),
    );
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


