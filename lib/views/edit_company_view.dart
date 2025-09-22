import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/company_models.dart';
import '../models/location_models.dart';
import '../services/general_service.dart';
import '../services/logger.dart';
import '../services/storage_service.dart';
import '../services/company_service.dart';
import '../theme/app_colors.dart';

class EditCompanyView extends StatefulWidget {
  const EditCompanyView({super.key, required this.company});
  final CompanyItem company;

  @override
  State<EditCompanyView> createState() => _EditCompanyViewState();
}

class _EditCompanyViewState extends State<EditCompanyView> {
  final _formKey = GlobalKey<FormState>();
  final _compNameController = TextEditingController();
  final _compTaxNoController = TextEditingController();
  final _compTaxPalaceController = TextEditingController();
  final _compKepAddressController = TextEditingController();
  final _compMersisNoController = TextEditingController();
  final _compAddressController = TextEditingController();

  final GeneralService _generalService = GeneralService();
  final CompanyService _userService = const CompanyService();

  List<CityItem> _cities = const [];
  List<DistrictItem> _districts = const [];
  List<TaxPalaceItem> _palaces = const [];
  CityItem? _selectedCity;
  DistrictItem? _selectedDistrict;
  TaxPalaceItem? _selectedPalace;
  bool _loading = false;
  bool _loadingMeta = true;
  String _logoBase64 = '';

  @override
  void initState() {
    super.initState();
    _compNameController.text = widget.company.compName;
    _compTaxNoController.text = widget.company.compTaxNo ?? '';
    _compTaxPalaceController.text = widget.company.compTaxPalace ?? '';
    _compKepAddressController.text = '';
    _compMersisNoController.text = widget.company.compMersisNo ?? '';
    _compAddressController.text = widget.company.compAddress;
    _logoBase64 = widget.company.compLogo;
    _initMeta();
  }

  Future<void> _initMeta() async {
    try {
      final cities = await _generalService.getCities();
      setState(() { _cities = cities; });
      // Şehri seçili getir
      final city = cities.firstWhere((c) => c.cityNo == widget.company.compCityID, orElse: () => cities.first);
      _selectedCity = city;
      final d = await _generalService.getDistricts(city.cityNo);
      final p = await _generalService.getTaxPalaces(city.cityNo);
      setState(() { _districts = d; _palaces = p; });
      // İlçeyi seçili getir
      try {
        _selectedDistrict = d.firstWhere((x) => x.districtNo == widget.company.compDistrictID);
      } catch (_) {}
      // Vergi dairesini seçili getir
      try {
        if (widget.company.compTaxPalaceID != null) {
          _selectedPalace = p.firstWhere((x) => x.palaceID == widget.company.compTaxPalaceID);
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şehir/ilçe verisi alınamadı')),
        );
      }
    } finally {
      if (mounted) setState(() { _loadingMeta = false; });
    }
  }

