import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: 'Genel'),
          _NavTile(
            icon: Icons.notifications_outlined,
            label: 'Bildirimler',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          _Divider(subtleBorder: subtleBorder),
          _NavTile(
            icon: Icons.language_outlined,
            label: 'Dil',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _Section(title: 'Gizlilik ve Güvenlik'),
          _NavTile(
            icon: Icons.lock_outline,
            label: 'Şifreyi değiştir',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          _Divider(subtleBorder: subtleBorder),
          _NavTile(
            icon: Icons.shield_outlined,
            label: 'İki Aşamalı Doğrulama',
            trailing: Switch(
              value: false,
              onChanged: (_) {},
            ),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _Section(title: 'Hakkında'),
          _NavTile(
            icon: Icons.info_outline,
            label: 'Sürüm Bilgisi',
            trailing: Text(
              'Uygulama',
              style: theme.textTheme.bodySmall,
            ),
            onTap: () {},
          ),
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

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.label, this.trailing, this.onTap});
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subtleBorder),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.7)),
        title: Text(label, style: theme.textTheme.bodyMedium),
        trailing: trailing,
        dense: true,
        visualDensity: VisualDensity.compact,
        onTap: onTap,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.subtleBorder});
  final Color subtleBorder;
  @override
  Widget build(BuildContext context) {
    return Container(height: 8);
  }
}


