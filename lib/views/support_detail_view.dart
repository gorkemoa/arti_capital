import 'package:flutter/material.dart';
import '../models/support_models.dart';
import '../services/general_service.dart';
class SupportDetailView extends StatefulWidget {
  const SupportDetailView({super.key, required this.id});

  final int id;

  @override
  State<SupportDetailView> createState() => _SupportDetailViewState();
}

class _SupportDetailViewState extends State<SupportDetailView> {
  final GeneralService _service = GeneralService();
  ServiceItem? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _service.getServiceDetail(widget.id);
      setState(() {
        _detail = d;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Detay yüklenemedi';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _detail?.serviceName ?? 'Destek Detayı';
    final description = _detail?.serviceDesc ?? '';
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Text(title, style: theme.appBarTheme.titleTextStyle?.copyWith(color: colorScheme.onPrimary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _SectionTitle(text: 'Teşviki Tanıyalım'),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              // ignore: deprecated_member_use
                              color: colorScheme.onSurface.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 24),
                          _SectionTitle(text: 'Gerekli Belgeler'),
                          const SizedBox(height: 12),
                          _DocumentsGrid(items: const [
                            _DocItem(icon: Icons.description_outlined, label: 'Proje Önerisi'),
                            _DocItem(icon: Icons.science_outlined, label: 'Teknik Rapor'),
                            _DocItem(icon: Icons.attach_money_outlined, label: 'Bütçe Planı'),
                            _DocItem(icon: Icons.business_center_outlined, label: 'Şirket Kayıtları'),
                          ]),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('Başvuruya Başla', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text, style: theme.textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w700));
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                    child: Icon(Icons.check, size: 16, color: colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DocumentsGrid extends StatelessWidget {
  const _DocumentsGrid({required this.items});
  final List<_DocItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.4,
      ),
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(item.icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(item.label, style: theme.textTheme.bodyMedium)),
            ],
          ),
        );
      },
    );
  }
}

// ignore: unused_element
class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});
  final List<_StepItem> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(steps[i].icon, color: colorScheme.primary, size: 18),
                  ),
                  if (i != steps.length - 1)
                    Container(width: 2, height: 36, color: colorScheme.onSurface.withOpacity(0.15)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(steps[i].label, style: theme.textTheme.bodyMedium),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _DocItem {
  const _DocItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _StepItem {
  const _StepItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

