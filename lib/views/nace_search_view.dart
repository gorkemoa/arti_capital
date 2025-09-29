import 'package:flutter/material.dart';

import '../models/company_models.dart';
import '../services/general_service.dart';
import '../theme/app_colors.dart';

class NaceSearchView extends StatefulWidget {
  const NaceSearchView({super.key});

  @override
  State<NaceSearchView> createState() => _NaceSearchViewState();
}

class _NaceSearchViewState extends State<NaceSearchView> {
  final GeneralService _generalService = GeneralService();
  final TextEditingController _searchController = TextEditingController();

  List<NaceCodeItem> _all = const [];
  List<NaceCodeItem> _filtered = const [];
  bool _loading = true;
  String _error = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilter);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final nace = await _generalService.getNaceCodes();
      if (!mounted) return;
      setState(() {
        _all = List.of(nace);
        _sortById(_all);
        _filtered = List.of(_all);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'NACE listesi alınamadı';
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim();
    _query = query;
    final lower = query.toLowerCase();
    if (lower.isEmpty) {
      setState(() {
        _filtered = List.of(_all);
      });
      return;
    }
    setState(() {
      _filtered = _all.where((n) {
        return n.naceCode.toLowerCase().contains(lower) ||
            n.naceDesc.toLowerCase().contains(lower) ||
            n.professionDesc.toLowerCase().contains(lower) ||
            n.sectorDesc.toLowerCase().contains(lower);
      }).toList();
      _sortById(_filtered);
    });
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
        title: const Text('NACE Kodu Seç'),
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
                      controller: _searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'NACE ara (kod, açıklama, sektör)',
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
                        TextButton(
                          onPressed: _load,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Alt bilgi/filtre çubuğu kaldırıldı
            Expanded(
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
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
                                final n = _filtered[i];
                                final subtitle = n.professionDesc.isNotEmpty ? n.professionDesc : n.sectorDesc;
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
                                      onTap: () => Navigator.of(context).pop<NaceCodeItem>(n),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildHighlightedWithStyle(
                                                    '${n.naceCode} - ${n.naceDesc}',
                                                    _query,
                                                    const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  if (subtitle.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    _buildHighlightedWithStyle(
                                                      subtitle,
                                                      _query,
                                                      TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade700,
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.chevron_right, color: Colors.grey.shade500),
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
          TextSpan(
            text: match,
            style: baseStyle.merge(const TextStyle(backgroundColor: Color(0xFFFFF3BF))),
          ),
          TextSpan(text: after, style: baseStyle),
        ],
      ),
    );
  }

  void _sortById(List<NaceCodeItem> list) {
    int parseId(String s) {
      final v = int.tryParse(s.trim());
      return v ?? 0;
    }
    list.sort((a, b) {
      final ai = parseId(a.ncID);
      final bi = parseId(b.ncID);
      return ai.compareTo(bi);
    });
  }
}


