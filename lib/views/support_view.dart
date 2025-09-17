import 'package:arti_capital/views/support_detail_view.dart';
import 'package:flutter/material.dart';
import '../models/support_models.dart';
import '../services/general_service.dart';

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
  final GeneralService _generalService = GeneralService();
  List<ServiceItem> _services = <ServiceItem>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchServices();
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
            child: _buildBodyContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    return TabBarView(
      controller: _tabController,
      children: _tabs.map((tab) {
        final filtered = _filteredServices(tab);
        return _buildServiceList(filtered);
      }).toList(),
    );
  }

  List<ServiceItem> _filteredServices(String tab) {
    final query = _searchController.text.trim().toLowerCase();
    Iterable<ServiceItem> items = _services;
    // Kategori şu an API’de yok; taslak olarak tümünde gösteriyoruz.
    if (query.isNotEmpty) {
      items = items.where(
        (g) => g.serviceName.toLowerCase().contains(query) || g.serviceDesc.toLowerCase().contains(query),
      );
    }
    return items.toList();
  }

  Widget _buildServiceList(List<ServiceItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = items[index];
        return _buildSupportCard(s.serviceName, s.serviceDesc, Icons.info_outline, null);
      },
    );
  }

  Widget _buildSupportCard(String title, String description, IconData icon, Color? backgroundColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String shortDesc = description.length > 100 ? description.substring(0, 100) + '...' : description;
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
                  Text(shortDesc, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SupportDetailView(title: title, description: description),
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
  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _generalService.getAllServices();
      setState(() {
        _services = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Destekler yüklenirken bir hata oluştu';
      });
    }
  }
}
