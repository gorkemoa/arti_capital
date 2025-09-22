import 'package:flutter/foundation.dart';

import '../models/company_models.dart';
import '../services/company_service.dart';
import '../services/app_group_service.dart';

class CompaniesViewModel extends ChangeNotifier {
  final CompanyService _companyService = const CompanyService();

  List<CompanyItem> _companies = [];
  bool _loading = true;
  String? _errorMessage;

  List<CompanyItem> get companies => _companies;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  CompaniesViewModel() {
    _load();
  }

  Future<void> _load() async {
    try {
      _loading = true;
      notifyListeners();
      final resp = await _companyService.getCompanies();
      if (resp.success) {
        _companies = resp.companies;
        _errorMessage = null;
        // iOS Share Extension için firma adlarını App Group'a yaz
        try {
          final names = _companies.map((e) => e.compName).where((e) => e.trim().isNotEmpty).toList();
          if (names.isNotEmpty) {
            await AppGroupService.setCompanies(names);
          }
        } catch (_) {}
      } else {
        _companies = [];
        _errorMessage = resp.errorMessage ?? 'Firmalar alınamadı';
      }
    } catch (e) {
      _companies = [];
      _errorMessage = 'Bir hata oluştu: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _load();
  }
}




