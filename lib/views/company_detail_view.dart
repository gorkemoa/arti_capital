import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../models/company_models.dart';
import '../services/company_service.dart';
import '../services/storage_service.dart';
import '../services/pdf_generator_service.dart';
import '../theme/app_colors.dart';
import 'edit_company_view.dart';
import 'add_company_document_view.dart';
import 'add_company_image_view.dart';
import 'add_company_bank_view.dart';
import 'add_company_password_view.dart';
import 'edit_company_password_view.dart';
import 'document_preview_view.dart';
import 'add_company_partner_view.dart';
import 'edit_company_partner_view.dart';
import 'partner_detail_view.dart';
import 'add_company_address_view.dart';
import 'edit_company_address_view.dart';

class CompanyDetailView extends StatefulWidget {
  const CompanyDetailView({super.key, required this.compId});
  final int compId;

  @override
  State<CompanyDetailView> createState() => _CompanyDetailViewState();
}

class _CompanyDetailViewState extends State<CompanyDetailView> {
  CompanyItem? _company;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    final comp = await const CompanyService().getCompanyDetail(widget.compId);
    if (!mounted) return;
    setState(() {
      _company = comp;
      _loading = false;
    });
  }

  List<Widget> _addressRows() {
    if (_company == null) return const [];
    final addresses = _company!.addresses;
    if (addresses.isEmpty) {
      return [
        _InfoRow(label: 'İl / İlçe', value: '${_company!.compCity} / ${_company!.compDistrict}'),
        _InfoRow(label: 'Adres', value: _company!.compAddress),
      ];
    }

    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: addresses.map((a) {
          final theme = Theme.of(context);
          final border = theme.colorScheme.outline.withOpacity(0.12);
          final type = a.addressType ?? 'Adres';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: theme.textTheme.bodyMedium?.fontSize,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (StorageService.hasPermission('companies', 'update'))
                          GestureDetector(
                            onTap: () async {
                              final res = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => EditCompanyAddressView(compId: widget.compId, address: a),
                                ),
                              );
                              if (res == true) _load();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        if (StorageService.hasPermission('companies', 'delete'))
                          GestureDetector(
                            onTap: () async {
                              final token = await StorageService.getToken();
                              if (token == null) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
                                return;
                              }
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Adresi Sil'),
                                  content: Text('${a.addressType ?? 'Adres'} kaydını silmek istediğinize emin misiniz?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              final ok = await const CompanyService().deleteCompanyAddress(
                                userToken: token,
                                compId: widget.compId,
                                addressId: a.addressID,
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(ok ? 'Adres silindi.' : 'Adres silinemedi')),
                              );
                              if (ok) _load();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: theme.textTheme.bodyMedium?.height),
                Text(
                  '${a.addressAddress ?? '-'}',
                  style: TextStyle(
                    fontSize: theme.textTheme.bodyMedium?.fontSize,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: theme.textTheme.bodyMedium?.height,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ];
  }

  Future<void> _updateDocument(CompanyDocumentItem doc) async {
    final token = await StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final String? path = file.path;
    final bytes = file.bytes ?? (path != null ? await File(path).readAsBytes() : null);
    if (bytes == null) return;

    String mime = 'application/octet-stream';
    final name = (file.name).toLowerCase();
    if (name.endsWith('.pdf')) {
      mime = 'application/pdf';
    } else if (name.endsWith('.png')) {
      mime = 'image/png';
    } else if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      mime = 'image/jpeg';
    } else if (name.endsWith('.docx')) {
      mime = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }

    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

    final ok = await const CompanyService().updateCompanyDocument(
      userToken: token,
      compId: widget.compId,
      documentId: doc.documentID,
      documentType: doc.documentTypeID,
      dataUrl: dataUrl,
      partnerID: 0,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Belge güncellendi.' : 'Belge güncellenemedi')),
    );
    if (ok) _load();
  }

  Future<void> _deleteDocument(CompanyDocumentItem doc) async {
    final token = await StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Belgeyi Sil'),
        content: Text('${doc.documentType} belgesini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await const CompanyService().deleteCompanyDocument(
      userToken: token,
      compId: widget.compId,
      documentId: doc.documentID,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Belge silindi.' : 'Belge silinemedi')),
    );
    if (ok) _load();
  }

  Future<void> _shareDocument(CompanyDocumentItem doc) async {
    try {
      final String title = doc.documentType;
      final String url = doc.documentURL;

      Uint8List bytes;
      String fileName = 'belge';
      String? mimeType;

      if (url.startsWith('data:')) {
        final int commaIndex = url.indexOf(',');
        final String header = commaIndex > 0 ? url.substring(0, commaIndex) : '';
        final String b64 = commaIndex > 0 ? url.substring(commaIndex + 1) : '';
        if (header.contains(';base64')) {
          mimeType = header.split(':').last.split(';').first;
        }
        bytes = base64Decode(b64);
        if (mimeType == 'application/pdf') {
          fileName = 'belge.pdf';
        } else if (mimeType == 'image/png') {
          fileName = 'belge.png';
        } else if (mimeType == 'image/jpeg') {
          fileName = 'belge.jpg';
        } else if (mimeType == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
          fileName = 'belge.docx';
        } else {
          fileName = 'belge.bin';
        }
      } else {
        final uri = Uri.tryParse(url);
        if (uri == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçersiz belge bağlantısı')));
          return;
        }

        final client = HttpClient();
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belge indirilemedi')));
          return;
        }
        final builder = BytesBuilder(copy: false);
        await for (final chunk in response) {
          builder.add(chunk);
        }
        bytes = builder.takeBytes();
        mimeType = response.headers.value('content-type');

        final String lastSeg = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (lastSeg.isNotEmpty) {
          fileName = lastSeg;
        } else {
          if (mimeType == 'application/pdf') {
            fileName = 'belge.pdf';
          } else if (mimeType == 'image/png') {
            fileName = 'belge.png';
          } else if (mimeType == 'image/jpeg') {
            fileName = 'belge.jpg';
          } else if (mimeType == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
            fileName = 'belge.docx';
          } else {
            fileName = 'belge.bin';
          }
        }
      }

      final String tempPath = Directory.systemTemp.path;
      final File outFile = File('$tempPath/$fileName');
      await outFile.writeAsBytes(bytes);

      final xfile = XFile(outFile.path, mimeType: mimeType, name: fileName);
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [xfile], 
        subject: title, 
        text: title, 
        sharePositionOrigin: box != null 
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belge paylaşılırken hata oluştu')));
    }
  }

  Future<void> _exportCompanyToPdf() async {
    if (_company == null) return;

    try {
      // Loading dialog göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                child: Text('PDF oluşturuluyor...\nLütfen bekleyin.'),
              ),
            ],
          ),
        ),
      );

      // PDF oluştur
      final pdfBytes = await PdfGeneratorService.generateCompanyDetailPdf(_company!);
      
      if (!mounted) return;
      Navigator.pop(context); // Loading dialog'u kapat

      // Başarı dialog'u göster
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${_company!.compName} - PDF Raporu'),
              ),
            ],
          ),
          content: const Text('PDF başarıyla oluşturuldu. Ne yapmak istiyorsunuz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final file = await PdfGeneratorService.savePdfToFile(
                    pdfBytes, 
                    '${_company!.compName}_detay_raporu.pdf'
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PDF kaydedildi: ${file.path}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'TAMAM',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PDF kaydedilemedi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final file = await PdfGeneratorService.savePdfToFile(
                    pdfBytes, 
                    '${_company!.compName}_detay_raporu.pdf'
                  );
                  final xfile = XFile(
                    file.path,
                    mimeType: 'application/pdf',
                    name: '${_company!.compName}_detay_raporu.pdf',
                  );
                  final box = context.findRenderObject() as RenderBox?;
                  await Share.shareXFiles(
                    [xfile],
                    subject: '${_company!.compName} - Firma Detay Raporu',
                    text: 'Firma detay raporu ekte bulunmaktadır.',
                    sharePositionOrigin: box != null 
                      ? box.localToGlobal(Offset.zero) & box.size
                      : null,
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PDF paylaşılamadı: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Paylaş'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Eğer dialog açıksa kapat
      Navigator.pop(context);
      
      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF oluşturulurken hata oluştu: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
      // Debug için konsola yazdır
      print('PDF oluşturma hatası: $e');
    }
  }

  Future<void> _deleteCompany() async {
    if (_company == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firmayı Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu firmayı silmek istediğinizden emin misiniz?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Firma Adı: ${_company!.compName}'),
            if (_company!.compTaxNo != null && _company!.compTaxNo!.isNotEmpty)
              Text('Vergi No: ${_company!.compTaxNo}'),
            const SizedBox(height: 16),
            const Text(
              'Bu işlem geri alınamaz ve firma ile ilgili tüm bilgiler silinecektir.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = await StorageService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oturum bulunamadı')),
      );
      return;
    }

    // Loading dialog göster
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Firma siliniyor...')),
          ],
        ),
      ),
    );

    try {
      final success = await const CompanyService().deleteCompany(
        userToken: token,
        compId: widget.compId,
      );

      if (!mounted) return;
      Navigator.pop(context); // Loading dialog'u kapat

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firma başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
        // Firma silindikten sonra bir önceki sayfaya dön
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firma silinemedi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Loading dialog'u kapat
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firma silinirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateImage(CompanyImageItem image) async {
    final token = await StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.image,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final String? path = file.path;
    final bytes = file.bytes ?? (path != null ? await File(path).readAsBytes() : null);
    if (bytes == null) return;

    String mime = 'image/jpeg';
    final name = (file.name).toLowerCase();
    if (name.endsWith('.png')) {
      mime = 'image/png';
    } else if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      mime = 'image/jpeg';
    } else if (name.endsWith('.webp')) {
      mime = 'image/webp';
    }

    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

    final ok = await const CompanyService().updateCompanyDocument(
      userToken: token,
      compId: widget.compId,
      documentId: image.imageID,
      documentType: image.imageTypeID,
      dataUrl: dataUrl,
      partnerID: 0,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Görsel güncellendi.' : 'Görsel güncellenemedi')),
    );
    if (ok) _load();
  }

  Future<void> _deleteImage(CompanyImageItem image) async {
    final token = await StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görseli Sil'),
        content: Text('${image.imageType} görselini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await const CompanyService().deleteCompanyDocument(
      userToken: token,
      compId: widget.compId,
      documentId: image.imageID,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Görsel silindi.' : 'Görsel silinemedi')),
    );
    if (ok) _load();
  }

  Future<void> _shareImage(CompanyImageItem image) async {
    try {
      final String title = image.imageType;
      final String url = image.imageURL;

      Uint8List bytes;
      String fileName = 'gorsel';
      String? mimeType;

      if (url.startsWith('data:')) {
        final int commaIndex = url.indexOf(',');
        final String header = commaIndex > 0 ? url.substring(0, commaIndex) : '';
        final String b64 = commaIndex > 0 ? url.substring(commaIndex + 1) : '';
        if (header.contains(';base64')) {
          mimeType = header.split(':').last.split(';').first;
        }
        bytes = base64Decode(b64);
        if (mimeType == 'image/png') {
          fileName = 'gorsel.png';
        } else if (mimeType == 'image/jpeg') {
          fileName = 'gorsel.jpg';
        } else if (mimeType == 'image/webp') {
          fileName = 'gorsel.webp';
        } else {
          fileName = 'gorsel.jpg';
        }
      } else {
        final uri = Uri.tryParse(url);
        if (uri == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçersiz görsel bağlantısı')));
          return;
        }

        final client = HttpClient();
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Görsel indirilemedi')));
          return;
        }
        final builder = BytesBuilder(copy: false);
        await for (final chunk in response) {
          builder.add(chunk);
        }
        bytes = builder.takeBytes();
        mimeType = response.headers.value('content-type');

        final String lastSeg = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (lastSeg.isNotEmpty) {
          fileName = lastSeg;
        } else {
          if (mimeType == 'image/png') {
            fileName = 'gorsel.png';
          } else if (mimeType == 'image/jpeg') {
            fileName = 'gorsel.jpg';
          } else if (mimeType == 'image/webp') {
            fileName = 'gorsel.webp';
          } else {
            fileName = 'gorsel.jpg';
          }
        }
      }

      final String tempPath = Directory.systemTemp.path;
      final File outFile = File('$tempPath/$fileName');
      await outFile.writeAsBytes(bytes);

      final xfile = XFile(outFile.path, mimeType: mimeType, name: fileName);
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [xfile], 
        subject: title, 
        text: title, 
        sharePositionOrigin: box != null 
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Görsel paylaşılırken hata oluştu')));
    }
  }

  Widget _buildPartnersTable(List<PartnerItem> partners) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text('Ad Soyad')),
                DataColumn(label: Text('T.C. No')),
                DataColumn(label: Text('Doğum Tarihi')),
                DataColumn(label: Text('Ünvan')),
                DataColumn(label: Text('Konum')),
                DataColumn(label: Text('Vergi Dairesi')),
                DataColumn(label: Text('Hisse')),
                DataColumn(label: Text('Tutar')),
              ],
              rows: partners.map((PartnerItem p) {
                return DataRow(
                  onSelectChanged: (selected) async {
                    if (selected != true) return;
                    final res = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => PartnerDetailView(compId: widget.compId, partner: p),
                      ),
                    );
                    if (res == true) _load();
                  },
                  cells: [
                    DataCell(Text((p.partnerFullname.isNotEmpty ? p.partnerFullname : p.partnerName).toUpperCase())),
                    DataCell(Text(p.partnerIdentityNo.isNotEmpty ? p.partnerIdentityNo : '-')),
                    DataCell(Text(p.partnerBirthday.isNotEmpty ? p.partnerBirthday : '-')),
                    DataCell(Text(p.partnerTitle.isNotEmpty ? p.partnerTitle.toUpperCase() : '-')),
                    DataCell(Text('${p.partnerCity}/${p.partnerDistrict}')),
                    DataCell(Text(p.partnerTaxPalace)),
                    DataCell(Text(p.partnerShareRatio)),
                    DataCell(Text(p.partnerSharePrice)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        Container(
          width: 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: partners.map((PartnerItem p) {
              return Container(
                height: 48,
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  tooltip: 'Aksiyonlar',
                  icon: const Icon(Icons.more_vert),
                  iconSize: 20,
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final res = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => EditCompanyPartnerView(compId: widget.compId, partner: p),
                        ),
                      );
                      if (res == true) _load();
                    } else if (value == 'delete') {
                      final token = await StorageService.getToken();
                      if (token == null) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
                        return;
                      }
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Ortak Sil'),
                          content: Text('${p.partnerName} adlı ortağı silmek istediğinize emin misiniz?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      final ok = await const CompanyService().deleteCompanyPartner(
                        userToken: token,
                        compId: widget.compId,
                        partnerId: p.partnerID,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok ? 'Ortak silindi.' : 'Ortak silinemedi')),
                      );
                      if (ok) _load();
                    }
                  },
                  itemBuilder: (context) => [
                    if (StorageService.hasPermission('companies', 'update'))
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Düzenle'),
                        ),
                      ),
                    if (StorageService.hasPermission('companies', 'delete'))
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                          title: Text('Sil'),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 12),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        side: BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildCompanyInfoPanel() {
    return _Panel(
      title: 'Firma Bilgileri',
      icon: Icons.apartment_outlined,
      actions: [
        if (StorageService.hasPermission('companies', 'update'))
          _buildActionButton(
            icon: Icons.edit_outlined,
            label: 'Firma Düzenle',
            onPressed: (_loading || _company == null)
                ? () {}
                : () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => EditCompanyView(company: _company!),
                      ),
                    );
                    if (result == true) _load();
                  },
          ),
      ],
      children: [
        _InfoRow(label: 'Vergi No', value: _company!.compTaxNo ?? '-'),
        _InfoRow(label: 'Vergi Dairesi', value: _company!.compTaxPalace ?? (_company!.compTaxPalaceID?.toString() ?? '-')),
        _InfoRow(label: 'MERSİS', value: _company!.compMersisNo ?? '-'),
        _InfoRow(label: 'E-Posta', value: _company!.compEmail ?? '-'),
        _InfoRow(label: 'Telefon', value: _company!.compPhone ?? '-'),
        _InfoRow(label: 'Web Sitesi', value: _company!.compWebsite ?? '-'),
        _InfoRow(label: 'NACE Kodu', value: _company!.compNaceCode ?? '-'),
        if (_company!.compNaceCodeDesc != null && _company!.compNaceCodeDesc!.isNotEmpty)
          _InfoRow(label: 'NACE Açıklama', value: _company!.compNaceCodeDesc!),
        _InfoRow(label: 'Kep Adresi', value: _company!.compKepAddress ?? '-'),
        _InfoRow(label: 'Açıklama', value: _company!.compDesc ?? '-'),
      ],
    );
  }

  Widget _buildAddressPanel() {
    return _Panel(
      title: 'Adres',
      icon: Icons.location_on_outlined,
      actions: [
        if (StorageService.hasPermission('companies', 'add'))
          _buildActionButton(
            icon: Icons.add_location_alt_outlined,
            label: 'Adres Ekle',
            onPressed: () async {
              final res = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddCompanyAddressView(compId: widget.compId),
                ),
              );
              if (res == true) _load();
            },
          ),
      ],
      children: _addressRows(),
    );
  }

  Widget _buildPartnersPanel() {
    return _Panel(
      title: 'Ortaklar',
      icon: Icons.group_outlined,
      actions: [
        if (StorageService.hasPermission('companies', 'add'))
          _buildActionButton(
            icon: Icons.person_add_alt,
            label: 'Ortak Ekle',
            onPressed: () async {
              final res = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddCompanyPartnerView(compId: widget.compId),
                ),
              );
              if (res == true) _load();
            },
          ),
      ],
      contentPadding: const EdgeInsets.only(left: 14, right: 0, top: 10, bottom: 10),
      children: [
        if (_company!.partners.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Hiç ortak yok', style: Theme.of(context).textTheme.bodyMedium),
          )
        else
          _buildPartnersTable(_company!.partners),
      ],
    );
  }

  Widget _buildDocumentsPanel() {
    return _Panel(
      title: 'Belgeler',
      icon: Icons.insert_drive_file_outlined,
      actions: [
        if (StorageService.hasPermission('companies', 'add'))
          _buildActionButton(
            icon: Icons.upload_file,
            label: 'Belge Ekle',
            onPressed: () async {
              final res = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddCompanyDocumentView(compId: widget.compId),
                ),
              );
              if (res == true) _load();
            },
          ),
      ],
      children: [
        if (_company!.documents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Hiç belge yok', style: Theme.of(context).textTheme.bodyMedium),
          )
        else
          Column(
            children: _company!.documents.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              return Column(
                children: [
                  if (index > 0) 
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(doc.documentType, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  SizedBox(height: 6),
                    Row(children: [
                      Text(
                        'Yükleme Tarihi: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        doc.createDate,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]
),
                    if (doc.documentValidityDate.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Geçerlilik Tarihi: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            doc.documentValidityDate,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (doc.documentDesc != null && doc.documentDesc!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Açıklama:',
                            style: TextStyle(
                              fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              doc.documentDesc!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                         
                          ),

                        ],
                      ),
                  
                    ],
                  ],
                ),
                isThreeLine: doc.documentDesc != null && doc.documentDesc!.isNotEmpty,
                trailing: PopupMenuButton<String>(
                  tooltip: 'Aksiyonlar',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _updateDocument(doc);
                    } else if (value == 'delete') {
                      _deleteDocument(doc);
                    } else if (value == 'share') {
                      _shareDocument(doc);
                    }
                  },
                  itemBuilder: (context) => [
                    if (StorageService.hasPermission('companies', 'update'))
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Güncelle'),
                        ),
                      ),
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: ListTile(
                        leading: Icon(Icons.ios_share),
                        title: Text('Paylaş'),
                      ),
                    ),
                    if (StorageService.hasPermission('companies', 'delete'))
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                          title: Text('Sil'),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DocumentPreviewView(
                        url: doc.documentURL,
                        title: doc.documentType,
                      ),
                    ),
                  );
                },
              ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildBanksPanel() {
    return _Panel(
      title: 'Banka Bilgileri',
      icon: Icons.account_balance_outlined,
      actions: [
        if (StorageService.hasPermission('companies', 'add'))
          _buildActionButton(
            icon: Icons.add,
            label: 'Banka Ekle',
            onPressed: () async {
              final res = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddCompanyBankView(compId: widget.compId),
                ),
              );
              if (res == true) _load();
            },
          ),
      ],
      children: [
        if (_company!.banks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Hiç banka bilgisi yok', style: Theme.of(context).textTheme.bodyMedium),
          )
        else
          Column(
            children: _company!.banks.map((bank) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: bank.bankLogo != null && bank.bankLogo!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          bank.bankLogo!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance),
                        ),
                      )
                    : const Icon(Icons.account_balance),
                title: Text(bank.bankName.isNotEmpty ? bank.bankName : 'Banka ${bank.bankID}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bank.bankUsername),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          bank.bankIBAN.length > 16 ? '${bank.bankIBAN.substring(0, 16)}...' : bank.bankIBAN,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: bank.bankIBAN));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('IBAN kopyalandı'), duration: Duration(seconds: 1)),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.copy, size: 14, color: Colors.blue),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () async {
                            final box = context.findRenderObject() as RenderBox?;
                            await Share.share(
                              bank.bankIBAN,
                              subject: 'IBAN Numarası',
                              sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.ios_share, size: 14, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  tooltip: 'Aksiyonlar',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final token = await StorageService.getToken();
                      if (token == null) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
                        return;
                      }
                      final confirm = await showDialog<bool>(
                        // ignore: use_build_context_synchronously
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Banka Bilgisini Sil'),
                          content: Text('${bank.bankName} banka bilgisini silmek istediğinize emin misiniz?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      final ok = await const CompanyService().deleteCompanyBank(
                        userToken: token,
                        compId: widget.compId,
                        cbID: bank.cbID != 0 ? bank.cbID : bank.bankID,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok ? 'Banka bilgisi silindi.' : 'Banka bilgisi silinemedi')),
                      );
                      if (ok) _load();
                    }
                  },
                  itemBuilder: (context) => [
                    if (StorageService.hasPermission('companies', 'delete'))
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                          title: Text('Sil'),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildPasswordsPanel() {
    return _Panel(
      title: 'Şifreler',
      icon: Icons.lock_outlined,
      actions: [
        if (StorageService.hasPermission('companies', 'add'))
          _buildActionButton(
            icon: Icons.add,
            label: 'Şifre Ekle',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCompanyPasswordView(compId: widget.compId),
                ),
              );
              if (result == true) {
                _load();
              }
            },
          ),
      ],
      children: [
        if (_company!.passwords.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Hiç şifre yok', style: Theme.of(context).textTheme.bodyMedium),
          )
        else
          Column(
            children: _company!.passwords.map((password) {
              return _PasswordListItem(
                password: password,
                compId: widget.compId,
                onPasswordUpdated: _load,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildImagesPanel() {
    return _Panel(
      title: 'Görseller',
      icon: Icons.image_outlined,
      actions: [
        if (StorageService.hasPermission('companies', 'add'))
          _buildActionButton(
            icon: Icons.add,
            label: 'Görsel Ekle',
            onPressed: () async {
              final res = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddCompanyImageView(compId: widget.compId),
                ),
              );
              if (res == true) _load();
            },
          ),
      ],
      children: [
        if (_company!.images.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Hiç görsel yok', style: Theme.of(context).textTheme.bodyMedium),
          )
        else
          Column(
            children: _company!.images.map((image) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      image.imageURL,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  title: Text(image.imageType),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        image.createDate,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (image.imageDesc != null && image.imageDesc!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  image.imageDesc!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  isThreeLine: image.imageDesc != null && image.imageDesc!.isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Aksiyonlar',
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'view') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DocumentPreviewView(
                              url: image.imageURL,
                              title: image.imageType,
                            ),
                          ),
                        );
                      } else if (value == 'update') {
                        _updateImage(image);
                      } else if (value == 'share') {
                        _shareImage(image);
                      } else if (value == 'delete') {
                        _deleteImage(image);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility_outlined),
                          title: Text('Görüntüle'),
                        ),
                      ),
                      if (StorageService.hasPermission('companies', 'update'))
                        const PopupMenuItem<String>(
                          value: 'update',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Güncelle'),
                          ),
                        ),
                      const PopupMenuItem<String>(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.ios_share),
                          title: Text('Paylaş'),
                        ),
                      ),
                      if (StorageService.hasPermission('companies', 'delete'))
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                            title: Text('Sil'),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DocumentPreviewView(
                          url: image.imageURL,
                          title: image.imageType,
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firma Detayı'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          if (!_loading && _company != null)
            IconButton(
              onPressed: _exportCompanyToPdf,
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'PDF Olarak Dışa Aktar',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_company == null)
              ? const Center(child: Text('Firma bulunamadı'))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    _HeaderCard(
                      logo: _company!.compLogo,
                      name: _company!.compName,
                      type: _company!.compType ?? '-',
                    ),
                    const SizedBox(height: 16),
                    _buildCompanyInfoPanel(),
                    const SizedBox(height: 16),
                    _buildAddressPanel(),
                    const SizedBox(height: 16),
                    _buildPartnersPanel(),
                    const SizedBox(height: 16),
                    _buildDocumentsPanel(),
                    const SizedBox(height: 16),
                    _buildBanksPanel(),
                    const SizedBox(height: 16),
                    _buildPasswordsPanel(),
                    const SizedBox(height: 16),
                    _buildImagesPanel(),
                    const SizedBox(height: 24),
                    // Firma Sil Butonu
                    if (StorageService.hasPermission('companies', 'delete'))
                      Center(
                        child: TextButton.icon(
                          onPressed: _deleteCompany,
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          label: const Text(
                            'Firmayı Sil',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }
}

Widget _detailLogoWidget(String logo, ThemeData theme) {
  final bg = theme.colorScheme.surface;
  final border = theme.colorScheme.outline.withOpacity(0.12);
  Widget child;
  if (logo.isEmpty) {
    child = const Icon(Icons.apartment_outlined, size: 64);
  } else if (logo.startsWith('data:image/')) {
    try {
      final parts = logo.split(',');
      if (parts.length == 2) {
        final bytes = base64Decode(parts[1]);
        child = Image.memory(bytes, fit: BoxFit.contain);
      } else {
        child = const Icon(Icons.apartment_outlined, size: 64);
      }
    } catch (_) {
      child = const Icon(Icons.apartment_outlined, size: 64);
    }
  } else if (logo.startsWith('http://') || logo.startsWith('https://')) {
    child = Image.network(logo, fit: BoxFit.contain);
  } else {
    child = const Icon(Icons.apartment_outlined, size: 64);
  }
  return Container(
    width: 96,
    height: 96,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: bg,
      shape: BoxShape.circle,
      border: Border.all(color: border),
    ),
    child: ClipOval(
      child: FittedBox(fit: BoxFit.contain, child: child),
    ),
  );
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.logo, required this.name, required this.type});
  final String logo;
  final String name;
  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outline.withOpacity(0.12);
    final muted = theme.colorScheme.onSurface.withOpacity(0.7);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            child: _detailLogoWidget(logo, theme),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.apartment_outlined, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        type,
                        style: theme.textTheme.bodySmall?.copyWith(color: muted, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.icon, required this.children, this.actions, this.contentPadding});
  final String title;
  final IconData icon;
  final List<Widget> children;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outline.withOpacity(0.12);
    final headerBg = theme.colorScheme.surface;
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
              color: headerBg,
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
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (actions != null && actions!.isNotEmpty)
                  Row(children: actions!),
              ],
            ),
          ),
          Padding(
            padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
                    Divider(height: 16, thickness: 0.5, color: border),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = theme.colorScheme.onSurface.withOpacity(0.7);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: subtle, letterSpacing: 0.2, height: 1.2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.25),
          ),
        ),
      ],
    );
  }
}

