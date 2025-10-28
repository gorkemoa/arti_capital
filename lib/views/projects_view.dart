import 'package:flutter/material.dart';
import '../models/project_models.dart';
import '../services/projects_service.dart';
import '../theme/app_colors.dart';
import '../services/storage_service.dart';
import 'add_project_view.dart';
import 'project_detail_view.dart';

class ProjectsView extends StatefulWidget {
  const ProjectsView({super.key});

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  final ProjectsService _service = ProjectsService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ProjectItem> _projects = [];
  List<ProjectItem> _filteredProjects = [];
  bool _loading = true;
  String _query = '';
  Set<int> _expandedProjects = {};

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
      });
      _applyFilter();
    });
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      final projects = await _service.getProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Projeler yüklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _applyFilter() async {
    if (_query.isEmpty) {
      setState(() {
        _filteredProjects = _projects;
      });
    } else {
      setState(() => _loading = true);
      try {
        final filtered = await _service.getProjects(searchText: _query);
        if (mounted) {
          setState(() {
            _filteredProjects = filtered;
          });
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
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

  void _showProjectActions(BuildContext context, ProjectItem project) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.appTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20),
                // Sabitle
                ListTile(
                  leading: const Icon(Icons.push_pin, color: AppColors.primary),
                  title: const Text('Sabitle'),
                  onTap: () {
                    Navigator.pop(context);
                    _pinProject(project);
                  },
                ),
                // Güncelle
                if (StorageService.hasPermission('projects', 'edit'))
                  ListTile(
                    leading: const Icon(Icons.edit, color: AppColors.primary),
                    title: const Text('Güncelle'),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => AddProjectView(projectId: project.appID),
                        ),
                      );
                      if (result == true) {
                        _loadProjects();
                      }
                    },
                  ),
                // Sil
                if (StorageService.hasPermission('projects', 'delete'))
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Sil', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteProject(project);
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pinProject(ProjectItem project) {
    // TODO: Sabitleme işlemi yapılacak
   
  }

  void _deleteProject(ProjectItem project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Projeyi Sil'),
        content: Text('${project.appTitle} projesini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await _service.deleteProject(project.appID);
                if (mounted) {
                  if (response.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response.message ?? 'Proje silindi')),
                    );
                    _loadProjects();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response.message ?? 'Proje silinemedi')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Proje silinemedi: $e')),
                  );
                }
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = AppColors.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projeler'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          if (StorageService.hasPermission('projects', 'add'))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const AddProjectView()),
                  );
                  if (result == true) {
                    _loadProjects();
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Proje Ekle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.onPrimary,
                  side: const BorderSide(color: AppColors.background, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Arama Barı
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
            textCapitalization: TextCapitalization.sentences,
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Proje ara',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: onSurface.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          // Projeler Listesi
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredProjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 56,
                              color: onSurface.withOpacity(0.25),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Proje bulunmuyor',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadProjects,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredProjects.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final project = _filteredProjects[index];
                            final statusColor = _parseStatusColor(project.statusColor);
                            
                            return _buildProjectCard(
                              context,
                              project,
                              statusColor,
                              theme,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    ProjectItem project,
    Color statusColor,
    ThemeData theme,
  ) {
    final onSurface = AppColors.onSurface;
    final cardBg = onSurface.withOpacity(0.02);
    const cardRadius = 12.0;
    final isExpanded = _expandedProjects.contains(project.appID);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: isExpanded 
            ? AppColors.primary.withOpacity(0.3) 
            : onSurface.withOpacity(0.08), 
          width: 1,
        ),
        boxShadow: isExpanded ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        children: [
          // Üst Kısım (Her Zaman Görünür)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedProjects.remove(project.appID);
                } else {
                  _expandedProjects.add(project.appID);
                }
              });
            },
            onLongPress: () {
              _showProjectActions(context, project);
            },
            borderRadius: BorderRadius.circular(cardRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık ve Ok
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.appTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Proje Kodu ve Firma
                  Row(
                    children: [
                      Icon(
                        Icons.tag,
                        size: 13,
                        color: onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        project.appCode,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurface.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.business_outlined,
                        size: 13,
                        color: onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          project.compName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Status ve Kişi (Aynı Hizada)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: statusColor,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  project.statusName,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  project.personName.trim(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Alt Kısım (Genişletilebilir)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(cardRadius),
                  bottomRight: Radius.circular(cardRadius),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    color: onSurface.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  // Destek
                  if (project.serviceName != null && project.serviceName!.isNotEmpty)
                    _buildDetailRow(
                      context,
                      Icons.category_outlined,
                      'Destek',
                      project.serviceName!,
                      theme,
                    ),
                  if (project.serviceName != null && project.serviceName!.isNotEmpty)
                    const SizedBox(height: 12),
                  // Tarih
                  _buildDetailRow(
                    context,
                    Icons.calendar_today_outlined,
                    'Oluşturma Tarihi',
                    project.createDate,
                    theme,
                  ),
                  // Açıklama
                  if (project.appDesc != null && project.appDesc!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Açıklama',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: onSurface.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project.appDesc!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurface.withOpacity(0.7),
                        height: 1.5,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Detay Butonu
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => ProjectDetailView(projectId: project.appID),
                          ),
                        );
                        if (result == true) {
                          _loadProjects();
                        }
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Detayları Görüntüle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    final onSurface = AppColors.onSurface;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: onSurface.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onSurface.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
