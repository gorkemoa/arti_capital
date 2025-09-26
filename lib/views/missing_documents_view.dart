import 'package:flutter/material.dart';

class MissingDocumentsView extends StatelessWidget {
  const MissingDocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        title: Text('Eksik Evraklar', style: theme.appBarTheme.titleTextStyle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              tooltip: 'Bildirimler',
              onPressed: () {
                Navigator.of(context).pushNamed('/notifications');
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(1),
                iconSize: 20,
              ),
              icon: Icon(
                Icons.notifications_none,
                color: colorScheme.primary,
                size: theme.textTheme.headlineSmall?.fontSize,
              ),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _Panel(
            title: 'Genel Durum',
            icon: Icons.info_outline,
            children: [
              _EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'Eksik evrak bulunmuyor',
                subtitle: 'Tüm zorunlu evraklarınız mevcut görünüyor.',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Panel(
            title: 'Firma Bazlı Eksikler',
            icon: Icons.apartment_outlined,
            children: [
              _SectionInfo(text: 'Şu an listelenecek bir eksik evrak bulunamadı.'),
            ],
          ),
          const SizedBox(height: 12),
          _Panel(
            title: 'Ortak Bazlı Eksikler',
            icon: Icons.people_alt_outlined,
            children: [
              _SectionInfo(text: 'Şu an listelenecek bir eksik evrak bulunamadı.'),
            ],
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
    final border = theme.colorScheme.outline.withOpacity(0.12);
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
              color: theme.colorScheme.surface,
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
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 28, color: colorScheme.primary),
        ),
        const SizedBox(height: 12),
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SectionInfo extends StatelessWidget {
  const _SectionInfo({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: theme.textTheme.bodySmall),
      ),
    );
  }
}


