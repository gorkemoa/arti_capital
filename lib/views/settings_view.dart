import 'package:flutter/material.dart';
import 'contact_view.dart';
import 'change_password_view.dart';
import '../services/user_service.dart';
import '../models/user_request_models.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

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
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: 'Genel'),
          _NavTile(
            icon: Icons.notifications_outlined,
            label: 'Bildirimler',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          _Divider(subtleBorder: subtleBorder),
          _NavTile(
            icon: Icons.language_outlined,
            label: 'Dil',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          _Divider(subtleBorder: subtleBorder),
          _NavTile(
            icon: Icons.support_agent_outlined,
            label: 'Bize Ulaşın',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContactView()),
              );
            },
          ),
          const SizedBox(height: 16),
          _Section(title: 'Gizlilik ve Güvenlik'),
          _NavTile(
            icon: Icons.lock_outline,
            label: 'Şifreyi değiştir',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordView()),
              );
            },
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
          _Divider(subtleBorder: subtleBorder),
          _NavTile(
            icon: Icons.delete_forever_outlined,
            label: 'Hesabı Sil',
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hesabı Sil'),
                  content: const Text('Hesabınızı kalıcı olarak silmek istediğinize emin misiniz?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
                  ],
                ),
              );
              if (confirmed != true) return;

              final token = StorageService.getToken();
              // Silme isteğini arka planda gönder (varsa)
              if (token != null) {
                // fire-and-forget: sonucu beklemiyoruz
                // kullanıcı hemen login ekranına yönlenecek
                // hata olursa yine de oturum kapatılacak
                // ve kullanıcı login ekranına düşecek
                // arka planda çalışma
                // ignore: unawaited_futures
                UserService().deleteUser(DeleteUserRequest(userToken: token));
              }

              // Oturumu hemen kapat ve login'e yönlendir
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
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
          _Divider(subtleBorder: subtleBorder),
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


