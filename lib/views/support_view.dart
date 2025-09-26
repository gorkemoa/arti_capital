import 'package:arti_capital/views/support_detail_view.dart';
import 'package:flutter/material.dart';
import '../models/support_models.dart';
import '../services/general_service.dart';

// Uygulama genelinde erişilebilir destek kategorileri

class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  final TextEditingController _searchController = TextEditingController();
  final GeneralService _generalService = GeneralService();
  List<ServiceItem> _services = <ServiceItem>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  void dispose() {
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
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              tooltip: 'Bildirimler',
              onPressed: () {
                Navigator.of(context).pushNamed('/notifications');
              },
              style: IconButton.styleFrom(backgroundColor: Colors.white, 
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
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Destek ve Yardım Ara',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 1),
          
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
    final filtered = _filteredServices();
    return _buildServiceList(filtered);
  }

  List<ServiceItem> _filteredServices() {
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
        return _buildSupportCardWithId(s.serviceID, s.serviceName, s.serviceDesc, Icons.info_outline, null);
      },
    );
  }

  Widget _buildSupportCardWithId(int id, String title, String description, IconData icon, Color? backgroundColor) {
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
                          builder: (_) => SupportDetailView(id: id),
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
