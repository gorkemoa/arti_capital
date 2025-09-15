import 'package:arti_capital/views/support_detail_view.dart';
import 'package:flutter/material.dart';

// Uygulama genelinde erişilebilir destek kategorileri
const List<String> kSupportCategories = ['Tümü', 'Ar-Ge', 'Ür-Ge', 'İstihdam', 'İhracat'];

class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _tabs = kSupportCategories;

  late final List<_GrantItem> _grants = <_GrantItem>[
    const _GrantItem(
      title: 'Ar-Ge Teşvikleri',
      description: 'Teknoloji geliştirme projelerinizi destekliyoruz.',
      category: 'Ar-Ge',
      icon: Icons.biotech_outlined,
    ),
    const _GrantItem(
      title: 'Ür-Ge Teşvikleri',
      description: 'Yeni ürün geliştirme süreçlerinizi destekliyoruz.',
      category: 'Ür-Ge',
      icon: Icons.lightbulb_outline,
    ),
    const _GrantItem(
      title: 'İstihdam Teşvikleri',
      description: 'Yeni personel alımlarınızı destekliyoruz.',
      category: 'İstihdam',
      icon: Icons.badge_outlined,
    ),
    const _GrantItem(
      title: 'İhracat Teşvikleri',
      description: 'Yurt dışı pazarlara açılmanızı destekliyoruz.',
      category: 'İhracat',
      icon: Icons.public_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
        foregroundColor: colorScheme.onBackground,
        title: Text('Destekler', style: theme.appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications_outlined,
              color: colorScheme.onPrimary,
            ),
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Destek ve Yardım Ara',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                indicatorColor: colorScheme.primary,
                indicatorWeight: 3,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withOpacity(0.7),
                labelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: theme.textTheme.bodyMedium,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Destek kartları
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final filtered = _filteredGrants(tab);
                return _buildGrantList(filtered);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<_GrantItem> _filteredGrants(String tab) {
    final query = _searchController.text.trim().toLowerCase();
    Iterable<_GrantItem> items = _grants;
    if (tab != 'Tümü') {
      items = items.where((g) => g.category == tab);
    }
    if (query.isNotEmpty) {
      items = items.where(
        (g) => g.title.toLowerCase().contains(query) || g.description.toLowerCase().contains(query),
      );
    }
    return items.toList();
  }

  Widget _buildGrantList(List<_GrantItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final g = items[index];
        return _buildSupportCard(g.title, g.description, g.icon, null);
      },
    );
  }

  Widget _buildSupportCard(String title, String description, IconData icon, Color? backgroundColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(description, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SupportDetailView(title: title),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    ),
                    child: Text('Detaylar', style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: backgroundColor ?? colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 28, color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrantItem {
  const _GrantItem({required this.title, required this.description, required this.category, required this.icon});
  final String title;
  final String description;
  final String category; // Ar-Ge, Ür-Ge, İstihdam, İhracat
  final IconData icon;
}
