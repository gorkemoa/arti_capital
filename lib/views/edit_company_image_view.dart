import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

import '../models/company_models.dart';
import '../services/general_service.dart';
import '../services/storage_service.dart';
import '../services/company_service.dart';
import '../theme/app_colors.dart';

class EditCompanyImageView extends StatefulWidget {
  const EditCompanyImageView({
    super.key,
    required this.compId,
    required this.image,
  });
  final int compId;
  final CompanyImageItem image;

  @override
  State<EditCompanyImageView> createState() => _EditCompanyImageViewState();
}

class _EditCompanyImageViewState extends State<EditCompanyImageView> {
  List<DocumentTypeItem> _imageTypes = [];
  DocumentTypeItem? _selectedType;
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  bool _submitting = false;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _videoLinkController = TextEditingController();
  
  // Görsel mi video linki mi eklenecek
  String _uploadType = 'image'; // 'image' veya 'videoLink'

  @override
  void initState() {
    super.initState();
    _descController.text = widget.image.imageDesc ?? '';
    // Eğer mevcut görsel video (documentID=25) ise, uploadType'ı videoLink yap
    if (widget.image.imageTypeID == 25) {
      _uploadType = 'videoLink';
      // Eğer imageURL varsa, onu videoLinkController'a yükle
      if (widget.image.imageURL.isNotEmpty) {
        _videoLinkController.text = widget.image.imageURL;
      }
    }
    _loadTypes();
  }

  @override
  void dispose() {
    _descController.dispose();
    _videoLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    final types = await GeneralService().getDocumentTypes(2); // 2 = Görsel
    if (!mounted) return;
    setState(() {
      _imageTypes = types;
      // Mevcut görsel tipini seç
      _selectedType = types.firstWhere(
        (t) => t.documentID == widget.image.imageTypeID,
        orElse: () => types.isNotEmpty ? types.first : DocumentTypeItem(documentID: 0, documentName: ''),
      );
    });
  }

  Future<void> _showCupertinoSelector<T>({
    required List<T> items,
    required int initialIndex,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
    String title = '',
  }) async {
    final FixedExtentScrollController controller =
        FixedExtentScrollController(initialItem: initialIndex);
    int currentIndex = initialIndex.clamp(0, items.isNotEmpty ? items.length - 1 : 0);

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text('Vazgeç'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    Center(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text('Seç'),
                        onPressed: () {
                          if (items.isNotEmpty) {
                            onSelected(items[currentIndex]);
                          }
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: controller,
                  onSelectedItemChanged: (index) {
                    currentIndex = index;
                  },
                  children: items.isEmpty
                      ? [const Text('-')]
                      : items.map((e) => Center(child: Text(labelBuilder(e)))).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showImageSourceDialog() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Görsel Seç'),
        message: const Text('Görseli nereden seçmek istersiniz?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImageFromCamera();
            },
            child: const Text('Kamera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImageFromGallery();
            },
            child: const Text('Galeri'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('İptal'),
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamera açılırken hata oluştu: $e')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Galeri açılırken hata oluştu: $e')),
      );
    }
  }

