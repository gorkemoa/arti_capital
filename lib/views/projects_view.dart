import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_models.dart';
import '../services/projects_service.dart';
import '../theme/app_colors.dart';
import '../services/storage_service.dart';
import 'add_project_view.dart';
import 'project_detail_view.dart';

// Bekleyen işleri hesapla (Status ID: 1 veya 3)
Future<int> getPendingProjectsCount() async {
  try {
    final service = ProjectsService();
    final projects = await service.getProjects();
    // appStatus 1 (Yeni Randevu) veya 3 (Belge Bekleniyor) olanları say
    return projects.where((p) => p.appStatus == 1 || p.appStatus == 3).length;
  } catch (e) {
    return 0;
  }
}

// Devam eden işleri hesapla (Status ID: 3 veya 4)
Future<int> getOngoingProjectsCount() async {
  try {
    final service = ProjectsService();
    final projects = await service.getProjects();
    // appStatus 3 (Belge Bekleniyor) veya 4 (Devam Ediyor) olanları say
    return projects.where((p) => p.appStatus == 3 || p.appStatus == 4).length;
  } catch (e) {
    return 0;
  }
}

// Tamamlanan işleri hesapla (Status ID: 5)
Future<int> getCompletedProjectsCount() async {
  try {
    final service = ProjectsService();
    final projects = await service.getProjects();
    // appStatus 5 (Tamamlandı) olanları say
    return projects.where((p) => p.appStatus == 5).length;
  } catch (e) {
    return 0;
  }
}

// Toplam proje sayısını hesapla
Future<int> getTotalProjectsCount() async {
  try {
    final service = ProjectsService();
    final projects = await service.getProjects();
    return projects.length;
  } catch (e) {
    return 0;
  }
}

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
  Set<int> _pinnedProjects = {};

  @override
  void initState() {
    super.initState();
    _loadPinnedProjects();
    _loadProjects();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
      });
      _applyFilter();
    });
  }

  Future<void> _loadPinnedProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final pinnedIds = prefs.getStringList('pinned_projects') ?? [];
    setState(() {
      _pinnedProjects = pinnedIds.map((id) => int.parse(id)).toSet();
    });
  }

  Future<void> _savePinnedProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'pinned_projects',
      _pinnedProjects.map((id) => id.toString()).toList(),
    );
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
        _filteredProjects = _sortProjects(_projects);
      });
    } else {
      setState(() => _loading = true);
      try {
        final filtered = await _service.getProjects(searchText: _query);
        if (mounted) {
          setState(() {
            _filteredProjects = _sortProjects(filtered);
          });
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  List<ProjectItem> _sortProjects(List<ProjectItem> projects) {
    final pinned = projects.where((p) => _pinnedProjects.contains(p.appID)).toList();
    final unpinned = projects.where((p) => !_pinnedProjects.contains(p.appID)).toList();
    return [...pinned, ...unpinned];
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
    final isPinned = _pinnedProjects.contains(project.appID);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
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
                
                // Proje başlığı
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.appTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.appCode,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Divider(
                  height: 1,
                  color: AppColors.onSurface.withOpacity(0.1),
                ),
                
                // Detayları Görüntüle
                ListTile(
                  leading: Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Detayları Görüntüle'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailView(projectId: project.appID),
                      ),
                    );
                    if (result == true) {
                      _loadProjects();
                    }
                  },
                ),
                
                Divider(
                  height: 1,
                  color: AppColors.onSurface.withOpacity(0.1),
                ),
                
                // Sabitle/Kaldır
                ListTile(
                  leading: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(isPinned ? 'Sabitlemeyi Kaldır' : 'Sabitle'),
                  onTap: () {
                    Navigator.pop(context);
                    _pinProject(project);
                  },
                ),
                
                Divider(
                  height: 1,
                  color: AppColors.onSurface.withOpacity(0.1),
                ),
                
                // Güncelle
                if (StorageService.hasPermission('projects', 'update'))
                  ListTile(
                    leading: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Projeyi Düzenle'),
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
                
                if (StorageService.hasPermission('projects', 'update'))
                  Divider(
                    height: 1,
                    color: AppColors.onSurface.withOpacity(0.1),
                  ),
                
                // Sil
                if (StorageService.hasPermission('projects', 'delete'))
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Projeyi Sil',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteProject(project);
                    },
                  ),
                
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pinProject(ProjectItem project) {
    setState(() {
      if (_pinnedProjects.contains(project.appID)) {
        _pinnedProjects.remove(project.appID);
      } else {
        _pinnedProjects.add(project.appID);
      }
    });
    _savePinnedProjects();
    _applyFilter();
    
    if (mounted) {
      final isPinned = _pinnedProjects.contains(project.appID);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPinned ? 'Proje sabitlendi' : 'Proje sabitleme kaldırıldı'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteProject(ProjectItem project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Projeyi Sil'),
        content: Text('${project.appTitle} projesini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final response = await _service.deleteProject(project.appID);
      if (!mounted) return;
      
      if (response.success) {
        // Sabitlenmiş projelerden de kaldır
        if (_pinnedProjects.contains(project.appID)) {
          _pinnedProjects.remove(project.appID);
          await _savePinnedProjects();
        }
        
        // Listeyi yenile
        await _loadProjects();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Proje silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Proje silinemedi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proje silinemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    final isPinned = _pinnedProjects.contains(project.appID);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: isPinned
            ? AppColors.primary.withOpacity(0.4)
            : isExpanded 
              ? AppColors.primary.withOpacity(0.3) 
              : onSurface.withOpacity(0.08), 
          width: isPinned ? 1.5 : 1,
        ),
        boxShadow: isPinned ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ] : isExpanded ? [
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
            onTap: () async {
              // Ana alana tıklandığında detaya git
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ProjectDetailView(projectId: project.appID),
                ),
              );
              if (result == true) {
                _loadProjects();
              }
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
                      if (isPinned) ...[
                        Icon(
                          Icons.push_pin,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                      ],
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
                      // Ok ikonu - Ayrı tıklanabilir alan
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
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
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
