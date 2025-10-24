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

    if (result == true && mounted) {
      // Bilgi eklendi, ana sayfayı güncelle
      if (widget.onUpdate != null) {
        widget.onUpdate!();
      }
      
      // Bu sayfayı kapat ve ana sayfanın yenilenmesini bekle
      Navigator.of(context).pop(true);
    }
  }

  void _showInfoActions(RequiredInfo info, ProjectInformation addedInfo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Bilgi başlığı
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  children: [
                    Text(
                      info.infoName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      addedInfo.infoValue,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              Divider(
                height: 1,
                color: AppColors.onSurface.withOpacity(0.1),
              ),
              
              // Güncelle
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: AppColors.primary,
                ),
                title: const Text('Güncelle'),
                onTap: () {
                  Navigator.pop(context);
                  _openAddInformationView(info);
                },
              ),
              
              Divider(
                height: 1,
                color: AppColors.onSurface.withOpacity(0.1),
              ),
              
              // Sil
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text(
                  'Sil',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(info, addedInfo);
                },
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(RequiredInfo info, ProjectInformation addedInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bilgiyi Sil'),
        content: Text('${info.infoName} bilgisini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteInformation(addedInfo.infoID);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInformation(int infoID) async {
    // Burada silme API'sini çağırabilirsiniz
    // Şimdilik sadece yenileme yapıyoruz
    if (widget.onUpdate != null) {
      widget.onUpdate!();
    }
    Navigator.of(context).pop(true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bilgi silindi'),
        backgroundColor: Colors.green,
      ),
    );
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
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredInfosCard(ThemeData theme) {
    // Eklenen bilgileri bir map'e çevir (infoID'ye göre)
    final addedInfoMap = <int, ProjectInformation>{};
    for (var info in widget.project.informations) {
      addedInfoMap[info.infoID] = info;
    }

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
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Proje Bilgileri',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (widget.project.requiredInfos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Bilgi bulunmuyor',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.project.requiredInfos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final info = widget.project.requiredInfos[index];
                final addedInfo = addedInfoMap[info.infoID];
                
                return InkWell(
                  onTap: info.isAdded
                      ? () => _showInfoActions(info, addedInfo!)
                      : () => _openAddInformationView(info),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: info.isAdded
                          ? Colors.green.withOpacity(0.04)
                          : AppColors.onSurface.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: info.isAdded
                            ? Colors.green.withOpacity(0.2)
                            : (info.isRequired
                                ? Colors.red.withOpacity(0.2)
                                : AppColors.onSurface.withOpacity(0.08)),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                info.infoName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!info.isAdded) ...[
                              if (info.isRequired)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Zorunlu',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppColors.onSurface.withOpacity(0.4),
                              ),
                            ] else
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                          ],
                        ),
                        
                        // Eklenen bilgi varsa göster
                        if (addedInfo != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.onSurface.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addedInfo.infoValue,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (addedInfo.infoDesc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    addedInfo.infoDesc,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.onSurface.withOpacity(0.5),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
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
}