  Future<void> _openDriveApp() async {
    try {
      // Google Drive uygulamasını açmak için URL scheme'leri
      Uri driveUri;
      
      if (Platform.isAndroid) {
        // Android için Google Drive app intent
        driveUri = Uri.parse('com.google.android.apps.docs://');
      } else if (Platform.isIOS) {
        // iOS için Google Drive app URL scheme
        driveUri = Uri.parse('googledrive://');
      } else {
        // Web veya diğer platformlar için browser'da Drive aç
        driveUri = Uri.parse('https://drive.google.com/drive/my-drive');
      }

      // URL'yi açmayı dene
      if (await canLaunchUrl(driveUri)) {
        await launchUrl(driveUri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drive uygulaması açıldı. Video linkini kopyalayıp buraya yapıştırın.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Drive uygulaması yüklü değilse, web'de aç
        final webUri = Uri.parse('https://drive.google.com/drive/my-drive');
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Drive web sayfası açıldı. Video linkini kopyalayıp buraya yapıştırın.'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          throw 'Drive açılamadı';
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Drive açılırken hata oluştu: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Görsel türü seçin')));
      return;
    }

    // Video linki seçeneği kontrolü
    if (_uploadType == 'videoLink') {
      final link = _videoLinkController.text.trim();
      if (link.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Drive video linki girin')),
        );
        return;
      }
    }

    final token = await StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }

    setState(() { _submitting = true; });
    try {
      String dataUrl = '';
      String? documentLink;
      
      if (_uploadType == 'videoLink') {
        // Video linki kullanılacak
        documentLink = _videoLinkController.text.trim();
      } else {
        // Eğer yeni görsel dosyası seçildiyse
        if (_pickedImage != null && _imageBytes != null) {
          final mime = _guessMime(_pickedImage!.name);
          dataUrl = 'data:$mime;base64,${base64Encode(_imageBytes!)}';
        }
      }

      final ok = await const CompanyService().updateCompanyDocument(
        userToken: token,
        compId: widget.compId,
        documentId: widget.image.imageID,
        documentType: _selectedType!.documentID,
        dataUrl: dataUrl,
        documentDesc: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        documentLink: documentLink,
      );

      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_uploadType == 'videoLink' ? 'Drive video linki başarıyla güncellendi.' : 'Görsel başarıyla güncellendi.')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_uploadType == 'videoLink' ? 'Drive video linki güncellenemedi' : 'Görsel güncellenemedi')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() { _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Görsel / Video Düzenle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(context, 'Görsel / Video Düzenleme'),
            const SizedBox(height: 24),

            // Görsel türü (Cupertino picker)
            GestureDetector(
              onTap: _imageTypes.isEmpty
                  ? null
                  : () async {
                      final currentIndex = _selectedType == null
                          ? 0
                          : _imageTypes.indexWhere((e) => e.documentID == _selectedType!.documentID).clamp(0, _imageTypes.length - 1);
                      await _showCupertinoSelector<DocumentTypeItem>(
                        items: _imageTypes,
                        initialIndex: currentIndex,
                        labelBuilder: (e) => e.documentName,
                        title: 'Görsel Türü Seç',
                        onSelected: (e) { setState(() { _selectedType = e; }); },
                      );
                    },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedType?.documentName ?? 'Görsel Türü',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: (_selectedType == null)
                                  ? AppColors.onSurface.withOpacity(0.6)
                                  : AppColors.onSurface,
                            ),
                      ),
                    ),
                    Icon(CupertinoIcons.chevron_down, size: 18, color: AppColors.onSurface.withOpacity(0.6)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Açıklama alanı
            Text(
              'Açıklama (İsteğe bağlı)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
            textCapitalization: TextCapitalization.sentences,
              controller: _descController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Görsel hakkında açıklama ekleyebilirsiniz...',
                hintStyle: TextStyle(
                  color: AppColors.onSurface.withOpacity(0.5),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Yükleme Tipi Seçimi
            Text(
              'Yükleme Tipi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _uploadType = 'image';
                        _videoLinkController.clear();
                        // Görsel seçildiğinde ilk görsel türünü seç (25 değil)
                        if (_imageTypes.isNotEmpty) {
                          _selectedType = _imageTypes.first;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _uploadType == 'image' ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _uploadType == 'image' ? AppColors.primary : Colors.grey.shade300,
                          width: _uploadType == 'image' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            color: _uploadType == 'image' ? AppColors.onPrimary : AppColors.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Görsel Dosyası',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _uploadType == 'image' ? AppColors.onPrimary : AppColors.onSurface.withOpacity(0.7),
                                  fontWeight: _uploadType == 'image' ? FontWeight.w600 : FontWeight.normal,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _uploadType = 'videoLink';
                        _pickedImage = null;
                        _imageBytes = null;
                        // Video seçildiğinde documentID = 25 olan türü seç
                        final videoType = _imageTypes.firstWhere(
                          (type) => type.documentID == 25,
                          orElse: () => _imageTypes.isNotEmpty ? _imageTypes.first : DocumentTypeItem(documentID: 25, documentName: 'Video'),
                        );
                        _selectedType = videoType;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _uploadType == 'videoLink' ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _uploadType == 'videoLink' ? AppColors.primary : Colors.grey.shade300,
                          width: _uploadType == 'videoLink' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_library,
                            color: _uploadType == 'videoLink' ? AppColors.onPrimary : AppColors.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Drive Video',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _uploadType == 'videoLink' ? AppColors.onPrimary : AppColors.onSurface.withOpacity(0.7),
                                  fontWeight: _uploadType == 'videoLink' ? FontWeight.w600 : FontWeight.normal,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Video Linki veya Görsel gösterimi
            if (_uploadType == 'videoLink') ...[
              // Video linki input alanı
              Text(
                'Google Drive Video Linki',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
            textCapitalization: TextCapitalization.sentences,
                controller: _videoLinkController,
                decoration: InputDecoration(
                  hintText: 'https://drive.google.com/file/d/...',
                  hintStyle: TextStyle(
                    color: AppColors.onSurface.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.link, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Google Drive\'dan video linki ekleyebilirsiniz',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 12),
              // Bilgi kutusu
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Google Drive\'dan video eklemek için:\n1. Drive\'da videoyu açın\n2. Sağ üst köşeden "Paylaş" butonuna tıklayın\n3. "Linki kopyala" seçeneğini kullanın\n4. Kopyalanan linki yukarıdaki alana yapıştırın',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue.shade900,
                              fontSize: 11,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Drive uygulamasını aç butonu
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openDriveApp,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(Icons.drive_file_move_outlined, color: AppColors.primary),
                      label: const Text('Drive\'ı Aç'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Görsel modu
              // Mevcut görsel
              Text(
                'Mevcut Görsel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.image.imageURL,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Yeni görsel seçimi
              if (_pickedImage == null && _imageBytes == null) ...[
                Text(
                  'Yeni Görsel Seç (İsteğe bağlı)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: DashedBorderContainer(
                    width: double.infinity,
                    height: 140,
                    borderColor: AppColors.primary.withOpacity(0.6),
                    dashWidth: 6,
                    dashSpace: 4,
                    radius: 8,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: AppColors.primary, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          'Kamera veya Galeriden Seç',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mevcut görsel değiştirilecek',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Yeni görsel seçilmiş
                Text(
                  'Yeni Görsel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                DashedBorderContainer(
                  width: double.infinity,
                  height: 200,
                  borderColor: Colors.green.shade400,
                  dashWidth: 6,
                  dashSpace: 4,
                  radius: 8,
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: Icon(Icons.edit, color: AppColors.primary),
                      label: Text(
                        'Değiştir',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _pickedImage = null;
                        _imageBytes = null;
                      }),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: Text(
                        'Kaldır',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _submitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Güncelleniyor...',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      )
                    : Text(
                        'Güncelle',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSectionTitle(BuildContext context, String title) {
  return Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
  );
}

class DashedBorderContainer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color borderColor;
  final double dashWidth;
  final double dashSpace;
  final Widget child;

  const DashedBorderContainer({
    super.key,
    required this.width,
    required this.height,
    required this.borderColor,
    required this.dashWidth,
    required this.dashSpace,
    this.radius = 8,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: borderColor,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
        radius: radius,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  _DashedRectPainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final PathMetrics metrics = path.computeMetrics();
    for (final PathMetric metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
