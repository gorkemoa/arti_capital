import 'package:flutter/material.dart';

import '../models/company_models.dart';
import '../models/location_models.dart';
import '../services/general_service.dart';
import '../services/company_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class AddCompanyPartnerView extends StatefulWidget {
  const AddCompanyPartnerView({super.key, required this.compId});
  final int compId;

  @override
  State<AddCompanyPartnerView> createState() => _AddCompanyPartnerViewState();
}

class _AddCompanyPartnerViewState extends State<AddCompanyPartnerView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _taxNoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _shareRatioController = TextEditingController();
  final TextEditingController _sharePriceController = TextEditingController();

  final GeneralService _generalService = GeneralService();
  final CompanyService _companyService = const CompanyService();

  List<CityItem> _cities = const [];
  List<DistrictItem> _districts = const [];
  List<TaxPalaceItem> _palaces = const [];
  CityItem? _selectedCity;
  DistrictItem? _selectedDistrict;
  TaxPalaceItem? _selectedPalace;
  bool _loadingMeta = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _initMeta();
  }

  Future<void> _initMeta() async {
    try {
      final cities = await _generalService.getCities();
      setState(() { _cities = cities; });
      if (cities.isNotEmpty) {
        _selectedCity = cities.first;
        final districts = await _generalService.getDistricts(_selectedCity!.cityNo);
        setState(() { _districts = districts; _selectedDistrict = districts.isNotEmpty ? districts.first : null; });
        final palaces = await _generalService.getTaxPalaces(_selectedCity!.cityNo);
        setState(() { _palaces = palaces; _selectedPalace = palaces.isNotEmpty ? palaces.first : null; });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şehir/vergi dairesi verileri yüklenemedi')));
      }
    } finally {
      if (mounted) setState(() { _loadingMeta = false; });
    }
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _titleController.dispose();
    _taxNoController.dispose();
    _addressController.dispose();
    _shareRatioController.dispose();
    _sharePriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = await StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }
    setState(() { _submitting = true; });
    try {
      final req = AddPartnerRequest(
        userToken: token,
        compID: widget.compId,
        partnerFullname: _fullnameController.text.trim(),
        partnerTitle: _titleController.text.trim(),
        partnerTaxNo: _taxNoController.text.trim(),
        partnerCity: _selectedCity?.cityNo ?? 0,
        partnerDistrict: _selectedDistrict?.districtNo ?? 0,
        partnerTaxPalace: _selectedPalace?.palaceID ?? 0,
        partnerAddress: _addressController.text.trim(),
        partnerShareRatio: _shareRatioController.text.trim(),
        partnerSharePrice: _sharePriceController.text.trim(),
      );
      final resp = await _companyService.addCompanyPartner(req);
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message.isNotEmpty ? resp.message : 'Ortak eklendi')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.errorMessage ?? resp.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() { _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ortak Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildText(theme, controller: _fullnameController, label: 'Ad Soyad'),
                    const SizedBox(height: 12),
                    _buildText(theme, controller: _titleController, label: 'Ünvan'),
                    const SizedBox(height: 12),
                    _buildText(theme, controller: _taxNoController, label: 'Vergi No / TC No'),
                    const SizedBox(height: 12),
                    _buildCityDropdown(theme),
                    const SizedBox(height: 12),
                    _buildDistrictDropdown(theme),
                    const SizedBox(height: 12),
                    _buildPalaceDropdown(theme),
                    const SizedBox(height: 12),
                    _buildText(theme, controller: _addressController, label: 'Adres', maxLines: 2),
                    const SizedBox(height: 12),
                    _buildText(theme, controller: _shareRatioController, label: 'Hisse Oranı (%)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    const SizedBox(height: 12),
                    _buildText(theme, controller: _sharePriceController, label: 'Hisse Tutarı', keyboardType: TextInputType.number),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                      label: const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildText(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: const InputDecoration(border: OutlineInputBorder()).copyWith(labelText: label, filled: true, fillColor: Colors.grey.shade50),
    );
  }

  Widget _buildCityDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CityItem>(
          isExpanded: true,
          value: _selectedCity,
          hint: const Text('İl Seçin'),
          items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c.cityName))).toList(),
          onChanged: (CityItem? city) async {
            setState(() { _selectedCity = city; _selectedDistrict = null; _palaces = const []; _selectedPalace = null; _loadingMeta = true; });
            if (city != null) {
              try {
                final d = await _generalService.getDistricts(city.cityNo);
                final p = await _generalService.getTaxPalaces(city.cityNo);
                if (mounted) setState(() { _districts = d; _selectedDistrict = d.isNotEmpty ? d.first : null; _palaces = p; _selectedPalace = p.isNotEmpty ? p.first : null; });
              } catch (_) {}
            }
            if (mounted) setState(() { _loadingMeta = false; });
          },
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DistrictItem>(
          isExpanded: true,
          value: _selectedDistrict,
          hint: const Text('İlçe Seçin'),
          items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d.districtName))).toList(),
          onChanged: (_districts.isEmpty)
              ? null
              : (DistrictItem? v) async {
                  setState(() { _selectedDistrict = v; _loadingMeta = true; _palaces = const []; _selectedPalace = null; });
                  try {
                    if (_selectedCity != null) {
                      final p = await _generalService.getTaxPalaces(_selectedCity!.cityNo);
                      if (mounted) {
                        setState(() {
                          _palaces = p;
                          _selectedPalace = p.isNotEmpty ? p.first : null;
                        });
                      }
                    }
                  } catch (_) {}
                  if (mounted) setState(() { _loadingMeta = false; });
                },
        ),
      ),
    );
  }

  Widget _buildPalaceDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaxPalaceItem>(
          isExpanded: true,
          value: _selectedPalace,
          hint: const Text('Vergi Dairesi'),
          items: _palaces.map((p) => DropdownMenuItem(value: p, child: Text(p.palaceName))).toList(),
          onChanged: (_palaces.isEmpty) ? null : (TaxPalaceItem? v) => setState(() { _selectedPalace = v; }),
        ),
      ),
    );
  }
}


