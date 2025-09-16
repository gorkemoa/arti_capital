import 'package:flutter/material.dart';

import '../models/company_models.dart';
import '../services/user_service.dart';

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
    final comp = await UserService().getCompanyDetail(widget.compId);
    if (!mounted) return;
    setState(() {
      _company = comp;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firma Detayı'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_company == null)
              ? const Center(child: Text('Firma bulunamadı'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: theme.colorScheme.surface,
                        child: const Icon(Icons.apartment_outlined, size: 44),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Section(title: 'Firma Bilgileri'),
                    _Tile(label: 'Adı', value: _company!.compName, icon: Icons.badge_outlined),
                    _Tile(label: 'Tür', value: _company!.compType ?? '-', icon: Icons.category_outlined),
                    _Tile(label: 'Vergi No', value: _company!.compTaxNo ?? '-', icon: Icons.receipt_long_outlined),
                    _Tile(label: 'Vergi Dairesi', value: _company!.compTaxPalace ?? '-', icon: Icons.apartment),
                    _Tile(label: 'MERSİS', value: _company!.compMersisNo ?? '-', icon: Icons.confirmation_number_outlined),
                    const SizedBox(height: 12),
                    _Section(title: 'Adres'),
                    _Tile(label: 'İl / İlçe', value: '${_company!.compCity} / ${_company!.compDistrict}', icon: Icons.location_city_outlined),
                    _Tile(label: 'Adres', value: _company!.compAddress, icon: Icons.place_outlined),
                  ],
                ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subtleBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.7)),
        title: Text(label, style: theme.textTheme.bodyMedium),
        subtitle: Text(value, style: theme.textTheme.bodySmall),
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}


