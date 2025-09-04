import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/notifications_view_model.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ChangeNotifierProvider(
      create: (_) => NotificationsViewModel(),
      child: Builder(
        builder: (context) {
          final vm = context.watch<NotificationsViewModel>();
          return Scaffold(
            appBar: AppBar(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              title: const Text('Bildirimler'),
            ),
            body: Builder(
              builder: (_) {
                if (vm.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (vm.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: 8),
                          Text(vm.errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<NotificationsViewModel>().load(),
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final items = vm.notifications;
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Gösterilecek bildirim yok'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<NotificationsViewModel>().load(),
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 16,
                      endIndent: 16,
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                    itemBuilder: (context, index) {
                      final n = items[index];
                      return ListTile(
                        leading: Icon(
                          n.isRead ? Icons.notifications_none : Icons.notifications_active,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(n.title),
                        subtitle: Text(n.body),
                        trailing: Text(
                          n.createDate,
                          style: theme.textTheme.bodySmall,
                        ),
                        onTap: () {},
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}


