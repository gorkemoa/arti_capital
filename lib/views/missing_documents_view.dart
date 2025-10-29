import 'package:flutter/material.dart';
import '../models/project_models.dart';
import '../services/projects_service.dart';

// Eksik evrak sayısını hesapla
Future<int> getMissingDocumentsCount() async {
  try {
    final service = ProjectsService();
    final projects = await service.getProjects();
    
    int totalMissingCount = 0;
    
    // Her proje için detay getir ve eksik evrakları say
    for (final project in projects) {
      final response = await service.getProjectDetail(project.appID);
      if (response.success && response.project != null) {
        final missing = response.project!.requiredDocuments
            .where((doc) => !doc.isAdded)
            .length;
        totalMissingCount += missing;
      }
    }
    
    return totalMissingCount;
  } catch (e) {
    return 0;
  }
}

class MissingDocumentsView extends StatefulWidget {
  const MissingDocumentsView({super.key});

  @override
  State<MissingDocumentsView> createState() => _MissingDocumentsViewState();
}

class _MissingDocumentsViewState extends State<MissingDocumentsView> {
  final ProjectsService _service = ProjectsService();
  List<ProjectItem> _projects = [];
  Map<int, List<RequiredDocument>> _missingDocumentsByProject = {};
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMissingDocuments();
  }

  Future<void> _loadMissingDocuments() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Tüm projeleri getir
      final projects = await _service.getProjects();
      
      if (!mounted) return;

      Map<int, List<RequiredDocument>> missingDocs = {};

      // Her proje için detay getir ve eksik evrakları filtrele
      for (final project in projects) {
        final response = await _service.getProjectDetail(project.appID);
        if (response.success && response.project != null) {
          final missing = response.project!.requiredDocuments
              .where((doc) => !doc.isAdded)
              .toList();
          if (missing.isNotEmpty) {
            missingDocs[project.appID] = missing;
          }
        }
      }

      if (mounted) {
        setState(() {
          _projects = projects;
          _missingDocumentsByProject = missingDocs;
          _loading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        title: Text('Eksik Evraklar', style: theme.appBarTheme.titleTextStyle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              tooltip: 'Bildirimler',
              onPressed: () {
                Navigator.of(context).pushNamed('/notifications');
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(1),
                iconSize: 20,
              ),
              icon: Icon(
                Icons.notifications_none,
                color: colorScheme.primary,
                size: theme.textTheme.headlineSmall?.fontSize,
              ),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 56,
                        color: colorScheme.error.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hata',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadMissingDocuments,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMissingDocuments,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: _missingDocumentsByProject.isEmpty
                        ? [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.fact_check_outlined,
                                      size: 64,
                                      color: colorScheme.primary.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Eksik Evrak Bulunmuyor',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tüm zorunlu evraklarınız mevcut görünüyor.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]
                        : [
                            _Panel(
                              title: 'Genel Durum',
                              icon: Icons.info_outline,
                              children: [
                                Text(
                                  '${_missingDocumentsByProject.values.fold<int>(0, (sum, list) => sum + list.length)} eksik evrak bulunmaktadır',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _Panel(
                              title: 'Proje Bazlı Eksik Evraklar',
                              icon: Icons.assignment_outlined,
                              children: [
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _missingDocumentsByProject.keys.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final projectId = _missingDocumentsByProject.keys.elementAt(index);
                                    final project = _projects.firstWhere(
                                      (p) => p.appID == projectId,
                                      orElse: () => _projects.first,
                                    );
                                    final missingDocs = _missingDocumentsByProject[projectId] ?? [];

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: colorScheme.outlineVariant,
                                          width: 0.5,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.folder_open_outlined,
                                                size: 18,
                                                color: colorScheme.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      project.appTitle,
                                                      style: theme.textTheme.labelLarge,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      project.compName,
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: colorScheme.onSurface.withOpacity(0.6),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.error.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${missingDocs.length}',
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    color: colorScheme.error,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: missingDocs
                                                .map(
                                                  (doc) => Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Icon(
                                                          Icons.check_circle_outline,
                                                          size: 16,
                                                          color: colorScheme.error,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                doc.documentName,
                                                                style:
                                                                    theme.textTheme.bodySmall,
                                                              ),
                                                              if (doc.statusText.isNotEmpty)
                                                                Text(
                                                                  doc.statusText,
                                                                  style: theme.textTheme
                                                                      .labelSmall
                                                                      ?.copyWith(
                                                                    color: colorScheme.onSurface
                                                                        .withOpacity(0.6),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                  ),
                ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outline.withOpacity(0.12);
    final muted = theme.colorScheme.onSurface.withOpacity(0.7);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: border),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: muted),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}