  @override
  void dispose() {
    _compNameController.dispose();
    _compTaxNoController.dispose();
    _compTaxPalaceController.dispose();
    _compKepAddressController.dispose();
    _compMersisNoController.dispose();
    _compAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          try { bytes = await File(file.path!).readAsBytes(); } catch (_) {}
        }
        if (bytes != null) {
          final base64String = base64Encode(bytes);
          String mimeType = 'image/png';
          final fileName = file.name.toLowerCase();
          if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) mimeType = 'image/jpeg';
          setState(() { _logoBase64 = 'data:$mimeType;base64,$base64String'; });
        }
      }
    } catch (e) {
      AppLogger.e('Logo seçme hatası: $e', tag: 'EDIT_COMPANY');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo seçilirken hata')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null || _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şehir/ilçe seçiniz')));
      return;
    }
    if (_selectedPalace == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vergi dairesi seçiniz')));
      return;
    }
    setState(() { _loading = true; });
    try {
      final token = StorageService.getToken();
      if (token == null) throw Exception('Token bulunamadı');

      // userIdentityNo çek
      final userData = StorageService.getUserData();
      if (userData == null) throw Exception('Kullanıcı verisi bulunamadı');
      String? identityNo;
      try {
        final dynamic parsed = jsonDecode(userData);
        if (parsed is Map<String, dynamic>) identityNo = parsed['userIdentityNo'] as String?;
      } catch (_) {
        final match = RegExp(r'userIdentityNo[:=]\s*([^,}\s]+)').firstMatch(userData);
        identityNo = match != null ? match.group(1) : null;
      }
      if (identityNo == null || identityNo.isEmpty) throw Exception('Kimlik numarası bulunamadı');

      final req = UpdateCompanyRequest(
        userToken: token,
        userIdentityNo: identityNo,
        compID: widget.company.compID,
        compName: _compNameController.text.trim(),
        compTaxNo: _compTaxNoController.text.trim(),
        compTaxPalace: _selectedPalace!.palaceID,
        compKepAddress: _compKepAddressController.text.trim(),
        compMersisNo: _compMersisNoController.text.trim(),
        compType: 1,
        compCity: _selectedCity!.cityNo,
        compDistrict: _selectedDistrict!.districtNo,
        compAddress: _compAddressController.text.trim(),
        compLogo: _logoBase64,
      );

      final resp = await _userService.updateCompany(req);
      if (resp.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.errorMessage ?? resp.message)));
        }
      }
    } catch (e) {
      AppLogger.e('Firma güncelleme hatası: $e', tag: 'EDIT_COMPANY');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Güncelleme sırasında hata oluştu')));
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Firmayı Düzenle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle(context, 'Logo'),
                    const SizedBox(height: 16),
                    _buildLogoSection(theme),
                    const SizedBox(height: 24),

                    _buildSectionTitle(context, 'Şirket Bilgileri'),
                    const SizedBox(height: 16),
                    _styledTextField(controller: _compNameController, label: 'Firma Adı *', validator: (v){ if(v==null||v.trim().isEmpty) return 'Gerekli'; return null; }),
                    const SizedBox(height: 16),
                    _styledTextField(controller: _compTaxNoController, label: 'Vergi No *', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v){ if(v==null||v.trim().isEmpty) return 'Gerekli'; if(v.trim().length!=10) return '10 haneli olmalı'; return null; }),
                    // Vergi dairesi text alanı kaldırıldı; aşağıda dropdown mevcut

                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Konum Bilgileri'),
                    const SizedBox(height: 16),
                    _styledCityDropdown(theme),
                    const SizedBox(height: 16),
                    _styledDistrictDropdown(theme),
                    const SizedBox(height: 16),
                    _styledTaxPalaceDropdown(theme),
                    const SizedBox(height: 16),
                    _styledTextField(controller: _compAddressController, label: 'Adres', maxLines: 3),

                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Diğer'),
                    const SizedBox(height: 16),
                    _styledTextField(controller: _compKepAddressController, label: 'KEP Adresi', keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _styledTextField(controller: _compMersisNoController, label: 'MERSIS No', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    const SizedBox(height: 8),
                  ],
                ),
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
                onPressed: _loading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _loading
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

  Widget _buildLogoSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text('Firma Logosu', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildLogoPreview(theme),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(onPressed: _pickLogo, icon: const Icon(Icons.photo_library), label: Text(_logoBase64.isEmpty ? 'Logo Seç' : 'Değiştir')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPreview(ThemeData theme) {
    final borderColor = theme.colorScheme.outline.withOpacity(0.3);
    if (_logoBase64.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Icon(Icons.apartment_outlined, size: 40, color: theme.colorScheme.outline),
      );
    }

    Widget imageWidget;
    try {
      if (_logoBase64.startsWith('data:image/')) {
        final parts = _logoBase64.split(',');
        if (parts.length == 2) {
          final bytes = base64Decode(parts[1]);
          imageWidget = Image.memory(bytes, fit: BoxFit.contain);
        } else {
          imageWidget = const Icon(Icons.apartment_outlined);
        }
      } else if (_logoBase64.startsWith('http://') || _logoBase64.startsWith('https://')) {
        imageWidget = Image.network(_logoBase64, fit: BoxFit.contain);
      } else {
        // Unknown format fallback
        imageWidget = const Icon(Icons.apartment_outlined);
      }
    } catch (_) {
      imageWidget = const Icon(Icons.apartment_outlined);
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FittedBox(fit: BoxFit.contain, child: imageWidget),
      ),
    );
  }

  

  // Styled components (match add_company_view aesthetics)
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

  InputDecoration _styledDecoration(String label) => InputDecoration(
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
      );

  Widget _styledTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _styledDecoration(label),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface,
          ),
    );
  }

  Widget _styledCityDropdown(ThemeData theme) {
    if (_loadingMeta && _cities.isEmpty) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }

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
              .map((city) => DropdownMenuItem(
                    value: city,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        city.cityName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurface,
                            ),
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (CityItem? city) async {
            setState(() { _selectedCity = city; _selectedDistrict = null; _selectedPalace = null; _palaces = const []; });
            if (city != null) {
              setState(() { _loadingMeta = true; _districts = const []; });
              try {
                final d = await _generalService.getDistricts(city.cityNo);
                final p = await _generalService.getTaxPalaces(city.cityNo);
                if (mounted) setState(() { _districts = d; _palaces = p; });
              } catch (_) {}
              if (mounted) setState(() { _loadingMeta = false; });
            }
          },
        ),
      ),
    );
  }

  Widget _styledDistrictDropdown(ThemeData theme) {
    if (_loadingMeta && _selectedCity != null && _districts.isEmpty) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }

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
          onChanged: _districts.isEmpty ? null : (DistrictItem? district) {
            setState(() { _selectedDistrict = district; });
          },
        ),
      ),
    );
  }

  Widget _styledTaxPalaceDropdown(ThemeData theme) {
    if (_loadingMeta && _selectedCity != null && _palaces.isEmpty) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }

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
                  'Vergi Dairesi',
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
          onChanged: _palaces.isEmpty ? null : (TaxPalaceItem? v) {
            setState(() { _selectedPalace = v; });
          },
        ),
      ),
    );
  }

  

  
}


