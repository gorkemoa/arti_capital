import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
  PlatformFile? _pickedFile;
  bool _submitting = false;
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descController.text = widget.image.imageDesc ?? '';
    _loadTypes();
  }

  @override
  void dispose() {
    _descController.dispose();
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

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.image,
    );
    if (res == null || res.files.isEmpty) return;
    setState(() {
      _pickedFile = res.files.first;
    });
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

    final token = await StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }

    setState(() { _submitting = true; });
    try {
      String dataUrl = '';
      
      // Eğer yeni dosya seçildiyse
      if (_pickedFile != null) {
        final file = _pickedFile!;
        final String? path = file.path;
        final bytes = file.bytes ?? (path != null ? await File(path).readAsBytes() : null);
        if (bytes == null) throw Exception('Dosya okunamadı');
        final mime = _guessMime(file.name);
        dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      }

      final ok = await const CompanyService().updateCompanyDocument(
        userToken: token,
        compId: widget.compId,
        documentId: widget.image.imageID,
        documentType: _selectedType!.documentID,
        dataUrl: dataUrl,
        documentDesc: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      );

      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Görsel başarıyla güncellendi.')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Görsel güncellenemedi')));
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
        title: const Text('Görseli Düzenle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(context, 'Görsel Düzenleme'),
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

            // Yeni dosya seçimi
            if (_pickedFile == null) ...[
              Text(
                'Yeni Görsel Seç (İsteğe bağlı)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickFile,
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
                        'Görsel Seç (PNG, JPG, GIF)',
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
                child: FutureBuilder<Uint8List?>(
                  future: (() async {
                    final pf = _pickedFile!;
                    if (pf.bytes != null) return pf.bytes;
                    if (pf.path != null) return await File(pf.path!).readAsBytes();
                    return null;
                  })(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final data = snap.data;
                    if (data == null) {
                      return const Center(
                        child: Icon(Icons.image_not_supported_outlined, size: 48),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.memory(data, fit: BoxFit.contain),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _pickFile,
                    icon: Icon(Icons.edit, color: AppColors.primary),
                    label: Text(
                      'Değiştir',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => setState(() => _pickedFile = null),
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
