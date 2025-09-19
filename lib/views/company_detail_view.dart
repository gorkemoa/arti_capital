import 'package:flutter/material.dart';
import 'dart:convert';

import '../models/company_models.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import 'edit_company_view.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firma Detayı'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
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
                                    _InfoRow(label: 'Vergi Dairesi', value: _company!.compTaxPalace ?? '-'),
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
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 3,
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


