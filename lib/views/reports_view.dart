import 'package:flutter/material.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  String _selectedStatus = 'Tümü';
  String _selectedProject = 'Tümü';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Raporlar',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          _buildExportButton(context),
          IconButton(
            icon: Icon(Icons.share, color: colorScheme.onPrimary),
            onPressed: () => _showShareOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtre Çubuğu
            _buildFilterBar(),
            const SizedBox(height: 24),

            // Hızlı Özet Kartları
            _buildQuickSummaryCards(theme),
            const SizedBox(height: 24),

            // Genel Başvuru Tablosu
            _buildApplicationsTable(theme),
            const SizedBox(height: 24),

            // Mali Raporlar
            _buildFinancialReports(theme),
            const SizedBox(height: 24),

            // Performans & İstatistikler
            _buildPerformanceStats(theme),
            const SizedBox(height: 24),

            // Bildirim & Takip
            _buildNotificationsAndTracking(theme),
            const SizedBox(height: 16),

         
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.download, color: Theme.of(context).colorScheme.onPrimary),
      onSelected: (value) => _handleExport(value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pdf', child: Text('PDF İndir')),
        const PopupMenuItem(value: 'excel', child: Text('Excel İndir')),
      ],
    );
  }

  Widget _buildFilterBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 700;
          if (isWide) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildDateRangeField()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildProjectDropdown()),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSearchField(),
              ],
            );
          }
          // Dar ekran: dikey yerleşim
          return Column(
            children: [
              _buildDateRangeField(),
              const SizedBox(height: 12),
              _buildStatusDropdown(),
              const SizedBox(height: 12),
              _buildProjectDropdown(),
              const SizedBox(height: 12),
              _buildSearchField(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateRangeField() {
    return InkWell(
      onTap: () => _selectDateRange(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, size: 16, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDateRange == null
                    ? 'Tarih Aralığı'
                    : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: const InputDecoration(
        isDense: true,
        labelText: 'Durum',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ['Tümü', 'İncelemede', 'Onaylı', 'Reddedilen']
          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
          .toList(),
      onChanged: (value) => setState(() => _selectedStatus = value!),
    );
  }

  Widget _buildProjectDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedProject,
      decoration: const InputDecoration(
        isDense: true,
        labelText: 'Proje',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ['Tümü', 'AR-GE Projesi', 'İhracat Desteği', 'Teknoloji Transferi']
          .map((project) => DropdownMenuItem(value: project, child: Text(project)))
          .toList(),
      onChanged: (value) => setState(() => _selectedProject = value!),
    );
  }

  Widget _buildSearchField() {
    return TextField(
            textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: 'Proje adı veya açıklama ile arama yapın...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  Widget _buildQuickSummaryCards(ThemeData theme) {
    final cards = [
      _SummaryCard(title: 'Toplam Başvuru', value: '47', icon: Icons.assignment_outlined, color: theme.colorScheme.primary),
      _SummaryCard(title: 'Onaylanan', value: '23', icon: Icons.check_circle_outline, color: Colors.green),
      _SummaryCard(title: 'İncelemede', value: '18', icon: Icons.schedule, color: Colors.orange),
      _SummaryCard(title: 'Reddedilen', value: '6', icon: Icons.cancel_outlined, color: Colors.red),
      _SummaryCard(title: 'Toplam Onaylı Destek', value: '₺2.4M', icon: Icons.paid_outlined, color: Colors.blue),
      _SummaryCard(title: 'Bekleyen Ödeme', value: '₺850K', icon: Icons.hourglass_empty, color: Colors.purple),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hızlı Özet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Ekran genişliğine göre sabit kolon sayısı ile daha dengeli ızgara
            final int crossAxisCount = (constraints.maxWidth ~/ 240).clamp(2, 4);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) => _buildSummaryCard(cards[index], theme),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(_SummaryCard card, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(minHeight: 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(card.icon, color: card.color, size: 24),
          const SizedBox(height: 8),
          Text(
            card.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: card.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.title,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsTable(ThemeData theme) {
    final allApplications = [
      _ApplicationData(name: 'Akıllı Sensör Geliştirme', project: 'AR-GE Projesi', date: '15.03.2024', status: 'Onaylı', amount: '₺425.000', statusColor: Colors.green),
      _ApplicationData(name: 'İhracat Pazarlama Desteği', project: 'İhracat Desteği', date: '08.03.2024', status: 'İncelemede', amount: '₺180.000', statusColor: Colors.orange),
      _ApplicationData(name: 'Yazılım Geliştirme Projesi', project: 'AR-GE Projesi', date: '22.02.2024', status: 'Onaylı', amount: '₺320.000', statusColor: Colors.green),
      _ApplicationData(name: 'Makine İmalat Desteği', project: 'Teknoloji Transferi', date: '10.02.2024', status: 'Reddedilen', amount: '₺650.000', statusColor: Colors.red),
      _ApplicationData(name: 'Dijital Dönüşüm Projesi', project: 'AR-GE Projesi', date: '05.02.2024', status: 'İncelemede', amount: '₺280.000', statusColor: Colors.orange),
    ];

    // Filtrele
    final applications = allApplications.where((app) {
      final matchesSearch = _searchQuery.isEmpty || 
                           app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           app.project.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == 'Tümü' || app.status == _selectedStatus;
      final matchesProject = _selectedProject == 'Tümü' || app.project == _selectedProject;
      return matchesSearch && matchesStatus && matchesProject;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Genel Başvuru Tablosu', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        // Yatay kaydırma: küçük ekranlarda sığmayan tablo için
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  // Tablo başlığı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 280, child: Text('Proje Adı', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600))),
                        SizedBox(width: 180, child: Text('Kategori', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600))),
                        SizedBox(width: 100, child: Text('Tarih', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600))),
                        SizedBox(width: 120, child: Text('Durum', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600))),
                        SizedBox(width: 120, child: Text('Tutar', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600))),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  // Tablo satırları
                  ...applications.asMap().entries.map((entry) {
                    final index = entry.key;
                    final app = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: index < applications.length - 1
                            ? Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)))
                            : null,
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 280, child: Text(app.name, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
                          SizedBox(width: 180, child: Text(app.project, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                          SizedBox(width: 100, child: Text(app.date, style: theme.textTheme.bodySmall)),
                          SizedBox(
                            width: 120,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: app.statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  app.status,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: app.statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 120, child: Text(app.amount, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                          SizedBox(
                            width: 40,
                            child: IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 18),
                              onPressed: () => _showProjectDetail(app),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialReports(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mali Raporlar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Tüm ekran boyutlarında 2x2 ızgara (4'lü, 2'ye 2)
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: constraints.maxWidth >= 800 ? 16 : 12,
                mainAxisSpacing: constraints.maxWidth >= 800 ? 16 : 12,
                childAspectRatio: constraints.maxWidth >= 800 ? 1.6 : 1.2,
              ),
              children: [
                _buildFinancialCard('Onaylı Destek Toplamı', '₺2.4M', Colors.green, theme),
                _buildFinancialCard('Bekleyen Destek', '₺850K', Colors.orange, theme),
                _buildFinancialCard('Şirket Katkısı', '₺1.2M', Colors.blue, theme),
                _buildFinancialBarPlaceholder(theme),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        // Projeye göre liste
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Projeye Göre Alınan/Alınacak', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...['Akıllı Sensör Geliştirme', 'Yazılım Geliştirme', 'Dijital Dönüşüm'].map((project) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(project, style: theme.textTheme.bodySmall)),
                      Expanded(child: Text('₺425K', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green))),
                      Expanded(child: Text('₺125K', style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange))),
                      Expanded(child: Text('15.06.2024', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)))),
                    ],
                  ),
                ),
              ).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard(String title, String value, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      constraints: const BoxConstraints(minHeight: 110),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Grafik placeholder'ını tek bir fonksiyona aldık
  Widget _buildFinancialBarPlaceholder(ThemeData theme) {
    return Container(
            child: _buildFinancialCard('Devlet Desteği', '₺1.2M', Colors.red, theme),

    );
  }

  Widget _buildPerformanceStats(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performans & İstatistikler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 800;
            Widget lineChart = Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Son 6 Ay Başvuru Adedi',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.trending_up, size: 32, color: theme.colorScheme.primary.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text('Trend Grafiği', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
            Widget pieChart = Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Sektör Dağılımı',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart, size: 32, color: theme.colorScheme.primary.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text('Dağılım Grafiği', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
            if (isWide) {
              return Row(
                children: [
                  Expanded(child: lineChart),
                  const SizedBox(width: 16),
                  Expanded(child: pieChart),
                ],
              );
            }
            return Column(
              children: [
                lineChart,
                const SizedBox(height: 16),
                pieChart,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        // Vurgu kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'En çok destek alınan alan: AR-GE Projeleri (%65)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsAndTracking(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bildirim & Takip', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 800;
            Widget deadlinesCard = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yaklaşan Son Başvuru Tarihleri', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...['TÜBİTAK 1501 - 28.09.2024', 'KOSGEB AR-GE - 15.10.2024', 'Teknogirişim - 22.10.2024'].map((deadline) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(deadline, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ).toList(),
                ],
              ),
            );
            Widget missingDocsCard = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Eksik Evraklar', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...['Proforma Fatura - Akıllı Sensör', 'İmza Sirküleri - Yazılım Proj.', 'Mali Tablo - Dijital Dönüşüm'].map((doc) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.warning, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(doc, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Yükle'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ],
              ),
            );
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: deadlinesCard),
                  const SizedBox(width: 16),
                  Expanded(child: missingDocsCard),
                ],
              );
            }
            return Column(
              children: [
                deadlinesCard,
                const SizedBox(height: 16),
                missingDocsCard,
              ],
            );
          },
        ),
         ],
    );
  }



  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _handleExport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$type formatında dışa aktarılıyor...')),
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('E-posta ile Paylaş'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Bağlantı Kopyala'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectDetail(_ApplicationData app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(app.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Proje: ${app.project}'),
            const SizedBox(height: 8),
            Text('Başvuru Tarihi: ${app.date}'),
            const SizedBox(height: 8),
            Text('Durum: ${app.status}'),
            const SizedBox(height: 8),
            Text('Tutar: ${app.amount}'),
            const SizedBox(height: 16),
            Text('Proje detay sayfası burada açılacak...'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Detay Sayfasına Git')),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // _formatDateTime kaldırıldı (kullanılmıyor)
}

// Veri modelleri
class _SummaryCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _ApplicationData {
  final String name;
  final String project;
  final String date;
  final String status;
  final String amount;
  final Color statusColor;

  const _ApplicationData({
    required this.name,
    required this.project,
    required this.date,
    required this.status,
    required this.amount,
    required this.statusColor,
  });
}
