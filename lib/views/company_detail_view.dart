import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/company_models.dart';
import '../services/company_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import 'edit_company_view.dart';
import 'add_company_document_view.dart';
import 'document_preview_view.dart';
import 'add_company_partner_view.dart';
import 'edit_company_partner_view.dart';
import 'partner_detail_view.dart';

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
    return SingleChildScrollView(
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
          DataColumn(label: Text('Aksiyonlar')),
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
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Düzenle',
                    onPressed: () async {
                      final res = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => EditCompanyPartnerView(compId: widget.compId, partner: p),
                        ),
                      );
                      if (res == true) _load();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: 'Sil',
                    onPressed: () async {
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Ortak silindi.' : 'Ortak silinemedi')));
                      if (ok) _load();
                    },
                  ),
                ],
              )),
            ],
          );
        }).toList(),
      ),
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
                              if ((_company!.partners).isNotEmpty)
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
                                    children: [
                                      _buildPartnersTable(_company!.partners),
                                    ],
                                  ),
                                ),
                              if (_company!.documents.isNotEmpty)
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
                              _InfoRow(label: 'Kep Adresi', value: _company!.compKepAddress ?? '-'),
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
                          if ((_company!.partners).isNotEmpty) ...[
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
                              children: [
                                _buildPartnersTable(_company!.partners),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (_company!.documents.isNotEmpty)
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
  const _Panel({required this.title, required this.icon, required this.children, this.actions});
  final String title;
  final IconData icon;
  final List<Widget> children;
  final List<Widget>? actions;

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


