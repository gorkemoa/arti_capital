import 'package:arti_capital/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/home_view_model.dart';
import '../widgets/app_bottom_nav.dart';
import 'profile_view.dart';
import 'panel_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Builder(
        builder: (context) {
          final vm = context.watch<HomeViewModel>();
          return Scaffold(
            backgroundColor: theme.colorScheme.background,
            bottomNavigationBar: AppBottomNav(
              currentIndex: vm.currentIndex,
              onTap: vm.setCurrentIndex,
            ),
            body: _buildIndexedBody(context, vm),
          );
        },
      ),
    );
  }

}

// Bottom navigation, ortak bileşen AppBottomNav ile sağlanıyor.

Widget _buildIndexedBody(BuildContext context, HomeViewModel vm) {
  if (vm.currentIndex == 0) {
    final userName = vm.user?.userFullname.isNotEmpty == true
        ? vm.user!.userFullname
        : (vm.user?.userName.isNotEmpty == true ? vm.user!.userName : 'Kullanıcı');
    return PanelView(userName: userName);
  }
  if (vm.currentIndex == 2) {
    return const ProfileView();
  }

  if (vm.loading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (vm.user != null) {
    return _HomeContent(
      user: vm.user!,
      onLogout: () async {
        await vm.logout();
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      onRefresh: vm.refresh,
    );
  }

  return _buildError(context, vm.errorMessage ?? 'Kullanıcı bilgileri alınamadı');
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
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/login');
          },
          child: const Text('Giriş Sayfasına Dön'),
        ),
      ],
    ),
  );
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.user, required this.onLogout, required this.onRefresh});

  final User user;
  final Future<void> Function() onLogout;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 210,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/notifications');
              },
              icon: const Icon(Icons.notifications_none),
            ),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline)),
 
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(bottom: 20),
              title: _CollapsingTitle(text: 'Ana Sayfa'),
              centerTitle: true,
              background: _Header(user: user),
            ),

          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _StatsGrid(user: user),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: _UserDetailsCard(user: user),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: _TokenCard(token: user.userToken),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: colorScheme.onPrimary.withOpacity(0.15),
              backgroundImage: (user.profilePhoto.isNotEmpty)
                  ? NetworkImage(user.profilePhoto) as ImageProvider
                  : null,
              child: user.profilePhoto.isEmpty
                  ? Text(
                      _initials(user.userFullname),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user.userFullname,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.userEmail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimary.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.user});
  final User user;
  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      children: [
        _StatCard(title: 'Kullanıcı ID', value: user.userID.toString()),
        _StatCard(title: 'Rütbe', value: user.userRank),
        _StatCard(title: 'Platform', value: user.platform.toUpperCase()),
        _StatCard(
          title: user.platform.toLowerCase() == 'ios' ? 'iOS Versiyon' : 'Android Versiyon',
          value: user.platform.toLowerCase() == 'ios' ? user.iOSVersion : user.androidVersion,
        ),
      ],
    );
  }
}

class _CollapsingTitle extends StatelessWidget {
  const _CollapsingTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Title, yalnızca app bar çöktüğünde görünür olacak şekilde opaklığı animasyonla artırılır.
    return LayoutBuilder(
      builder: (context, constraints) {
        // FlexibleSpaceBar, yüksekliği 0..expandedHeight aralığında verir. Yaklaşık bir görünürlük oranı hesaplayalım.
        final maxExtent = (constraints.biggest.height).clamp(0.0, 240.0);
        // 56 px civarı çökük durum, 200+ px genişlemiş durum varsayımıyla normalize edelim.
        final t = (1 - ((maxExtent - 56) / (210 - 90))).clamp(0.0, 1.0);
        // Tam beyaz için ara saydamlıklar yerine ikili görünürlük kullan.
        final opacity = t > 0.6 ? 1.0 : 0.0;
        return Opacity(
          opacity: opacity,
          child: Text(
            text,
            style: theme.appBarTheme.titleTextStyle?.copyWith(color: Colors.white),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, this.value});
  final String title;
  final String? value; // null ise veri yok -> skeleton/N/A

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          if (value == null)
            SizedBox(
              height: 20,
              width: 60,
              child: LinearProgressIndicator(
                backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                color: theme.colorScheme.primary,
              ),
            )
          else
            Text(
              value!,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

class _UserDetailsCard extends StatelessWidget {
  const _UserDetailsCard({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kullanıcı Bilgileri', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _InfoRow(label: 'Kullanıcı Adı', value: user.userName),
          _InfoRow(label: 'Ad Soyad', value: user.userFullname),
          _InfoRow(label: 'E-posta', value: user.userEmail),
          _InfoRow(label: 'Telefon', value: user.userPhone),
          _InfoRow(label: 'Cinsiyet', value: user.userGender),
          _InfoRow(label: 'Rütbe', value: user.userRank),
          _InfoRow(label: 'Platform', value: user.platform),
          _InfoRow(label: 'Versiyon', value: user.userVersion),
        ],
      ),
    );
  }
}

class _TokenCard extends StatelessWidget {
  const _TokenCard({required this.token});
  final String token;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Token Bilgisi', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            child: Text(token, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Poppins')),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
