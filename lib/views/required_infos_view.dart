import 'package:flutter/material.dart';
import '../models/project_models.dart';
import '../theme/app_colors.dart';
import 'add_information_view.dart';

class RequiredInfosView extends StatefulWidget {
  final ProjectDetail project;
  final VoidCallback? onUpdate;

  const RequiredInfosView({
    super.key,
    required this.project,
    this.onUpdate,
  });

  @override
  State<RequiredInfosView> createState() => _RequiredInfosViewState();
}

class _RequiredInfosViewState extends State<RequiredInfosView> {
  
  void _openAddInformationView(RequiredInfo info) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddInformationView(
          projectID: widget.project.appID,
          requiredInfo: info,
        ),
      ),
    );

    if (result == true) {
      if (widget.onUpdate != null) {
        widget.onUpdate!();
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerekli Bilgiler'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gerekli Bilgiler Kartı
            _buildRequiredInfosCard(theme),
            const SizedBox(height: 16),
            // Ek Bilgiler Kartı
            _buildInformationsCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredInfosCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onSurface.withOpacity(0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist_rtl,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Gerekli Bilgiler',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          widget.project.requiredInfos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.checklist_outlined,
                          size: 40,
                          color: AppColors.onSurface.withOpacity(0.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerekli bilgi bulunmuyor',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.project.requiredInfos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final info = widget.project.requiredInfos[index];
                    
                    // Icon seçimi
                    IconData iconData;
                    switch (info.infoType) {
                      case 'text':
                        iconData = Icons.text_fields;
                        break;
                      case 'textarea':
                        iconData = Icons.notes;
                        break;
                      case 'select':
                        iconData = Icons.list;
                        break;
                      default:
                        iconData = Icons.info_outline;
                    }
                    
                    return InkWell(
                      onTap: (!info.isAdded && info.isRequired) 
                          ? () => _openAddInformationView(info)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: info.isAdded
                              ? Colors.green.withOpacity(0.04)
                              : (info.isRequired
                                  ? Colors.orange.withOpacity(0.04)
                                  : AppColors.onSurface.withOpacity(0.03)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: info.isAdded
                                ? Colors.green.withOpacity(0.2)
                                : (info.isRequired
                                    ? Colors.orange.withOpacity(0.2)
                                    : AppColors.onSurface.withOpacity(0.08)),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: info.isAdded
                                    ? Colors.green.withOpacity(0.1)
                                    : (info.isRequired
                                        ? Colors.orange.withOpacity(0.1)
                                        : AppColors.primary.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                info.isAdded
                                    ? Icons.check_circle
                                    : (info.isRequired ? Icons.edit_note : iconData),
                                size: 20,
                                color: info.isAdded
                                    ? Colors.green
                                    : (info.isRequired ? Colors.orange : AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info.infoName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.onSurface.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getInfoTypeLabel(info.infoType),
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: AppColors.onSurface.withOpacity(0.6),
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        info.statusText,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: info.isAdded
                                              ? Colors.green
                                              : (info.isRequired
                                                  ? Colors.orange
                                                  : AppColors.onSurface.withOpacity(0.6)),
                                          fontWeight: info.isRequired || info.isAdded ? FontWeight.w500 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!info.isAdded && info.isRequired)
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppColors.onSurface.withOpacity(0.4),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  String _getInfoTypeLabel(String type) {
    switch (type) {
      case 'text':
        return 'Metin';
      case 'textarea':
        return 'Çok Satırlı';
      case 'select':
        return 'Seçim';
      default:
        return type;
    }
  }

  Widget _buildInformationsCard(ThemeData theme) {
    // Firma bilgileri ve proje bilgileri ayrı grupla
    final compInfos = widget.project.informations.where((info) => info.isCompInfo).toList();
    final jobInfos = widget.project.informations.where((info) => info.isJobInfo).toList();

    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onSurface.withOpacity(0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ek Bilgiler',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          if (compInfos.isEmpty && jobInfos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 40,
                      color: AppColors.onSurface.withOpacity(0.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ek bilgi bulunmuyor',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Firma Bilgileri
          if (compInfos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Firma Bilgileri',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            ...compInfos.map((info) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildInformationRow(info, theme),
            )),
          ],
          
          // Proje Bilgileri
          if (jobInfos.isNotEmpty) ...[
            if (compInfos.isNotEmpty) const SizedBox(height: 8),
            Text(
              'Proje Bilgileri',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            ...jobInfos.map((info) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildInformationRow(info, theme),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildInformationRow(ProjectInformation info, ThemeData theme) {
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
                Icons.label_outline,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                info.infoLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            info.infoValue,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (info.infoDesc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              info.infoDesc,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
