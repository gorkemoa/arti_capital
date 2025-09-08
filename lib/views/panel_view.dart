import 'package:flutter/material.dart';

class PanelView extends StatelessWidget {
  const PanelView({super.key, required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: _PanelAppBarTitle(
          userName: userName,
          greeting: _greetingForNow(),
        ),
        actions: [
          IconButton(
            tooltip: 'Bildirimler',
            onPressed: () {
              Navigator.of(context).pushNamed('/notifications');
            },
            icon: Icon(Icons.notifications_none, color: colorScheme.onPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileStatusCard(
              message: 'Profilinizde eksik bilgiler var. Lütfen tamamlayın.',
              onComplete: () {
                Navigator.of(context).pushNamed('/profile');
              },
            ),
            const SizedBox(height: 12),
            _AnnouncementCard(
              title: 'Güncelleme yayınlandı',
              description: 'Uygulamanın yeni sürümü şimdi App Store/Play Store’da!',
            ),
            const SizedBox(height: 16),
            Text('Hızlı İstatistikler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _StatsGrid(cards: const [
              _StatData(title: 'Bekleyen İşler', value: '7'),
              _StatData(title: 'Onay Bekleyenler', value: '3'),
              _StatData(title: 'Okunmamış Mesaj', value: '12'),
              _StatData(title: 'Bugünkü İşlem', value: '5'),
            ]),
            const SizedBox(height: 20),
            Text('Hızlı İşlemler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _QuickActions(
              actions: [
                _QuickAction(icon: Icons.add_circle_outline, label: 'Yeni Oluştur', routeTitle: 'Yeni Kayıt'),
                _QuickAction(icon: Icons.assignment_outlined, label: 'Taleplerim', routeTitle: 'Taleplerim'),
                _QuickAction(icon: Icons.chat_bubble_outline, label: 'Mesajlar', routeTitle: 'Mesajlar'),
                _QuickAction(icon: Icons.insights_outlined, label: 'Raporlar', routeTitle: 'Raporlar'),
              ],
            ),
            const SizedBox(height: 20),
            Text('Son Aktiviteler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _RecentActivities(
              items: [
                _ActivityItem(date: '12:45', title: 'Teklif güncellendi', status: 'Tamamlandı', statusColor: colorScheme.primary),
                _ActivityItem(date: '11:30', title: 'Yeni mesaj alındı', status: 'Okunmadı', statusColor: colorScheme.primary),
                _ActivityItem(date: 'Dün', title: 'Talep oluşturuldu', status: 'Bekliyor', statusColor: colorScheme.primary),
                _ActivityItem(date: 'Dün', title: 'Profil bilgisi güncellendi', status: 'Tamamlandı', statusColor: colorScheme.primary),
                _ActivityItem(date: '2 gün önce', title: 'Rapor indirildi', status: 'Tamamlandı', statusColor: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Son giriş: 10:22  •  Versiyon: 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelAppBarTitle extends StatelessWidget {
  const _PanelAppBarTitle({required this.userName, required this.greeting});
  final String userName;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
          child: Text(
            _initials(userName),
            style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              greeting,
              style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onPrimary.withOpacity(0.9)),
            ),
            Text(
              userName,
              style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

String _greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 6) return 'İyi geceler';
  if (hour < 12) return 'Günaydın';
  if (hour < 18) return 'İyi günler';
  return 'İyi akşamlar';
}

class _ProfileStatusCard extends StatelessWidget {
  const _ProfileStatusCard({required this.message, required this.onComplete});
  final String message;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subtleBorder),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onComplete,
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subtleBorder),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.cards});
  final List<_StatData> cards;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return _StatCard(title: card.title, value: card.value);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData({required this.title, required this.value});
  final String title;
  final String value;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.actions});
  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _QuickActionButton(action: action);
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => _EmptyPage(title: action.routeTitle)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({required this.icon, required this.label, required this.routeTitle});
  final IconData icon;
  final String label;
  final String routeTitle;
}

class _RecentActivities extends StatelessWidget {
  const _RecentActivities({required this.items});
  final List<_ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.08);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subtleBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: subtleBorder),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: Text(item.date, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
            title: Text(item.title, style: theme.textTheme.bodyMedium),
            trailing: _StatusChip(label: item.status, color: item.statusColor),
            dense: true,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({required this.date, required this.title, required this.status, required this.statusColor});
  final String date;
  final String title;
  final String status;
  final Color statusColor;
}

class _EmptyPage extends StatelessWidget {
  const _EmptyPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('Bu sayfa yakında burada olacak', style: theme.textTheme.titleMedium),
      ),
    );
  }
}


