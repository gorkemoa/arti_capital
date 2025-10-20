import 'package:flutter/material.dart';
import '../models/project_models.dart';
import '../models/support_models.dart';
import '../services/projects_service.dart';
import '../services/general_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import 'document_viewer.dart';
import 'edit_project_view.dart';

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
  final GeneralService _generalService = GeneralService();
  
  ProjectDetail? _project;
  ServiceItem? _serviceDetail;
  bool _loading = true;
  bool _loadingService = false;
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
          // Servis detayını yükle
          if (_project!.serviceID != null) {
            _loadServiceDetail(_project!.serviceID!);
          }
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

  Future<void> _loadServiceDetail(int serviceID) async {
    setState(() => _loadingService = true);
    try {
      final service = await _generalService.getServiceDetail(serviceID);
      if (mounted) {
        setState(() {
          _serviceDetail = service;
          _loadingService = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingService = false);
      }
    }
  }

  void _openDocument(String url, String documentType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerPage(
          url: url,
          title: documentType,
        ),
      ),
    );
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
          if (_project != null && StorageService.hasPermission('projects', 'update'))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => EditProjectView(project: _project!),
                  ),
                );
                if (result == true) {
                  _loadProjectDetail();
                }
              },
            ),
          if (_project != null && StorageService.hasPermission('projects', 'delete'))
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirmation(),
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
                        if (_loadingService) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        ] else if (_serviceDetail != null && _serviceDetail!.documents.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildRequiredDocumentsCard(theme),
                        ],
                        const SizedBox(height: 16),
                        _buildDocumentsCard(theme),
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
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.trending_up,
            'İlerleme',
            _project!.appProgress,
            theme,
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
                'Servis',
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

  Widget _buildDocumentsCard(ThemeData theme) {
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
                Icons.folder_open,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Dökümanlar',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _project!.documents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_off,
                          size: 40,
                          color: AppColors.onSurface.withOpacity(0.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Henüz döküman eklenmemiş',
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
                  itemCount: _project!.documents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = _project!.documents[index];
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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.insert_drive_file,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.documentType,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 12,
                                          color: AppColors.onSurface.withOpacity(0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          doc.partner,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _openDocument(doc.documentURL, doc.documentType);
                                },
                                icon: const Icon(Icons.open_in_new),
                                iconSize: 20,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            color: AppColors.onSurface.withOpacity(0.1),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: AppColors.onSurface.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Geçerlilik: ${doc.validityDate}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: AppColors.onSurface.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    doc.createDate,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildRequiredDocumentsCard(ThemeData theme) {
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
                Icons.task_alt,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Gerekli Belgeler',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _serviceDetail!.documents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = _serviceDetail!.documents[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: doc.isRequired
                      ? Colors.red.withOpacity(0.05)
                      : AppColors.onSurface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: doc.isRequired
                        ? Colors.red.withOpacity(0.2)
                        : AppColors.onSurface.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: doc.isRequired
                            ? Colors.red.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        doc.isRequired ? Icons.priority_high : Icons.check_circle_outline,
                        size: 20,
                        color: doc.isRequired ? Colors.red : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.documentName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc.statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: doc.isRequired
                                  ? Colors.red
                                  : AppColors.onSurface.withOpacity(0.6),
                              fontWeight: doc.isRequired ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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
}
