import 'package:flutter/material.dart';
import '../models/project_models.dart';
import '../services/projects_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import 'edit_project_view.dart';
import 'add_tracking_view.dart';
import 'tracking_detail_view.dart';
import 'required_documents_view.dart';
import 'required_infos_view.dart';

class ProjectDetailView extends StatefulWidget {
  final int projectId;

  const ProjectDetailView({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<ProjectDetailView> {
  final ProjectsService _service = ProjectsService();
  
  ProjectDetail? _project;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProjectDetail();
  }

  Future<void> _loadProjectDetail() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.getProjectDetail(widget.projectId);
      
      if (mounted) {
        if (response.success && response.project != null) {
          setState(() {
            _project = response.project;
            _loading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.errorMessage ?? 'Proje yüklenemedi';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Bir hata oluştu: $e';
          _loading = false;
        });
      }
    }
  }

  void _openAddTrackingDialog() async {
    if (_project == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddTrackingView(
          projectID: _project!.appID,
          compID: _project!.compID,
          projectTitle: _project!.appTitle,
        ),
      ),
    );

    if (result == true) {
      _loadProjectDetail();
    }
  }

  Future<void> _showDeleteConfirmation() async {
    // İlk onay
    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Projeyi Sil'),
        content: Text(
          'Bu projeyi silmek istediğinizden emin misiniz?\n\n"${_project?.appTitle}" projesi kalıcı olarak silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    // İlk onay verilmediyse çık
    if (firstConfirmed != true || !mounted) return;

    // İkinci onay (Güvenlik)
    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text('Son Onay'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu işlem geri alınamaz!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"${_project?.appTitle}" projesi ve tüm ilgili verileri kalıcı olarak silinecektir.',
              style: TextStyle(
                color: AppColors.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Devam etmek istediğinizden emin misiniz?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
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
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    // İkinci onay da verilirse sil
    if (secondConfirmed == true && mounted) {
      await _deleteProject();
    }
  }

  Future<void> _deleteProject() async {
    if (_project == null) return;

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final response = await _service.deleteProject(_project!.appID);

      if (mounted) {
        // Loading'i kapat
        Navigator.of(context).pop();

        if (response.success) {
          // Başarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Proje başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Projeler sayfasına geri dön ve yenile
          Navigator.of(context).pop(true);
        } else {
          // Hata mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Proje silinemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Loading'i kapat
        Navigator.of(context).pop();
        
        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _parseStatusColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
      return AppColors.primary;
    } catch (_) {
      return AppColors.primary;
    }
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RequiredDocumentsView(
                    project: _project!,
                    onUpdate: _loadProjectDetail,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Gerekli Belgeler'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RequiredInfosView(
                    project: _project!,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.info),
            label: const Text('Gerekli Bilgiler'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proje Detayı'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          if (_project != null && 
              (StorageService.hasPermission('projects', 'update') || 
               StorageService.hasPermission('projects', 'delete')))
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                color: AppColors.surface,
                iconColor: AppColors.onPrimary,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(1),
                position: PopupMenuPosition.under,
                itemBuilder: (BuildContext context) => [
                  if (StorageService.hasPermission('projects', 'update'))
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: AppColors.onBackground),
                          SizedBox(width: 12),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                  if (StorageService.hasPermission('projects', 'delete'))
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => EditProjectView(project: _project!),
                      ),
                    );
                    if (result == true) {
                      _loadProjectDetail();
                    }
                  } else if (value == 'delete') {
                    _showDeleteConfirmation();
                  }
                },
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 56,
                        color: AppColors.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadProjectDetail,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadProjectDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActionButtons(theme),
                        
                        const SizedBox(height: 16),

                        if (_project!.trackings.isNotEmpty) ...[
                          _buildTrackingsCard(theme),
                        ] else ...[
                          _buildEmptyTrackingsCard(theme),
                        ],
                                                const SizedBox(height: 16),

                        _buildHeaderCard(theme),
                        const SizedBox(height: 16),
                        _buildCompanyCard(theme),
                        const SizedBox(height: 16),
                        _buildAddressCard(theme),
                       
                        if (_project!.serviceID != null && _project!.serviceName != null) ...[
                          const SizedBox(height: 16),
                          _buildServiceCard(theme),
                        ],
                        if (_project!.appDesc != null && _project!.appDesc!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildDescriptionCard(theme),
                        ],
                        
                       
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    final statusColor = _parseStatusColor(_project!.statusColor);
    
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _project!.appTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _project!.appCode,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _project!.statusName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.onSurface.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.person_outline,
                  'Sorumlu',
                  _project!.personName,
                  theme,
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  Icons.access_time,
                  'Tarih',
                  _project!.createDate,
                  theme,
                ),
              ),
              Expanded(child:  _buildInfoRow(
            Icons.trending_up,
            'İlerleme',
            _project!.appProgress,
            theme,
          ),)
            ],
          ),
         
        ],
      ),
    );
  }

  Widget _buildCompanyCard(ThemeData theme) {
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
                Icons.business,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Firma Bilgileri',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _project!.compName,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(ThemeData theme) {
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
                Icons.location_on,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Adres Bilgileri',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.label,
            'Adres Tipi',
            _project!.compAdrType,
            theme,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.location_city,
            'Şehir',
            _project!.compAdrCity,
            theme,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.place,
            'İlçe',
            _project!.compAdrDistrict,
            theme,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.onSurface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.home,
                  size: 16,
                  color: AppColors.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _project!.compAddress,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ThemeData theme) {
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
                Icons.category,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Destek',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _project!.serviceName!,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(ThemeData theme) {
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
                Icons.description,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Açıklama',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.onSurface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _project!.appDesc!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingsCard(ThemeData theme) {
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
                Icons.assignment,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Proje Durumu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (StorageService.hasPermission('projects', 'update'))
                ElevatedButton.icon(
                  onPressed: _openAddTrackingDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Durumu Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onPrimary,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AppColors.primary,
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _project!.trackings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final tracking = _project!.trackings[index];
              
              // Renkleri parse et
              Color typeColorBg = _parseHexColor(tracking.typeColorBg);
              Color statusBgColor = _parseHexColor(tracking.statusBgColor);
              Color statusColor = _parseHexColor(tracking.statusColor);
              
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TrackingDetailView(
                        tracking: tracking,
                        projectTitle: _project!.appTitle,
                        projectID: _project!.appID,
                        compID: _project!.compID,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusBgColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: statusBgColor.withOpacity(0.15),
                      width: 3,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Durum - EN ÜSTE
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            tracking.statusName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: typeColorBg.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: typeColorBg.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            tracking.trackTypeName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: typeColorBg,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Başlık
                    Text(
                      tracking.trackTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Açıklama
                    Text(
                      tracking.trackDesc,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurface.withOpacity(0.65),
                        height: 1.4,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10 ),
                    // Divider
                    Divider(
                      height: 1,
                      color: AppColors.onSurface.withOpacity(0.1),
                    ),
                    const SizedBox(height: 12),
                    // Info Grid (Tarihler ve Atanan)
                    Row(
                      children: [
                        // Bitiş Tarihi
                        Flexible(
                          child: _buildTrackingInfo(
                            Icons.calendar_today,
                            'Bitiş',
                            tracking.trackDueDate,
                            theme,
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Hatırlatma Tarihi
                        Flexible(
                          child: _buildTrackingInfo(
                            Icons.notifications_outlined,
                            'Hatırlat',
                            tracking.trackRemindDate,
                            theme,
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Atanan Kişi
                  
                      ],
                    ),
                   if (tracking.notificationType != null && tracking.notificationType!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                   Row(
                  children: [
                   Expanded(
                  child: _buildTrackingInfo(
                        Icons.notifications,
                        'Bildirim',
                        _formatNotificationType(tracking.notificationType!),
                        theme,
                        ),
                            ),
                   const SizedBox(width: 10),
                   Expanded(
                   child: _buildTrackingInfo(
                   Icons.person_outline,
                   'Atanan',
                   tracking.assignedUser,
                   theme,
       ),
      ),
    ],
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

  String _formatNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'push':
        return 'Push';
      case 'email':
        return 'E-posta';
      case 'sms':
        return 'SMS';
      case 'all':
        return 'Tümü';
      default:
        return type;
    }
  }

  Widget _buildTrackingInfo(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(
            icon,
            size: 14,
            color: AppColors.primary.withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTrackingsCard(ThemeData theme) {
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
                Icons.assignment,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Proje Durumu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (StorageService.hasPermission('projects', 'update'))
                ElevatedButton.icon(
                  onPressed: _openAddTrackingDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Durumu Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onPrimary,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AppColors.primary,
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: AppColors.onSurface.withOpacity(0.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz proje durumu eklenmemiş',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Proje hakkında güncelleme eklemek için',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface.withOpacity(0.4),
                    ),
                  ),
                  Text(
                    '"Durumu Ekle" butonunu kullanın',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
}
