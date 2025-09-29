import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../models/company_models.dart';
import '../services/company_service.dart';
import '../services/storage_service.dart';
import '../services/pdf_generator_service.dart';
import '../theme/app_colors.dart';
import 'edit_company_view.dart';
import 'add_company_document_view.dart';
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
  // Belge türü ve seçim durumu artık ayrı sayfada yönetiliyor

  @override
  void initState() {
    super.initState();
    _load();
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
          // ignore: deprecated_member_use
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

  // eski bağlantı dialogu kaldırıldı; artık dokümanlar önizleme sayfasında açılıyor

  // uzun basış menüsü kaldırıldı; aksiyonlar doğrudan listede

  Future<void> _updateDocument(CompanyDocumentItem doc) async {
    final token = await StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }

    // Yeni dosya seç
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final String? path = file.path;
    final bytes = file.bytes ?? (path != null ? await File(path).readAsBytes() : null);
    if (bytes == null) return;

    // MIME türü tahmini
    String mime = 'application/octet-stream';
    final name = (file.name).toLowerCase();
    if (name.endsWith('.pdf')) {
      mime = 'application/pdf';
    } else if (name.endsWith('.png')) {
      mime = 'image/png';
    }
    else if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      mime = 'image/jpeg';
    }
    else if (name.endsWith('.docx')) {
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

  Future<void> _load() async {
    setState(() { _loading = true; });
    final comp = await const CompanyService().getCompanyDetail(widget.compId);
    if (!mounted) return;
    setState(() {
      _company = comp;
      _loading = false;
    });
  }

  Widget _buildPartnersTable(List<PartnerItem> partners) {
    return Row(
      children: [
        // Yatay kaydırılabilir tablo kısmı
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
                    if (res == true) {
                      _load();
                    }
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
        // Sağda sabit duran aksiyonlar
        Container(
          width: 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Her satır için aksiyon butonları
              ...partners.map((PartnerItem p) {
                return Container(
                  height: 48, // DataRow yüksekliği
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
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Düzenle'),
                        ),
                      ),
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
            ],
          ),
        ),
      ],
    );
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
        // Basit uzantı tahmini
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

        // Dosya adı çıkarımı
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
      // PDF oluşturma işlemi başladığını kullanıcıya göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('PDF oluşturuluyor...'),
            ],
          ),
        ),
      );

      // PDF oluştur
      final pdfBytes = await PdfGeneratorService.generateCompanyDetailPdf(_company!);
      
      if (!mounted) return;
      Navigator.pop(context); // Loading dialog'unu kapat

      // PDF önizleme ve paylaşma seçenekleri göster
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${_company!.compName} - PDF Raporu'),
          content: const Text('PDF başarıyla oluşturuldu. Ne yapmak istiyorsunız?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // PDF'i doğrudan cihaza kaydet
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
                  ),
                );
              },
              child: const Text('Kaydet'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // PDF'i dosya olarak paylaş
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
              },
              child: const Text('Paylaş'),
            ),
          ],
        ),
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Loading dialog'unu kapat
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF oluşturulurken hata oluştu')),
      );
    }
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 640;
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: [
                        _HeaderCard(
                          logo: _company!.compLogo,
                          name: _company!.compName,
                          type: _company!.compType ?? '-',
                        ),
                        const SizedBox(height: 12),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Panel(
                                  title: 'Firma Bilgileri',
                                  icon: Icons.apartment_outlined,
                                  actions: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Firma Bilgilerini Düzenle',
                                      onPressed: (_loading || _company == null)
                                          ? null
                                          : () async {
                                              final result = await Navigator.of(context).push<bool>(
                                                MaterialPageRoute(
                                                  builder: (_) => EditCompanyView(company: _company!),
                                                ),
                                              );
                                              if (result == true) {
                                                _load();
                                              }
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
                                    _InfoRow(label: 'NACE Kodu', value: _company!.compNaceCodeID?.toString() ?? '-'),
                                    _InfoRow(label: 'Açıklama', value: _company!.compDesc ?? '-'),
                                    
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _Panel(
                                  title: 'Adres',
                                  icon: Icons.location_on_outlined,
                                  actions: [
                                    IconButton(
                                      icon: const Icon(Icons.add_location_alt_outlined),
                                      tooltip: 'Adres Ekle',
                                      onPressed: () async {
                                        final res = await Navigator.of(context).push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) => AddCompanyAddressView(compId: widget.compId),
                                          ),
                                        );
                                        if (res == true) {
                                          _load();
                                        }
                                      },
                                    ),
                                  ],
                                  children: _addressRows(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _Panel(
                                  title: 'Ortaklar',
                                  icon: Icons.group_outlined,
                                  actions: [
                                    IconButton(
                                      icon: const Icon(Icons.person_add_alt),
                                      tooltip: 'Ortak Ekle',
                                      onPressed: () async {
                                        final res = await Navigator.of(context).push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) => AddCompanyPartnerView(compId: widget.compId),
                                          ),
                                        );
                                        if (res == true) {
                                          _load();
                                        }
                                      },
                                    ),
                                  ],
                                  contentPadding: const EdgeInsets.only(left: 14, right: 0, top: 10, bottom: 10),
                                  children: [
                                    if (_company!.partners.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Text(
                                          'Hiç ortak yok',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      )
                                    else
                                      _buildPartnersTable(_company!.partners),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _Panel(
                                  title: 'Belgeler',
                                  icon: Icons.insert_drive_file_outlined,
                                  actions: [
                                    IconButton(
                                      icon: const Icon(Icons.upload_file),
                                      tooltip: 'Belge Ekle',
                                      onPressed: () async {
                                        final res = await Navigator.of(context).push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) => AddCompanyDocumentView(compId: widget.compId),
                                          ),
                                        );
                                        if (res == true) {
                                          _load();
                                        }
                                      },
                                    ),
                                  ],
                                  children: [
                                    if (_company!.documents.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Text(
                                          'Hiç belge yok',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      )
                                    else
                                      Column(
                                        children: [
                                          for (final doc in _company!.documents) ListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                            leading: const Icon(Icons.description_outlined),
                                            title: Text(doc.documentType),
                                            subtitle: Text(doc.createDate),
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
                                              itemBuilder: (context) => const [
                                                PopupMenuItem<String>(
                                                  value: 'edit',
                                                  child: ListTile(
                                                    leading: Icon(Icons.edit_outlined),
                                                    title: Text('Güncelle'),
                                                  ),
                                                ),
                                                PopupMenuItem<String>(
                                                  value: 'share',
                                                  child: ListTile(
                                                    leading: Icon(Icons.ios_share),
                                                    title: Text('Paylaş'),
                                                  ),
                                                ),
                                                PopupMenuItem<String>(
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
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _Panel(
                            title: 'Firma Bilgileri',
                            icon: Icons.apartment_outlined,
                            actions: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit_outlined, size: 12),
                                label: const Text('Firma Düzenle'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  side: BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                onPressed: (_loading || _company == null)
                                    ? null
                                    : () async {
                                        final result = await Navigator.of(context).push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) => EditCompanyView(company: _company!),
                                          ),
                                        );
                                        if (result == true) {
                                          _load();
                                        }
                                      },
                              ),
                            ],
                            children: [
                              _InfoRow(label: 'Vergi No', value: _company!.compTaxNo ?? '-'),
                              _InfoRow(label: 'Vergi Dairesi', value: _company!.compTaxPalace ?? '-'),
                              _InfoRow(label: 'MERSİS', value: _company!.compMersisNo ?? '-'),
                              _InfoRow(label: 'E-Posta', value: _company!.compEmail ?? '-'),
                              _InfoRow(label: 'Telefon', value: _company!.compPhone ?? '-'),
                              _InfoRow(label: 'Web Sitesi', value: _company!.compWebsite ?? '-'),
                              _InfoRow(label: 'NACE Code ID', value: _company!.compNaceCodeID?.toString() ?? '-'),
                              _InfoRow(label: 'Kep Adresi', value: _company!.compKepAddress ?? '-'),
                              _InfoRow(label: 'Açıklama', value: _company!.compDesc ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _Panel(
                            title: 'Adres',
                            icon: Icons.location_on_outlined,
                            actions: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.add_location_alt_outlined, size: 12),
                                label: const Text('Adres Ekle'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  side: BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                onPressed: () async {
                                  final res = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => AddCompanyAddressView(compId: widget.compId),
                                    ),
                                  );
                                  if (res == true) {
                                    _load();
                                  }
                                },
                              ),
                            ],
                            children: _addressRows(),
                          ),
                          const SizedBox(height: 16),
                          _Panel(
                            title: 'Ortaklar',
                            icon: Icons.group_outlined,
                            actions: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.person_add_alt, size: 12),
                                label: const Text('Ortak Ekle'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  side: BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                onPressed: () async {
                                  final res = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => AddCompanyPartnerView(compId: widget.compId),
                                    ),
                                  );
                                  if (res == true) {
                                    _load();
                                  }
                                },
                              ),
                            ],
                            contentPadding: const EdgeInsets.only(left: 14, right: 0, top: 10, bottom: 10),
                            children: [
                              if (_company!.partners.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Hiç ortak yok',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                )
                              else
                                _buildPartnersTable(_company!.partners),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _Panel(
                            title: 'Belgeler',
                            icon: Icons.insert_drive_file_outlined,
                            actions: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.upload_file, size: 12),
                                label: const Text('Belge Ekle'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  side: BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                onPressed: () async {
                                  final res = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => AddCompanyDocumentView(compId: widget.compId),
                                    ),
                                  );    
                                  if (res == true) {
                                    _load();
                                  }
                                },
                              ),
                            ],
                            children: [
                              if (_company!.documents.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Hiç belge yok',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    for (final doc in _company!.documents) ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.description_outlined),
                                      title: Text(doc.documentType),
                                      subtitle: Text(doc.createDate),
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
                                        itemBuilder: (context) => const [
                                          PopupMenuItem<String>(
                                            value: 'edit',
                                            child: ListTile(
                                              leading: Icon(Icons.edit_outlined),
                                              title: Text('Güncelle'),
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'share',
                                            child: ListTile(
                                              leading: Icon(Icons.ios_share),
                                              title: Text('Paylaş'),
                                            ),
                                          ),
                                          PopupMenuItem<String>(
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
                                ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
    );
  }
}

Widget _detailLogoWidget(String logo, ThemeData theme) {
  final bg = theme.colorScheme.surface;
  // ignore: deprecated_member_use
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
    // ignore: deprecated_member_use
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
    // ignore: deprecated_member_use
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
    // ignore: deprecated_member_use
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


