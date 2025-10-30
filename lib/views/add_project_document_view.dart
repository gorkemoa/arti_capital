import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/project_models.dart';
import '../models/company_models.dart';
import '../services/projects_service.dart';
import '../services/general_service.dart';
import '../services/logger.dart';
import '../theme/app_colors.dart';

class AddProjectDocumentView extends StatefulWidget {
  final int projectID;
  final int compID;
  final List<RequiredDocument>? requiredDocuments;

  const AddProjectDocumentView({
    super.key,
    required this.projectID,
    required this.compID,
    this.requiredDocuments,
  });

  @override
  State<AddProjectDocumentView> createState() => _AddProjectDocumentViewState();
}

class _AddProjectDocumentViewState extends State<AddProjectDocumentView> {
  final ProjectsService _projectsService = ProjectsService();
  final GeneralService _generalService = GeneralService();

  List<DocumentTypeItem> _documentTypes = [];
  DocumentTypeItem? _selectedDocType;
  PlatformFile? _selectedFile;
  final _descController = TextEditingController();
  bool _loading = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadDocumentTypes();
  }

  Future<void> _loadDocumentTypes() async {
    setState(() => _loading = true);
    try {
      // API'den belge türlerini çek (1 = Belgeler için)
      final apiDocTypes = await _generalService.getDocumentTypes(1);
      
      if (mounted) {
        setState(() {
          if (widget.requiredDocuments != null && widget.requiredDocuments!.isNotEmpty) {
            // RequiredDocuments'teki eklenmemiş belgeleri önce ekle
            final requiredNotAdded = widget.requiredDocuments!
                .where((doc) => !doc.isAdded)
                .map((doc) => DocumentTypeItem(
                  documentID: doc.documentID,
                  documentName: doc.documentName,
                ))
                .toList();
            
            // API'den gelen tüm belge türlerini ekle
            // Duplicates'leri önlemek için ID kontrolü yap
            final requiredIds = requiredNotAdded.map((d) => d.documentID).toSet();
            final additionalTypes = apiDocTypes
                .where((apiDoc) => !requiredIds.contains(apiDoc.documentID))
                .toList();
            
            _documentTypes = [...requiredNotAdded, ...additionalTypes];
          } else {
            // RequiredDocuments yoksa sadece API'den gelenleri kullan
            _documentTypes = apiDocTypes;
          }
          
          if (_documentTypes.isNotEmpty) {
            _selectedDocType = _documentTypes.first;
          }
        });
      }
    } catch (e) {
      AppLogger.e('Failed to load document types: $e', tag: 'LOAD_DOC_TYPES');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Belge türleri yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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

  Future<void> _uploadDocument() async {
    if (_selectedFile == null || _selectedDocType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen belge türü ve dosya seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
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

      final fileData = 'data:$mimeType;base64,$base64String';

      // isAdditional belirleme: Eğer seçilen belge requiredDocuments listesinde değilse 1, varsa 0
      int isAdditional = 0;
      if (widget.requiredDocuments != null) {
        final isInRequiredList = widget.requiredDocuments!.any(
          (doc) => doc.documentID == _selectedDocType!.documentID
        );
        isAdditional = isInRequiredList ? 0 : 1;
      } else {
        // RequiredDocuments listesi yoksa, ek belge olarak kabul et
        isAdditional = 1;
      }

      final response = await _projectsService.addProjectDocument(
        appID: widget.projectID,
        compID: widget.compID,
        documentType: _selectedDocType!.documentID,
        file: fileData,
        documentDesc: _descController.text.trim(),
        isAdditional: isAdditional,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Belge başarıyla eklendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Belge eklenemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.e('Error uploading document: $e', tag: 'UPLOAD_DOC');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Belge yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Widget _buildCupertinoField({
    required String placeholder,
    String? value,
    VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled 
              ? AppColors.onSurface.withOpacity(0.03)
              : AppColors.onSurface.withOpacity(0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value == null || value.isEmpty ? placeholder : value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: (value == null || value.isEmpty)
                      ? AppColors.onSurface.withOpacity(isDisabled ? 0.4 : 0.4)
                      : AppColors.onSurface.withOpacity(isDisabled ? 0.5 : 1),
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: AppColors.onSurface.withOpacity(isDisabled ? 0.3 : 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDocumentTypePicker() async {
    if (_documentTypes.isEmpty) return;

    int selectedIndex = _documentTypes.indexWhere((t) => t.documentID == _selectedDocType?.documentID);
    if (selectedIndex < 0) selectedIndex = 0;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text('İptal'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: Text('Tamam'),
                      onPressed: () {
                        setState(() {
                          _selectedDocType = _documentTypes[selectedIndex];
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    selectedIndex = index;
                  },
                  children: _documentTypes.map((type) {
                    return Center(
                      child: Text(
                        type.documentName,
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belge Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gerekli belgeleri göster - Sadece zorunlu ve eklenmemiş belgeler varsa
                  if (widget.requiredDocuments != null && 
                      widget.requiredDocuments!.any((doc) => doc.isRequired && !doc.isAdded)) ...[
                    Text(
                      'Gerekli Belgeler',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final doc in widget.requiredDocuments!)
                            if (doc.isRequired && !doc.isAdded)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.priority_high,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        doc.documentName,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Belge Türü
                  Text(
                    'Belge Türü',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCupertinoField(
                    placeholder: 'Belge Türü',
                    value: _documentTypes.isEmpty
                        ? 'Belge türleri yükleniyor...'
                        : (_selectedDocType == null
                            ? null
                            : _selectedDocType!.documentName),
                    onTap: _showDocumentTypePicker,
                    isDisabled: _documentTypes.isEmpty,
                  ),
                  const SizedBox(height: 16),

                  // Açıklama
                  Text(
                    'Açıklama (Opsiyonel)',
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
                  const SizedBox(height: 16),

                  // Dosya Seçimi
                  Text(
                    'Dosya',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedFile == null)
                    GestureDetector(
                      onTap: _uploading ? null : _pickFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _uploading ? Colors.grey.shade100 : Colors.transparent,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 32,
                              color: _uploading ? Colors.grey : AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Dosya Seç',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _uploading ? Colors.grey : AppColors.primary,
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

                  // Yükle Butonu
                  ElevatedButton(
                    onPressed: _uploading ? null : _uploadDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _uploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Belgeyi Yükle',
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
