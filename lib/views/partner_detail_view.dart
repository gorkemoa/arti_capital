import 'package:flutter/material.dart';

import '../models/company_models.dart';
import '../services/company_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import 'add_company_document_view.dart';
import 'edit_company_document_view.dart';
import 'document_preview_view.dart';
import 'edit_company_partner_view.dart';

class PartnerDetailView extends StatefulWidget {
  const PartnerDetailView({super.key, required this.compId, required this.partner});
  final int compId;
  final PartnerItem partner;

  @override
  State<PartnerDetailView> createState() => _PartnerDetailViewState();
}

class _PartnerDetailViewState extends State<PartnerDetailView> {
  PartnerItem? _partner;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _partner = widget.partner;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    final comp = await CompanyService().getCompanyDetail(widget.compId);
    if (!mounted) return;
    setState(() {
      // Güncel ortak bilgilerini al
      if (comp != null) {
        _partner = comp.partners.firstWhere(
          (p) => p.partnerID == widget.partner.partnerID,
          orElse: () => widget.partner,
        );
      }
      _loading = false;
    });
  }

  Future<void> _updateDocument(CompanyDocumentItem doc) async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditCompanyDocumentView(
          compId: widget.compId,
          document: doc,
          partnerID: _partner?.partnerID,
        ),
      ),
    );
    if (res == true) _load();
  }

  Future<void> _deleteDocument(CompanyDocumentItem doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Belgeyi Sil'),
        content: Text('${doc.documentType} belgesini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = await StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }

    final ok = await CompanyService().deleteCompanyDocument(
      userToken: token,
      compId: widget.compId,
      documentId: doc.documentID,
      partnerID: _partner?.partnerID ?? 0,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belge silindi')));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belge silinemedi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ortak Detayı'),
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
                  builder: (_) => AddCompanyDocumentView(
                    compId: widget.compId,
                    partnerID: _partner?.partnerID,
                  ),
                ),
              );
              if (res == true) {
                _load();
              }
            },
          ),
          if (!_loading && _partner != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => EditCompanyPartnerView(compId: widget.compId, partner: _partner!),
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
          : _partner == null
              ? const Center(child: Text('Ortak bilgileri yüklenemedi'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ortak Bilgileri
                      _Panel(
                        title: 'Ortak Bilgileri',
                        icon: Icons.person_outlined,
                        children: [
                          _InfoRow('Ad Soyad', (_partner!.partnerFullname.isNotEmpty ? _partner!.partnerFullname : _partner!.partnerName).toUpperCase()),
                          if (_partner!.partnerIdentityNo.isNotEmpty)
                            _InfoRow('T.C. No', _partner!.partnerIdentityNo),
                          if (_partner!.partnerBirthday.isNotEmpty)
                            _InfoRow('Doğum Tarihi', _partner!.partnerBirthday),
                          if (_partner!.partnerTitle.isNotEmpty)
                            _InfoRow('Unvan', _partner!.partnerTitle.toUpperCase()),
                          if (_partner!.partnerTaxNo.isNotEmpty)
                            _InfoRow('Vergi No', _partner!.partnerTaxNo),
                          _InfoRow('Vergi Dairesi', _partner!.partnerTaxPalace),
                          _InfoRow('Şehir/İlçe', '${_partner!.partnerCity}/${_partner!.partnerDistrict}'),
                          if (_partner!.partnerAddress.isNotEmpty)
                            _InfoRow('Adres', _partner!.partnerAddress),
                          _InfoRow('Hisse Oranı', _partner!.partnerShareRatio),
                          _InfoRow('Hisse Tutarı', _partner!.partnerSharePrice),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Belgeler
                      _Panel(
                        title: 'Ortak Belgeleri',
                        icon: Icons.folder_outlined,
                        children: [
                          if (_partner!.documents.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'Henüz belge eklenmemiş',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (final doc in _partner!.documents)
                                  ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.description_outlined),
                                    title: Text(
                                      doc.documentType,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              'Yükleme Tarihi: ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                doc.createDate,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          
                                          ],
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
                                              Expanded(
                                                child: Text(
                                                  doc.documentValidityDate,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
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
                                    isThreeLine: (doc.documentValidityDate.isNotEmpty) || 
                                                 (doc.documentDesc != null && doc.documentDesc!.isNotEmpty),
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
                                    trailing: PopupMenuButton<String>(
                                      tooltip: 'Aksiyonlar',
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _updateDocument(doc);
                                        } else if (value == 'delete') {
                                          _deleteDocument(doc);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem<String>(
                                          value: 'edit',
                                          child: ListTile(
                                            leading: Icon(Icons.edit_outlined),
                                            title: Text('Güncelle'),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                                            title: Text('Sil'),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