class _PasswordListItem extends StatefulWidget {
  const _PasswordListItem({
    required this.password,
    required this.compId,
    required this.onPasswordUpdated,
  });
  
  final CompanyPasswordItem password;
  final int compId;
  final VoidCallback onPasswordUpdated;

  @override
  State<_PasswordListItem> createState() => _PasswordListItemState();
}

class _PasswordListItemState extends State<_PasswordListItem> {
  bool _isPasswordVisible = false;
  bool _isUsernameVisible = false;
  Timer? _passwordTimer;
  Timer? _usernameTimer;

  @override
  void dispose() {
    _passwordTimer?.cancel();
    _usernameTimer?.cancel();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });

    if (_isPasswordVisible) {
      _passwordTimer?.cancel();
      _passwordTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isPasswordVisible = false;
          });
        }
      });
    }
  }

  void _toggleUsernameVisibility() {
    setState(() {
      _isUsernameVisible = !_isUsernameVisible;
    });

    if (_isUsernameVisible) {
      _usernameTimer?.cancel();
      _usernameTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isUsernameVisible = false;
          });
        }
      });
    }
  }

  String _maskText(String text, bool isVisible) {
    if (isVisible || text.length <= 4) {
      return text;
    }
    
    if (text.length <= 4) {
      return text;
    }
    
    final first = text.substring(0, 2);
    final last = text.substring(text.length - 2);
    final middle = '•' * (text.length - 4);
    
    return '$first$middle$last';
  }

  Future<void> _copyToClipboard(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showDeletePasswordDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şifreyi Sil'),
        content: Text(
          'Bu şifreyi silmek istediğinizden emin misiniz?\n\n'
          'Şifre Türü: ${widget.password.passwordType}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deletePassword();
    }
  }

  Future<void> _deletePassword() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oturum bulunamadı')),
        );
        return;
      }

      final success = await const CompanyService().deleteCompanyPassword(
        userToken: token,
        compId: widget.compId,
        passID: widget.password.passwordID,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onPasswordUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre silinirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outline.withOpacity(0.12);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key_outlined, size: 15, color: theme.colorScheme.onSurface.withOpacity(0.7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.password.passwordType,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                widget.password.createDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (StorageService.hasPermission('companies', 'update') || 
                  StorageService.hasPermission('companies', 'delete'))
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditCompanyPasswordView(
                            compId: widget.compId,
                            password: widget.password,
                          ),
                        ),
                      );
                      if (result == true) {
                        widget.onPasswordUpdated();
                      }
                    } else if (value == 'delete') {
                      _showDeletePasswordDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    if (StorageService.hasPermission('companies', 'update'))
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                    if (StorageService.hasPermission('companies', 'delete'))
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Kullanıcı Adı Başlık
          Text(
            'Kullanıcı Adı',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // Kullanıcı Adı Satırı
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _maskText(widget.password.passwordUsername, _isUsernameVisible),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: _isUsernameVisible ? 0 : 1,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _toggleUsernameVisibility,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _isUsernameVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _copyToClipboard(
                    widget.password.passwordUsername,
                    'Kullanıcı adı kopyalandı',
                  ),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Şifre Başlık
          Text(
            'Şifre',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // Şifre Satırı
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _maskText(widget.password.passwordPassword, _isPasswordVisible),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: _isPasswordVisible ? 0 : 1,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _togglePasswordVisibility,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _copyToClipboard(
                    widget.password.passwordPassword,
                    'Şifre kopyalandı',
                  ),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
