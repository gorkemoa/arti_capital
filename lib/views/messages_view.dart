import 'package:flutter/material.dart';
import 'package:arti_capital/views/message_detail_view.dart';

class MessagesView extends StatelessWidget {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final List<_MessagePreview> items = const [
      _MessagePreview(sender: 'Destek', snippet: 'Size nasıl yardımcı olabiliriz?', time: '12:30'),
      _MessagePreview(sender: 'Sistem', snippet: 'Başvurunuz güncellendi.', time: 'Dün'),
      _MessagePreview(sender: 'Danışman', snippet: 'Toplantıyı 15:00’e alalım mı?', time: 'Pzt'),
    ];

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: const Text('Mesajlar'),
        centerTitle: true,
        foregroundColor: colorScheme.onPrimary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return _MessageTile(item: item);
        },
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.item});
  final _MessagePreview item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MessageDetailView(peerName: item.sender),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: subtleBorder),
          boxShadow: [
            BoxShadow(color: theme.shadowColor.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              child: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.sender, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
                      Text(item.time, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagePreview {
  const _MessagePreview({required this.sender, required this.snippet, required this.time});
  final String sender;
  final String snippet;
  final String time;
}


