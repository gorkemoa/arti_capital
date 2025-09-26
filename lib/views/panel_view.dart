import 'dart:convert';
import 'package:arti_capital/views/companies_view.dart';
import 'package:arti_capital/views/documents_view.dart';
import 'package:arti_capital/services/storage_service.dart';
import 'package:arti_capital/views/support_view.dart';
import 'package:flutter/material.dart';
import 'package:arti_capital/views/requests_view.dart';
import 'package:arti_capital/views/messages_view.dart';
import 'package:arti_capital/views/reports_view.dart';

class PanelView extends StatelessWidget {
  const PanelView({super.key, required this.userName, required this.userVersion , required this.profilePhoto});
  final String userName;
  final String userVersion;
  final String profilePhoto;
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
          profilePhoto: profilePhoto,
        ),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
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
            const SizedBox(height: 10),
            _QuickActions(
              actions: [
                _QuickAction(
                  icon: Icons.add_circle_outline,
                  label: 'Destek Oluştur',
                  routeTitle: 'Yeni Kayıt',
                  builder: (context) => const SupportView(),
                ),
                _QuickAction(
                  icon: Icons.assignment_outlined,
                  label: 'Taleplerim',
                  routeTitle: 'Taleplerim',
                  builder: (context) => const RequestsView(),
                ),
                _QuickAction(
                  icon: Icons.chat_bubble_outline,
                  label: 'Mesajlar',
                  routeTitle: 'Mesajlar',
                  builder: (context) => const MessagesView(),
                ),
                _QuickAction(
                  icon: Icons.insights_outlined, 
                  label: 'Raporlar', 
                  routeTitle: 'Raporlar',
                  builder: (context) => const ReportsView(),
                ),
                _QuickAction(
                  icon: Icons.business_outlined,
                  label: 'Firmalarım',
                  routeTitle: 'Firmalarım',
                  builder: (context) => const CompaniesView(),
                  
                ),
                _QuickAction(
                  icon: Icons.description_outlined,
                  label: 'Belgelerim',
                  routeTitle: 'Belgelerim',
                  builder: (context) => const DocumentsView(),
                ),
                _QuickAction(
                  icon: Icons.folder_outlined,
                  label: 'Projeler',
                  routeTitle: 'Projeler',
                ),
                _QuickAction(
                  icon: Icons.warning_outlined,
                  label: 'Eksik Evraklar',
                  routeTitle: 'Eksik Evraklar',
                ),
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
              child: Builder(
                builder: (_) {
                  final dt = StorageService.getLastLoginAt();
                  String lastLoginText;
                  if (dt == null) {
                    lastLoginText = 'Son giriş: -';
                  } else {
                    final now = DateTime.now();
                    final local = dt.toLocal();
                    String hh = local.hour.toString().padLeft(2, '0');
                    String mm = local.minute.toString().padLeft(2, '0');
                    String dayPrefix;
                    final isSameDay = now.year == local.year && now.month == local.month && now.day == local.day;
                    if (isSameDay) {
                      dayPrefix = '';
                    } else {
                      dayPrefix = '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')} ';
                    }
                    lastLoginText = 'Son giriş: $dayPrefix$hh:$mm';
                  }
                  return Text(
                    '$lastLoginText  • Versiyon: $userVersion',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelAppBarTitle extends StatelessWidget {
  const _PanelAppBarTitle({required this.userName, required this.greeting, required this.profilePhoto});
  final String userName;
  final String greeting;
  final String profilePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
          backgroundImage: _resolveProfileImage(profilePhoto),
          child: _resolveProfileImage(profilePhoto) != null
              ? null
              : Text(
                  (userName.isNotEmpty ? userName.trim().characters.first : '?'),
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

  ImageProvider? _resolveProfileImage(String value) {
    if (value.isEmpty) return null;
    // http veya https ise doğrudan NetworkImage kullan
    if (value.startsWith('http')) {
      return NetworkImage(value);
    }
    // data:image/...;base64,xxxxx formatı
    if (value.startsWith('data:image')) {
      final commaIndex = value.indexOf(',');
      if (commaIndex != -1 && commaIndex + 1 < value.length) {
        final b64 = value.substring(commaIndex + 1);
        try {
          final bytes = base64Decode(b64);
          return MemoryImage(bytes);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }
}

String _greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 6) return 'İyi geceler';
  if (hour < 12) return 'Günaydın';
  if (hour < 18) return 'İyi günler';
  return 'İyi akşamlar';
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
        crossAxisSpacing: 10,
        mainAxisSpacing: 1,
        childAspectRatio: 0.85,
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
            MaterialPageRoute(
              builder: (_) => action.builder != null
                  ? action.builder!(context)
                  : _EmptyPage(title: action.routeTitle),
            ),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  action.label,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, height: 1.4, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({required this.icon, required this.label, required this.routeTitle, this.builder});
  final IconData icon;
  final String label;
  final String routeTitle;
  final WidgetBuilder? builder;
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


