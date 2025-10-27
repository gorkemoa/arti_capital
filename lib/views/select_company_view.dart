import 'package:flutter/material.dart';

import '../models/company_models.dart';
import '../services/company_service.dart';
import '../theme/app_colors.dart';
import 'company_detail_view.dart';

class SelectCompanyView extends StatefulWidget {
  const SelectCompanyView({super.key});

  @override
  State<SelectCompanyView> createState() => _SelectCompanyViewState();
}

class _SelectCompanyViewState extends State<SelectCompanyView> {
  final CompanyService _service = const CompanyService();
  final TextEditingController _searchController = TextEditingController();
  List<CompanyItem> _companies = const [];
  List<CompanyItem> _filtered = const [];
  bool _loading = true;
  String _query = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
        _applyFilter();
      });
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    final res = await _service.getCompanies();
    if (!mounted) return;
    if (res.success) {
      setState(() {
        _companies = res.companies;
        _applyFilter();
        _loading = false;
      });
    } else {
      setState(() { _loading = false; _error = res.errorMessage ?? 'Şirketler yüklenemedi'; });
    }
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = _companies;
    } else {
      _filtered = _companies.where((c) => c.compName.toLowerCase().contains(q)).toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Şirket Seç'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
            textCapitalization: TextCapitalization.sentences,
                      controller: _searchController,
                      autofocus: false,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Şirket ara',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilter();
                                },
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onSubmitted: (_) => _applyFilter(),
                    ),
                  ),
                ],
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        TextButton(onPressed: _load, child: const Text('Tekrar Dene')),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: _filtered.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 80),
                                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    'Aramanızı daraltmayı deneyin',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) {
                                final c = _filtered[i];
                                final subtitle = c.compType ?? '';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.grey.shade200),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () => Navigator.of(context).pop<CompanyItem>(c),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildHighlightedWithStyle(c.compName, _query, const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                                                  if (subtitle.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    _buildHighlightedWithStyle(subtitle, _query, TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w400)),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => CompanyDetailView(compId: c.compID),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.open_in_new, size: 16),
                                              label: const Text('Detay'),
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedWithStyle(String text, String query, TextStyle baseStyle) {
    if (query.trim().isEmpty) {
      return Text(text, style: baseStyle);
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final int matchIndex = lowerText.indexOf(lowerQuery);
    if (matchIndex < 0) {
      return Text(text, style: baseStyle);
    }
    final before = text.substring(0, matchIndex);
    final match = text.substring(matchIndex, matchIndex + query.length);
    final after = text.substring(matchIndex + query.length);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: before, style: baseStyle),
          TextSpan(text: match, style: baseStyle.merge(const TextStyle(backgroundColor: Color(0xFFFFF3BF)))),
          TextSpan(text: after, style: baseStyle),
        ],
      ),
    );
  }
}


