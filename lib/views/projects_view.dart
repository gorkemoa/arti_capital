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
    const cardRadius = 10.0;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ProjectDetailView(projectId: project.appID),
          ),
        );
        // Eğer proje silindiyse veya güncellendiyse listeyi yenile
        if (result == true) {
          _loadProjects();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: onSurface.withOpacity(0.08), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              // Başlık + Durum Satırı
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 3,
                      children: [
                        Text(
                          project.appTitle,
                          style: theme.textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          project.appCode,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
                    ),
                    child: Text(
                      project.statusName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              // Meta Bilgileri (Firma, Kişi, Servis)
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: _buildMetaItem(
                      context,
                      Icons.business,
                      project.compName,
                      theme,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      project.personName.trim(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Servis (eğer varsa)
              if (project.serviceName != null && project.serviceName!.isNotEmpty)
                _buildMetaItem(
                  context,
                  Icons.category,
                  project.serviceName!,
                  theme,
                  
                ),
              // Tarih
              _buildMetaItem(
                context,
                Icons.access_time,
                project.createDate,
                theme,
              ),
              // Açıklama (eğer varsa)
              if (project.appDesc != null && project.appDesc!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    project.appDesc!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withOpacity(0.65),
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(
    BuildContext context,
    IconData icon,
    String text,
    ThemeData theme,
  ) {
    final onSurface = AppColors.onSurface;

    return Row(
      children: [
        Icon(icon, size: 14, color: onSurface.withOpacity(0.4)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurface.withOpacity(0.65),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
