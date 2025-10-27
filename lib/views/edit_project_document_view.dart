import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/project_models.dart';
import '../services/projects_service.dart';
import '../services/logger.dart';
import '../theme/app_colors.dart';

class EditProjectDocumentView extends StatefulWidget {
  final ProjectDocument document;
  final int projectID;
  final int compID;

  const EditProjectDocumentView({
    super.key,
    required this.document,
    required this.projectID,
    required this.compID,
  });

  @override
  State<EditProjectDocumentView> createState() => _EditProjectDocumentViewState();
}

class _EditProjectDocumentViewState extends State<EditProjectDocumentView> {
  final ProjectsService _projectsService = ProjectsService();
  late TextEditingController _descController;
  PlatformFile? _selectedFile;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.document.documentDesc ?? '');
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya seçilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateDocument() async {
    setState(() => _updating = true);

    try {
      String fileData = '';

      // Eğer yeni dosya seçildiyse
      if (_selectedFile != null) {
        final fileBytes = await File(_selectedFile!.path!).readAsBytes();
        final base64String = base64Encode(fileBytes);

        String mimeType = 'application/octet-stream';
        final ext = _selectedFile!.extension?.toLowerCase() ?? '';
        if (ext == 'pdf') {
          mimeType = 'application/pdf';
        } else if (['jpg', 'jpeg'].contains(ext)) {
          mimeType = 'image/jpeg';
        } else if (ext == 'png') {
          mimeType = 'image/png';
        } else if (['doc', 'docx'].contains(ext)) {
          mimeType = 'application/msword';
        } else if (['xls', 'xlsx'].contains(ext)) {
          mimeType = 'application/vnd.ms-excel';
        }

        fileData = 'data:$mimeType;base64,$base64String';
      }

      final response = await _projectsService.updateProjectDocument(
        appID: widget.projectID,
        compID: widget.compID,
        documentID: widget.document.documentID,
        documentType: widget.document.documentTypeID,
        file: fileData,
        documentDesc: _descController.text.trim(),
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Belge başarıyla güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Belge güncellenemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.e('Error updating document: $e', tag: 'UPDATE_DOC');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Belge güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belgeyi Güncelle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Belge Türü İnfo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belge Türü',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.document.documentType,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Yüklenme Tarihi',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(height: 8),
                  Text(
                    widget.document.createDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface.withOpacity(0.8),
                    ),
                  ),
                  if (widget.document.validityDate.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Geçerlilik Tarihi',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.document.validityDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Açıklama
            Text(
              'Açıklama',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
            textCapitalization: TextCapitalization.sentences,
              controller: _descController,
              decoration: InputDecoration(
                hintText: 'Belge açıklaması',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Dosya Güncelleme
            Text(
              'Dosyayı Güncelle (İsteğe Bağlı)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Yeni bir dosya seçmek istemiyorsanız, sadece açıklamayı güncelleyebilirsiniz.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedFile == null)
              GestureDetector(
                onTap: _updating ? null : _pickFile,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _updating ? Colors.grey.shade100 : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 32,
                        color: _updating ? Colors.grey : AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dosya Seç',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _updating ? Colors.grey : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PDF, DOC, DOCX, XLS, XLSX, JPG, PNG',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Güncelle Butonu
            ElevatedButton(
              onPressed: _updating ? null : _updateDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _updating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Belgeyi Güncelle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
