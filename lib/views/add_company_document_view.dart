import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:arti_capital/views/document_preview_view.dart';
import 'package:path_provider/path_provider.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/company_models.dart';
import '../services/general_service.dart';
import '../services/storage_service.dart';
import '../services/company_service.dart';
import '../theme/app_colors.dart';

class AddCompanyDocumentView extends StatefulWidget {
  const AddCompanyDocumentView({super.key, required this.compId, this.partnerID});
  final int compId;
  final int? partnerID;

  @override
  State<AddCompanyDocumentView> createState() => _AddCompanyDocumentViewState();
}

class _AddCompanyDocumentViewState extends State<AddCompanyDocumentView> {
  List<DocumentTypeItem> _documentTypes = [];
  DocumentTypeItem? _selectedType;
  PlatformFile? _pickedFile;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    final types = await GeneralService().getDocumentTypes();
    if (!mounted) return;
    setState(() {
      _documentTypes = types;
      if (types.isNotEmpty) _selectedType = types.first;
    });
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: false, withData: true);
    if (res == null || res.files.isEmpty) return;
    setState(() {
      _pickedFile = res.files.first;
    });
  }

  Future<void> _openPreview() async {
    if (_pickedFile == null) return;
    try {
      final file = _pickedFile!;
      final String? path = file.path;
      final bytes = file.bytes ?? (path != null ? await File(path).readAsBytes() : null);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
      final savePath = '${dir.path}/preview_$safeName';
      final f = File(savePath);
      await f.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentPreviewView(
            url: 'file://$savePath',
            title: file.name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ön izleme açılamadı: $e')));
    }
  }

  String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.docx')) return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    return 'application/octet-stream';
  }

  Future<void> _submit() async {
    if (_selectedType == null || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belge türü ve dosya seçin')));
      return;
    }

    final token = await StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }

    setState(() { _submitting = true; });
    try {
      final file = _pickedFile!;
      final String? path = file.path;
      final bytes = file.bytes ?? (path != null ? await File(path).readAsBytes() : null);
      if (bytes == null) throw Exception('Dosya okunamadı');
      final mime = _guessMime(file.name);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      final ok = await const CompanyService().addCompanyDocument(
        userToken: token,
        compId: widget.compId,
        documentType: _selectedType!.documentID,
        dataUrl: dataUrl,
        partnerID: widget.partnerID,
      );

      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.partnerID != null ? 'Ortak belgesi başarıyla eklendi.' : 'Şirket belgesi başarıyla eklendi.')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.partnerID != null ? 'Ortak belgesi eklenemedi' : 'Şirket belgesi eklenemedi')));
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
        title: Text(widget.partnerID != null ? 'Ortak Belgesi Ekle' : 'Şirket Belgesi Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(context, 'Belge Yükleme'),
            const SizedBox(height: 24),

            // Belge türü (styled dropdown)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DocumentTypeItem>(
                  isExpanded: true,
                  value: _selectedType,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Belge Türü',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                  items: _documentTypes
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                e.documentName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.onSurface,
                                    ),
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Dosya seçimi alanı
            if (_pickedFile == null) ...[
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
                      Icon(Icons.attach_file, color: AppColors.primary, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'Dosya Seç (PDF, PNG, JPG, DOCX)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 180,
                child: ElevatedButton.icon(
                  onPressed: _pickFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Dosya Ekle'),
                ),
              ),
            ] else ...[
              DashedBorderContainer(
                width: double.infinity,
                height: 140,
                borderColor: Colors.grey.shade400,
                dashWidth: 6,
                dashSpace: 4,
                radius: 8,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_pickedFile != null && _guessMime(_pickedFile!.name).startsWith('image/')) ...[
                      FutureBuilder<Uint8List?>(
                        future: (() async {
                          final pf = _pickedFile!;
                          if (pf.bytes != null) return pf.bytes;
                          if (pf.path != null) return await File(pf.path!).readAsBytes();
                          return null;
                        })(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          final data = snap.data;
                          if (data == null) {
                            return const Icon(Icons.image_not_supported_outlined, size: 28);
                          }
                          return Image.memory(data, fit: BoxFit.contain);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pickedFile!.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ] else ...[
                      const Icon(Icons.insert_drive_file_outlined, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        _pickedFile!.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
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
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: _openPreview,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(
                      'Ön İzle',
                      style: Theme.of(context).textTheme.bodyMedium,
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
                            'Yükleniyor...',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      )
                    : Text(
                        'Yükle',
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


