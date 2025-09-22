import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/company_models.dart';
import '../services/company_service.dart';
import '../services/storage_service.dart';
import '../services/general_service.dart';
import '../theme/app_colors.dart';
import 'edit_company_view.dart';
import 'add_company_document_view.dart';
import 'document_preview_view.dart';

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
    if (name.endsWith('.pdf')) mime = 'application/pdf';
    else if (name.endsWith('.png')) mime = 'image/png';
    else if (name.endsWith('.jpg') || name.endsWith('.jpeg')) mime = 'image/jpeg';
    else if (name.endsWith('.docx')) mime = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

    final ok = await const CompanyService().updateCompanyDocument(
      userToken: token,
      compId: widget.compId,
      documentId: doc.documentID,
      documentType: doc.documentTypeID,
      dataUrl: dataUrl,
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

  Future<void> _showAddPartnerDialog() async {
    final theme = Theme.of(context);
    final fullnameController = TextEditingController();
    final titleController = TextEditingController();
    final taxNoController = TextEditingController();
    final addressController = TextEditingController();
    final shareRatioController = TextEditingController();
    final sharePriceController = TextEditingController();

    int? selectedTaxPalaceId;
    List<TaxPalaceItem> palaces = [];
    bool loadingPalaces = true;
    String? errorText;

    // İl vergi dairelerini çek
    final cityId = _company?.compCityID;
    if (cityId != null && cityId > 0) {
      try {
        palaces = await GeneralService().getTaxPalaces(cityId);
      } catch (_) {}
    }
    loadingPalaces = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Ortak Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: fullnameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Ad Soyad *'),
                    ),
                    TextField(
                      controller: titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Ünvan'),
                    ),
                    TextField(
                      controller: taxNoController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Vergi No / TC No'),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Vergi Dairesi', style: theme.textTheme.bodySmall),
                    ),
                    const SizedBox(height: 4),
                    loadingPalaces
                        ? const LinearProgressIndicator(minHeight: 2)
                        : DropdownButtonFormField<int>(
                            value: selectedTaxPalaceId,
                            items: palaces
                                .map((p) => DropdownMenuItem<int>(
                                      value: p.palaceID,
                                      child: Text(p.palaceName),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                selectedTaxPalaceId = v;
                              });
                            },
                            isExpanded: true,
                          ),
                    TextField(
                      controller: addressController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Adres'),
                    ),
                    TextField(
                      controller: shareRatioController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Hisse Oranı (%)'),
                    ),
                    TextField(
                      controller: sharePriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Hisse Tutarı'),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(errorText!, style: TextStyle(color: theme.colorScheme.error)),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () async {
                    final fullname = fullnameController.text.trim();
                    if (fullname.isEmpty) {
                      setState(() { errorText = 'Ad Soyad zorunludur.'; });
                      return;
                    }
                    final token = await StorageService.getToken();
                    if (token == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
                      return;
                    }
                    final req = AddPartnerRequest(
                      userToken: token,
                      compID: widget.compId,
                      partnerFullname: fullname,
                      partnerTitle: titleController.text.trim(),
                      partnerTaxNo: taxNoController.text.trim(),
                      partnerTaxPalace: selectedTaxPalaceId ?? 0,
                      partnerAddress: addressController.text.trim(),
                      partnerShareRatio: shareRatioController.text.trim(),
                      partnerSharePrice: sharePriceController.text.trim(),
                    );
                    final resp = await const CompanyService().addCompanyPartner(req);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(resp.success ? (resp.message.isNotEmpty ? resp.message : 'Ortak eklendi') : (resp.errorMessage ?? resp.message))),
                    );
                    if (resp.success) {
                      Navigator.of(ctx).pop();
                      _load();
                    } else {
                      setState(() { errorText = resp.errorMessage ?? resp.message; });
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
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
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: 'Ortak Ekle',
            onPressed: _showAddPartnerDialog,
          ),
          if (!_loading && _company != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => EditCompanyView(company: _company!),
                  ),
                );
                if (result == true) {
                  _load();
                }
              },
              tooltip: 'Düzenle',
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
                                  children: [
                                    _InfoRow(label: 'Vergi No', value: _company!.compTaxNo ?? '-'),
                                    _InfoRow(label: 'Vergi Dairesi', value: _company!.compTaxPalaceID?.toString() ?? '-'),
                                    _InfoRow(label: 'MERSİS', value: _company!.compMersisNo ?? '-'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _Panel(
                                  title: 'Adres',
                                  icon: Icons.location_on_outlined,
                                  children: [
                                    _InfoRow(label: 'İl / İlçe', value: '${_company!.compCity} / ${_company!.compDistrict}'),
                                    _InfoRow(label: 'Adres', value: _company!.compAddress),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (_company!.documents.isNotEmpty)
                                Expanded(
                                  child: _Panel(
                                    title: 'Belgeler',
                                    icon: Icons.insert_drive_file_outlined,
                                    children: [
                                      Column(
                                        children: [
                                          for (final doc in _company!.documents) ListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            leading: const Icon(Icons.description_outlined),
                                            title: Text(doc.documentType),
                                            subtitle: Text(doc.createDate),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined),
                                                  tooltip: 'Güncelle',
                                                  onPressed: () => _updateDocument(doc),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline),
                                                  tooltip: 'Sil',
                                                  onPressed: () => _deleteDocument(doc),
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
                            children: [
                              _InfoRow(label: 'Vergi No', value: _company!.compTaxNo ?? '-'),
                              _InfoRow(label: 'Vergi Dairesi', value: _company!.compTaxPalace ?? '-'),
                              _InfoRow(label: 'MERSİS', value: _company!.compMersisNo ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _Panel(
                            title: 'Adres',
                            icon: Icons.location_on_outlined,
                            children: [
                              _InfoRow(label: 'İl / İlçe', value: '${_company!.compCity} / ${_company!.compDistrict}'),
                              _InfoRow(label: 'Adres', value: _company!.compAddress),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_company!.documents.isNotEmpty)
                            _Panel(
                              title: 'Belgeler',
                              icon: Icons.insert_drive_file_outlined,
                              children: [
                                Column(
                                  children: [
                                    for (final doc in _company!.documents) ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.description_outlined),
                                      title: Text(doc.documentType),
                                      subtitle: Text(doc.createDate),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined),
                                            tooltip: 'Güncelle',
                                            onPressed: () => _updateDocument(doc),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            tooltip: 'Sil',
                                            onPressed: () => _deleteDocument(doc),
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
  const _Panel({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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


