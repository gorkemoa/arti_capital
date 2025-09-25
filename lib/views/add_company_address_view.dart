import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/company_models.dart';
import '../models/location_models.dart';
import '../services/company_service.dart';
import '../services/general_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class AddCompanyAddressView extends StatefulWidget {
  const AddCompanyAddressView({super.key, required this.compId});
  final int compId;

  @override
  State<AddCompanyAddressView> createState() => _AddCompanyAddressViewState();
}

class _AddCompanyAddressViewState extends State<AddCompanyAddressView> {
  // Yüklenme durumları
  bool _loadingMeta = true;
  bool _submitting = false;
  List<CityItem> _cities = const [];
  List<DistrictItem> _districts = const [];
  List<AddressTypeItem> _addressTypes = const [];

  int? _addressType; // 1: Merkez, vs. Backend ID bekliyor
  int? _cityId;
  int? _districtId;
  final TextEditingController _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _primeData();
  }

  Future<void> _primeData() async {
    setState(() => _loadingMeta = true);
    try {
      final service = GeneralService();
      final results = await Future.wait([
        service.getCities(),
        service.getAddressTypes(),
      ]);
      if (!mounted) return;
      setState(() {
        _cities = results[0] as List<CityItem>;
        _addressTypes = results[1] as List<AddressTypeItem>;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adres meta verileri yüklenemedi')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  Future<void> _loadDistricts(int cityNo) async {
    setState(() {
      _districts = const [];
      _districtId = null;
      _loadingMeta = true;
    });
    try {
      final items = await GeneralService().getDistricts(cityNo);
      if (!mounted) return;
      setState(() {
        _districts = items;
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  Future<void> _submit() async {
    final token = await StorageService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }

    // Basit doğrulamalar
    if (_addressType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adres tipi seçiniz')));
      return;
    }
    if (_cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İl seçiniz')));
      return;
    }
    if (_districtId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlçe seçiniz')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final resp = await const CompanyService().addCompanyAddress(
        AddCompanyAddressRequest(
          userToken: token,
          compID: widget.compId,
          addressType: _addressType!,
          addressCity: _cityId!,
          addressDistrict: _districtId!,
          addressAddress: _addressCtrl.text.trim(),
        ),
      );

      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adres eklendi.')));
        Navigator.of(context).pop(true);
      } else {
        final msg = resp.errorMessage ?? resp.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.isNotEmpty ? msg : 'Adres eklenemedi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _showCupertinoSelector<T>({
    required List<T> items,
    required int initialIndex,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
    String title = '',
  }) async {
    final FixedExtentScrollController controller =
        FixedExtentScrollController(initialItem: initialIndex);
    int currentIndex = initialIndex.clamp(0, items.isNotEmpty ? items.length - 1 : 0);

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text('Vazgeç'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    Center(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text('Seç'),
                        onPressed: () {
                          if (items.isNotEmpty) {
                            onSelected(items[currentIndex]);
                          }
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: controller,
                  onSelectedItemChanged: (index) {
                    currentIndex = index;
                  },
                  children: items.isEmpty
                      ? [const Text('-')]
                      : items.map((e) => Center(child: Text(labelBuilder(e)))).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCupertinoField({
    required String placeholder,
    required String? value,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value == null || value.isEmpty ? placeholder : value,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: (value == null || value.isEmpty)
                          ? AppColors.onSurface.withOpacity(0.6)
                          : AppColors.onSurface,
                    ),
              ),
            ),
            Icon(CupertinoIcons.chevron_down, size: 18, color: AppColors.onSurface.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adres Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      backgroundColor: Colors.white,
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(context, 'Adres Bilgileri'),
                  const SizedBox(height: 16),
                  _buildAddressTypeDropdown(theme),
                  const SizedBox(height: 16),
                  _buildCityDropdown(theme),
                  const SizedBox(height: 16),
                  _buildDistrictDropdown(theme),
                  const SizedBox(height: 16),
                  _buildText(
                    theme,
                    controller: _addressCtrl,
                    label: 'Adres',
                    maxLines: 3,
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

  // Ortak metin alanı
  Widget _buildText(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
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

  Widget _buildAddressTypeDropdown(ThemeData theme) {
    if (_loadingMeta && _addressTypes.isEmpty) {
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

    final String? currentLabel = _addressType == null
        ? null
        : _addressTypes.firstWhere(
            (t) => t.typeID == _addressType,
            orElse: () => _addressTypes.isNotEmpty ? _addressTypes.first : AddressTypeItem(typeID: -1, typeName: ''),
          ).typeName;

    return _buildCupertinoField(
      placeholder: 'Adres Tipi',
      value: (currentLabel != null && currentLabel.isNotEmpty) ? currentLabel : null,
      onTap: _addressTypes.isEmpty
          ? null
          : () async {
              final currentIndex = _addressType == null
                  ? 0
                  : _addressTypes.indexWhere((t) => t.typeID == _addressType).clamp(0, _addressTypes.length - 1);
              await _showCupertinoSelector<AddressTypeItem>(
                items: _addressTypes,
                initialIndex: currentIndex,
                labelBuilder: (t) => t.typeName,
                title: 'Adres Tipi Seç',
                onSelected: (t) {
                  setState(() { _addressType = t.typeID; });
                },
              );
            },
    );
  }

  Widget _buildCityDropdown(ThemeData theme) {
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

    final String? currentLabel = _cityId == null
        ? null
        : _cities.firstWhere(
            (c) => c.cityNo == _cityId,
            orElse: () => _cities.isNotEmpty ? _cities.first : CityItem(cityNo: -1, cityName: ''),
          ).cityName;

    return _buildCupertinoField(
      placeholder: 'İl',
      value: (currentLabel != null && currentLabel.isNotEmpty) ? currentLabel : null,
      onTap: _cities.isEmpty
          ? null
          : () async {
              final currentIndex = _cityId == null
                  ? 0
                  : _cities.indexWhere((c) => c.cityNo == _cityId).clamp(0, _cities.length - 1);
              await _showCupertinoSelector<CityItem>(
                items: _cities,
                initialIndex: currentIndex,
                labelBuilder: (c) => c.cityName,
                title: 'İl Seç',
                onSelected: (city) async {
                  setState(() { _cityId = city.cityNo; _districtId = null; _districts = const []; });
                  if (city.cityNo != 0) {
                    await _loadDistricts(city.cityNo);
                  }
                },
              );
            },
    );
  }

  Widget _buildDistrictDropdown(ThemeData theme) {
    if (_loadingMeta && _districts.isEmpty && _cityId != null) {
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

    final String? currentLabel = _districtId == null
        ? null
        : _districts.firstWhere(
            (d) => d.districtNo == _districtId,
            orElse: () => _districts.isNotEmpty ? _districts.first : DistrictItem(districtNo: -1, districtName: ''),
          ).districtName;

    return _buildCupertinoField(
      placeholder: 'İlçe',
      value: (currentLabel != null && currentLabel.isNotEmpty) ? currentLabel : null,
      onTap: (_districts.isEmpty || _loadingMeta)
          ? null
          : () async {
              final currentIndex = _districtId == null
                  ? 0
                  : _districts.indexWhere((d) => d.districtNo == _districtId).clamp(0, _districts.length - 1);
              await _showCupertinoSelector<DistrictItem>(
                items: _districts,
                initialIndex: currentIndex,
                labelBuilder: (d) => d.districtName,
                title: 'İlçe Seç',
                onSelected: (d) {
                  setState(() { _districtId = d.districtNo; });
                },
              );
            },
    );
  }
}


