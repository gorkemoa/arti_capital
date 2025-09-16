import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../viewmodels/companies_view_model.dart';
import 'company_detail_view.dart';

class CompaniesView extends StatelessWidget {
  const CompaniesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);
    return ChangeNotifierProvider(
      create: (_) => CompaniesViewModel(),
      child: Builder(
        builder: (context) {
          final vm = context.watch<CompaniesViewModel>();
          return Scaffold(
            appBar: AppBar(
              title: const Text('Firmalarım'),
              centerTitle: true,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: vm.refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final c = vm.companies[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: subtleBorder),
                          ),
                          child: ListTile(
                            leading: _logoWidget(c.compLogo, theme),
                            title: Text(c.compName, style: theme.textTheme.bodyMedium),
                            subtitle: Text(
                              '${c.compDistrict} / ${c.compCity}\n${c.compAddress}',
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => CompanyDetailView(compId: c.compID)),
                              );
                            },
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: vm.companies.length,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

Widget _logoWidget(String logo, ThemeData theme) {
  final bg = theme.colorScheme.surface;
  final border = theme.colorScheme.outline.withOpacity(0.12);
  Widget child;
  if (logo.isEmpty) {
    child = const Icon(Icons.apartment_outlined);
  } else if (logo.startsWith('data:image/')) {
    try {
      final parts = logo.split(',');
      if (parts.length == 2) {
        final bytes = base64Decode(parts[1]);
        child = Image.memory(bytes, fit: BoxFit.contain);
      } else {
        child = const Icon(Icons.apartment_outlined);
      }
    } catch (_) {
      child = const Icon(Icons.apartment_outlined);
    }
  } else if (logo.startsWith('http://') || logo.startsWith('https://')) {
    child = Image.network(logo, fit: BoxFit.contain);
  } else {
    child = const Icon(Icons.apartment_outlined);
  }
  return Container(
    width: 48,
    height: 48,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: border),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: FittedBox(fit: BoxFit.contain, child: child),
    ),
  );
}


