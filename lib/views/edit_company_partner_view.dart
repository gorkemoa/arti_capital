import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/company_models.dart';
import '../models/location_models.dart';
import '../services/general_service.dart';
import '../services/company_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class EditCompanyPartnerView extends StatefulWidget {
  const EditCompanyPartnerView({super.key, required this.compId, required this.partner});
  final int compId;
  final PartnerItem partner;

  @override
  State<EditCompanyPartnerView> createState() => _EditCompanyPartnerViewState();
}

class _EditCompanyPartnerViewState extends State<EditCompanyPartnerView> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _taxNoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _shareRatioController = TextEditingController();
  final TextEditingController _sharePriceWholeController = TextEditingController();
  final TextEditingController _sharePriceCentsController = TextEditingController();

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
    _prefill();
    _initMeta();
  }

  void _prefill() {
    final p = widget.partner;
    _fullnameController.text = p.partnerName;
    _firstnameController.text = p.partnerFirstname;
    _lastnameController.text = p.partnerLastname;
    _identityController.text = p.partnerIdentityNo;
    _birthdayController.text = p.partnerBirthday;
    _titleController.text = p.partnerTitle;
    _taxNoController.text = p.partnerTaxNo;
    _addressController.text = p.partnerAddress;
    _shareRatioController.text = p.partnerShareRatio.toString();
    String ratioRaw = _shareRatioController.text;
    String ratioNormalized = ratioRaw.replaceAll(',', '.');
    ratioNormalized = ratioNormalized.replaceAll(RegExp(r'[^0-9\.]'), '');
    final ratioParts = ratioNormalized.split('.');
    if (ratioParts.length > 2) {
      ratioNormalized = '${ratioParts[0]}.${ratioParts.sublist(1).join()}';
    }
    final parsedRatio = double.tryParse(ratioNormalized);
    if (parsedRatio != null) {
      double clamped = parsedRatio;
      if (clamped > 100) clamped = 100;
      if (clamped < 0) clamped = 0;
      ratioNormalized = clamped.toString();
    }
    _shareRatioController.text = ratioNormalized;
    final String priceText = p.partnerSharePrice.toString();
    String whole = '';
    String cents = '';
    if (priceText.contains('.')) {
      final parts = priceText.split('.');
      whole = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
      cents = parts.length > 1 ? parts[1].replaceAll(RegExp(r'[^0-9]'), '') : '';
    } else if (priceText.contains(',')) {
      final parts = priceText.split(',');
      whole = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
      cents = parts.length > 1 ? parts[1].replaceAll(RegExp(r'[^0-9]'), '') : '';
    } else {
      whole = priceText.replaceAll(RegExp(r'[^0-9]'), '');
      cents = '';
    }
    if (cents.isEmpty) cents = '00';
    if (cents.length > 2) cents = cents.substring(0, 2);
    _sharePriceWholeController.text = whole.isEmpty ? '0' : whole;
    _sharePriceCentsController.text = cents.padLeft(2, '0');
  }

  Future<void> _initMeta() async {
    try {
      final cities = await _generalService.getCities();
      _cities = cities;
      final city = cities.firstWhere(
        (c) => c.cityNo == widget.partner.partnerCityID,
        orElse: () => cities.isNotEmpty ? cities.first : const CityItem(cityNo: 0, cityName: ''),
      );
      _selectedCity = city;
      final districts = city.cityNo != 0 ? await _generalService.getDistricts(city.cityNo) : <DistrictItem>[];
      _districts = districts;
      final matchedDistricts = districts.where((d) => d.districtNo == widget.partner.partnerDistrictID).toList();
      _selectedDistrict = matchedDistricts.isNotEmpty ? matchedDistricts.first : (districts.isNotEmpty ? districts.first : null);

      final palaces = city.cityNo != 0 ? await _generalService.getTaxPalaces(city.cityNo) : <TaxPalaceItem>[];
      _palaces = palaces;
      final matchedPalaces = palaces.where((p) => p.palaceID == widget.partner.partnerTaxPalaceID).toList();
      _selectedPalace = matchedPalaces.isNotEmpty ? matchedPalaces.first : null;
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
    _firstnameController.dispose();
    _lastnameController.dispose();
    _identityController.dispose();
    _birthdayController.dispose();
    _titleController.dispose();
    _taxNoController.dispose();
    _addressController.dispose();
    _shareRatioController.dispose();
    _sharePriceWholeController.dispose();
    _sharePriceCentsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }
    setState(() { _submitting = true; });
    try {
      // Hisse tutarı birleştirme (tam.kuruş)
      String whole = _sharePriceWholeController.text.replaceAll(RegExp(r'[^0-9]'), '');
      String cents = _sharePriceCentsController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (whole.isEmpty) whole = '0';
      if (cents.isEmpty) cents = '00';
      if (cents.length > 2) cents = cents.substring(0, 2);
      cents = cents.padLeft(2, '0');

      final req = UpdatePartnerRequest(
        userToken: token,
        compID: widget.compId,
        partnerID: widget.partner.partnerID,
        partnerFirstname: _firstnameController.text.trim(),
        partnerLastname: _lastnameController.text.trim(),
        partnerIdentityNo: _identityController.text.trim(),
        partnerBirthday: _birthdayController.text.trim(),
        partnerTitle: _titleController.text.trim(),
        partnerTaxNo: _taxNoController.text.trim(),
        partnerCity: _selectedCity?.cityNo ?? 0,
        partnerDistrict: _selectedDistrict?.districtNo ?? 0,
        partnerTaxPalace: _selectedPalace?.palaceID ?? 0,
        partnerAddress: _addressController.text.trim(),
        partnerShareRatio: _shareRatioController.text.trim(),
        partnerSharePrice: '$whole.$cents',
      );
      final resp = await _companyService.updateCompanyPartner(req);
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message.isNotEmpty ? resp.message : 'Ortak güncellendi')));
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ortak Güncelle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(context, 'Kişi Bilgileri'),
                  const SizedBox(height: 16),
                  _buildText(theme, controller: _identityController, label: 'T.C. Kimlik No', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], maxLength: 11),
                  const SizedBox(height: 16),
                  _buildText(theme, controller: _firstnameController, label: 'Ad', onChanged: (v) {
                    final up = v.toUpperCase();
                    if (up != _firstnameController.text) {
                      _firstnameController.value = _firstnameController.value.copyWith(
                        text: up,
                        selection: TextSelection.collapsed(offset: up.length),
                      );
                    }
                  }),
                  const SizedBox(height: 16),
                  _buildText(theme, controller: _lastnameController, label: 'Soyad', onChanged: (v) {
                    final up = v.toUpperCase();
                    if (up != _lastnameController.text) {
                      _lastnameController.value = _lastnameController.value.copyWith(
                        text: up,
                        selection: TextSelection.collapsed(offset: up.length),
                      );
                    }
                  }),
                  const SizedBox(height: 16),
                  _buildDatePicker(theme, controller: _birthdayController, label: 'Doğum Tarihi (GG.AA.YYYY)'),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'İletişim ve Vergi'),
                  const SizedBox(height: 24),
                  _buildText(theme, controller: _titleController, label: 'Ünvan'),
                  const SizedBox(height: 16),
                  _buildText(theme, controller: _taxNoController, label: 'Vergi No / TC No', keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildCityDropdown(theme),
                  const SizedBox(height: 16),
                  _buildDistrictDropdown(theme),
                  const SizedBox(height: 16),
                  _buildPalaceDropdown(theme),
                  const SizedBox(height: 16),
                  _buildText(theme, controller: _addressController, label: 'Adres', maxLines: 2),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Hisse Bilgileri'),
                  const SizedBox(height: 24),
                  _buildText(
                    theme,
                    controller: _shareRatioController,
                    label: 'Hisse Oranı',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      String normalized = v.replaceAll(',', '.');
                      normalized = normalized.replaceAll(RegExp(r'[^0-9\.]'), '');
                      final parts = normalized.split('.');
                      if (parts.length > 2) {
                        normalized = parts[0] + '.' + parts.sublist(1).join();
                      }
                      final parsed = double.tryParse(normalized);
                      if (parsed != null && parsed > 100) {
                        normalized = '100';
                      }
                      if (normalized != v) {
                        _shareRatioController.value = _shareRatioController.value.copyWith(
                          text: normalized,
                          selection: TextSelection.collapsed(offset: normalized.length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildText(
                          theme,
                          controller: _sharePriceWholeController,
                          label: 'Hisse Tutarı (Tam)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (v) {
                            final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                            if (digits != v) {
                              _sharePriceWholeController.value = _sharePriceWholeController.value.copyWith(
                                text: digits,
                                selection: TextSelection.collapsed(offset: digits.length),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildText(
                          theme,
                          controller: _sharePriceCentsController,
                          label: 'Hisse Tutarı (Kuruş)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (v) {
                            String digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                            if (digits.length > 2) digits = digits.substring(0, 2);
                            if (digits != v) {
                              _sharePriceCentsController.value = _sharePriceCentsController.value.copyWith(
                                text: digits,
                                selection: TextSelection.collapsed(offset: digits.length),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _submitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Kaydediliyor...',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      )
                    : Text(
                        'Kaydet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
              ),
            ),
          ],
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
      int? maxLength,
      ValueChanged<String>? onChanged,
      List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface.withOpacity(0.6),
            ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface,
          ),
    );
  }

  Widget _buildDatePicker(ThemeData theme, {required TextEditingController controller, required String label}) {
    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).unfocus();
        final now = DateTime.now();
        DateTime initial = DateTime(now.year - 30, now.month, now.day);
        final text = controller.text.trim();
        if (RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(text)) {
          final parts = text.split('.');
          final dd = int.tryParse(parts[0]);
          final mm = int.tryParse(parts[1]);
          final yyyy = int.tryParse(parts[2]);
          if (dd != null && mm != null && yyyy != null) {
            final candidate = DateTime(yyyy, mm, dd);
            if (!candidate.isAfter(now) && yyyy >= 1900) {
              initial = candidate;
            }
          }
        }

        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1900, 1, 1),
          lastDate: DateTime(now.year, now.month, now.day),
          helpText: 'Doğum Tarihi',
          locale: const Locale('tr', 'TR'),
        );
        if (picked != null) {
          final dd = picked.day.toString().padLeft(2, '0');
          final mm = picked.month.toString().padLeft(2, '0');
          final yyyy = picked.year.toString();
          controller.text = '$dd.$mm.$yyyy';
          setState(() {});
        }
      },
      child: AbsorbPointer(
        child: _buildText(
          theme,
          controller: controller,
          label: label,
          keyboardType: TextInputType.datetime,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
    );
  }

  Widget _buildCityDropdown(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CityItem>(
          isExpanded: true,
          value: _selectedCity,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'İl',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          items: _cities
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        c.cityName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurface,
                            ),
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (CityItem? city) async {
            setState(() {
              _selectedCity = city;
              _selectedDistrict = null;
              _palaces = const [];
              _selectedPalace = null;
              _loadingMeta = true;
            });
            if (city != null) {
              try {
                final d = await _generalService.getDistricts(city.cityNo);
                final p = await _generalService.getTaxPalaces(city.cityNo);
                if (mounted) {
                  setState(() {
                    _districts = d;
                    _selectedDistrict = d.isNotEmpty ? d.first : null;
                    _palaces = p;
                    // Önce mevcut partner vergi dairesi ID'si varsa onu seç
                    final int savedPalaceId = widget.partner.partnerTaxPalaceID;
                    final match = p.where((e) => e.palaceID == savedPalaceId).toList();
                    _selectedPalace = match.isNotEmpty ? match.first : (p.isNotEmpty ? p.first : null);
                  });
                }
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DistrictItem>(
          isExpanded: true,
          value: _selectedDistrict,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'İlçe',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          items: _districts
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        d.districtName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurface,
                            ),
                      ),
                    ),
                  ))
              .toList(),
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
                          // Mevcut partner vergi dairesi ID'sine göre seç, yoksa ilkini seç
                          final int savedPalaceId = widget.partner.partnerTaxPalaceID;
                          final match = p.where((e) => e.palaceID == savedPalaceId).toList();
                          _selectedPalace = match.isNotEmpty ? match.first : (p.isNotEmpty ? p.first : null);
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaxPalaceItem>(
          isExpanded: true,
          value: _selectedPalace,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Vergi Dairesi (Seçiniz)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          items: _palaces
              .map((p) => DropdownMenuItem(
                    value: p,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        p.palaceName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurface,
                            ),
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (_palaces.isEmpty) ? null : (TaxPalaceItem? v) => setState(() { _selectedPalace = v; }),
        ),
      ),
    );
  }
}




