import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.surface,
                              child: const Icon(Icons.apartment_outlined),
                            ),
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


