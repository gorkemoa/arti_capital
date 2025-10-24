import 'package:flutter/material.dart';
import '../models/project_models.dart';
import '../theme/app_colors.dart';
import '../services/storage_service.dart';
import 'add_project_document_view.dart';
import 'edit_project_document_view.dart';
import 'document_viewer.dart';
import '../services/projects_service.dart';

class RequiredDocumentsView extends StatefulWidget {
  final ProjectDetail project;
  final VoidCallback onUpdate;

  const RequiredDocumentsView({
    super.key,
    required this.project,
    required this.onUpdate,
  });

  @override
  State<RequiredDocumentsView> createState() => _RequiredDocumentsViewState();
}

class _RequiredDocumentsViewState extends State<RequiredDocumentsView> {
  final ProjectsService _service = ProjectsService();

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

  void _openAddDocumentPage() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddProjectDocumentView(
          projectID: widget.project.appID,
          compID: widget.project.compID,
          requiredDocuments: widget.project.requiredDocuments,
        ),
      ),
    );

    if (result == true) {
      widget.onUpdate();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _openEditDocumentPage(ProjectDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProjectDocumentView(
          document: doc,
          projectID: widget.project.appID,
          compID: widget.project.compID,
        ),
      ),
    ).then((result) {
      if (result == true) {
        widget.onUpdate();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  Future<void> _deleteDocument(ProjectDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Belgeyi Sil'),
        content: Text(
          'Belge: ${doc.documentType}\n\nBu belgeyi silmek istediğinizden emin misiniz?',
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

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final response = await _service.deleteProjectDocument(
        appID: widget.project.appID,
        documentID: doc.documentID,
      );

      if (mounted) {
        Navigator.of(context).pop();

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Belge başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onUpdate();
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Belge silinemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerekli Belgeler'),
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
            // Gerekli Belgeler Kartı
            _buildRequiredDocumentsCard(theme),
            const SizedBox(height: 16),
            // Dökümanlar Kartı
            _buildDocumentsCard(theme),
          ],
        ),
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
          const SizedBox(height: 12),
          widget.project.requiredDocuments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.task_outlined,
                          size: 40,
                          color: AppColors.onSurface.withOpacity(0.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerekli belge bulunmuyor',
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
                  itemCount: widget.project.requiredDocuments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = widget.project.requiredDocuments[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: doc.isAdded
                            ? Colors.green.withOpacity(0.04)
                            : (doc.isRequired
                                ? Colors.red.withOpacity(0.04)
                                : AppColors.onSurface.withOpacity(0.03)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: doc.isAdded
                              ? Colors.green.withOpacity(0.2)
                              : (doc.isRequired
                                  ? Colors.red.withOpacity(0.2)
                                  : AppColors.onSurface.withOpacity(0.08)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: doc.isAdded
                                  ? Colors.green.withOpacity(0.1)
                                  : (doc.isRequired
                                      ? Colors.red.withOpacity(0.1)
                                      : AppColors.primary.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              doc.isAdded
                                  ? Icons.check_circle
                                  : (doc.isRequired ? Icons.priority_high : Icons.check_circle_outline),
                              size: 20,
                              color: doc.isAdded
                                  ? Colors.green
                                  : (doc.isRequired ? Colors.red : AppColors.primary),
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
                                    color: doc.isAdded
                                        ? Colors.green
                                        : (doc.isRequired
                                            ? Colors.red
                                            : AppColors.onSurface.withOpacity(0.6)),
                                    fontWeight: doc.isRequired || doc.isAdded ? FontWeight.w500 : FontWeight.normal,
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
              Expanded(
                child: Text(
                  'Dökümanlar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (StorageService.hasPermission('projects', 'update'))
                ElevatedButton.icon(
                  onPressed: _openAddDocumentPage,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          widget.project.documents.isEmpty
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
                  itemCount: widget.project.documents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = widget.project.documents[index];
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
                              if (StorageService.hasPermission('projects', 'update') && !doc.isCompDocument)
                                IconButton(
                                  onPressed: () {
                                    _openEditDocumentPage(doc);
                                  },
                                  icon: const Icon(Icons.edit),
                                  iconSize: 20,
                                  color: AppColors.primary,
                                ),
                              if (StorageService.hasPermission('projects', 'update') && !doc.isCompDocument)
                                IconButton(
                                  onPressed: () {
                                    _deleteDocument(doc);
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  iconSize: 20,
                                  color: Colors.red,
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
}
