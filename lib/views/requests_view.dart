import 'package:arti_capital/views/notifications_view.dart';
import 'package:flutter/material.dart';
import 'package:arti_capital/views/request_detail_view.dart';

class RequestsView extends StatefulWidget {
  const RequestsView({super.key});

  @override
  State<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends State<RequestsView> with TickerProviderStateMixin {
  late TabController _tabController;

  final List<_RequestItem> _items = const [
    _RequestItem(title: 'KOSGEB Girişimcilik Desteği', date: '15.08.2023', status: _RequestStatus.pending),
    _RequestItem(title: 'TÜBİTAK 1512 Desteği', date: '20.07.2023', status: _RequestStatus.approved),
    _RequestItem(title: 'Ar-Ge Teşvikleri', date: '05.06.2023', status: _RequestStatus.rejected),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: const Text('Başvurularım'),
        centerTitle: true,
        foregroundColor: colorScheme.onPrimary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        actions: [
          IconButton(
            tooltip: 'Bildirimler',
            onPressed: () {
              Navigator.of(context).pushNamed('/notifications');
            },
            style: IconButton.styleFrom(backgroundColor: Colors.white, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(8),
            iconSize: 24,
            
            ),
            icon: Icon(
              Icons.notifications_none,
              color: colorScheme.primary,
              size: theme.textTheme.headlineSmall?.fontSize,
               ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                tabs: const [
                  Tab(text: 'Tümü'),
                  Tab(text: 'Beklemede'),
                  Tab(text: 'Sonuçlandı'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(context, _items),
                _buildList(context, _items.where((e) => e.status == _RequestStatus.pending).toList()),
                _buildList(context, _items.where((e) => e.status != _RequestStatus.pending).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<_RequestItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _RequestCard(item: item);
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.item});
  final _RequestItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);
    return InkWell(
      onTap: () async {
        // Detay sayfasına git
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RequestDetailView(title: item.title),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: subtleBorder),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            _CircleIcon(icon: Icons.description_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(item.date, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.75))),
                ],
              ),
            ),
            _StatusChip(status: item.status),
          ],
        ),
      ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: colorScheme.onSurface.withOpacity(0.9), size: 22),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final _RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Map<_RequestStatus, Color> bg = {
      _RequestStatus.pending: colorScheme.primary,
      _RequestStatus.approved: Colors.green,
      _RequestStatus.rejected: colorScheme.error,
    };
    final label = {
      _RequestStatus.pending: 'Beklemede',
      _RequestStatus.approved: 'Onaylandı',
      _RequestStatus.rejected: 'Reddedildi',
    }[status]!;
    final color = bg[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: status == _RequestStatus.rejected ? colorScheme.onError : colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RequestItem {
  const _RequestItem({required this.title, required this.date, required this.status});
  final String title;
  final String date;
  final _RequestStatus status;
}

enum _RequestStatus { pending, approved, rejected }


