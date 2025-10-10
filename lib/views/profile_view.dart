import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../viewmodels/profile_view_model.dart';
import 'profile_edit_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: Builder(
        builder: (context) {
          final vm = context.watch<ProfileViewModel>();
          return Scaffold(
            backgroundColor: theme.colorScheme.background,
            appBar: AppBar(
              backgroundColor: theme.colorScheme.primary,
              title: const Text('Profil'),
              centerTitle: true,
              actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                           tooltip: 'Ayarlar',

              onPressed: () {
                Navigator.of(context).pushNamed('/settings');
              },
              style: IconButton.styleFrom(backgroundColor: Colors.white, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(8),
            iconSize: 24,
            
            ),
              icon: Icon(Icons.settings_outlined, color: theme.colorScheme.primary, size: theme.textTheme.headlineSmall?.fontSize),
                      ),

              ),
            
              ],
            ),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.user != null
                    ? _ProfileContent(
                        user: vm.user!,
                        onRefresh: vm.refresh,
                        onLogout: vm.logout,
                      )
                    : _buildError(context, vm.errorMessage ?? 'Profil bilgileri alınamadı'),
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Düzenleme alt sayfası ayrı bir ekrana taşındı: see `ProfileEditView`

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user, required this.onRefresh, required this.onLogout});

  final User user;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: colorScheme.surface,
                  backgroundImage: (user.profilePhoto.isNotEmpty)
                      ? NetworkImage(user.profilePhoto) as ImageProvider
                      : null,
                  child: user.profilePhoto.isEmpty
                      ? Text(
                          _initials(user.userFullname),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user.userFullname,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  user.userEmail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Hesap',
            trailingLabel: 'Düzenle',
            onTrailingPressed: () {
              final vm = context.read<ProfileViewModel>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: vm,
                    child: const ProfileEditView(),
                  ),
                ),
              );
            },
          ),
          _Tile(label: 'Kimlik No', value: user.userIdentityNo, icon: Icons.person_outline),
          _Tile(label: 'Adı Soyadı', value: user.userFullname, icon: Icons.account_circle_outlined),
          _Tile(label: 'Telefon', value: user.userPhone, icon: Icons.phone_outlined),
          _Tile(label: 'Cinsiyet', value: user.userGender, icon: Icons.wc_outlined),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await onLogout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.trailingLabel, this.onTrailingPressed});
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingPressed;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailingLabel != null && onTrailingPressed != null)
            TextButton(
              onPressed: onTrailingPressed,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                trailingLabel!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
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


 


