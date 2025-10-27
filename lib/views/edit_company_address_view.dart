import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/company_models.dart';
import '../models/location_models.dart';
import '../services/company_service.dart';
import '../services/general_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class EditCompanyAddressView extends StatefulWidget {
  const EditCompanyAddressView({super.key, required this.compId, required this.address});
  final int compId;
  final CompanyAddressItem address;

  @override
  State<EditCompanyAddressView> createState() => _EditCompanyAddressViewState();
}

class _EditCompanyAddressViewState extends State<EditCompanyAddressView> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  List<CityItem> _cities = const [];
  List<DistrictItem> _districts = const [];
  List<AddressTypeItem> _addressTypes = const [];

  int? _addressType;
  int? _cityId;
  int? _districtId;
  final TextEditingController _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _primeData();
  }

  Future<void> _primeData() async {
    final service = GeneralService();
    final results = await Future.wait([
      service.getCities(),
      service.getAddressTypes(),
      service.getDistricts(widget.address.addressCityID ?? 0),
    ]);
    if (!mounted) return;
    setState(() {
      _cities = results[0] as List<CityItem>;
      _addressTypes = results[1] as List<AddressTypeItem>;
      _districts = results[2] as List<DistrictItem>;
      _addressType = widget.address.addressTypeID;
      _cityId = widget.address.addressCityID;
      _districtId = widget.address.addressDistrictID;
      _addressCtrl.text = widget.address.addressAddress ?? '';
    });
  }

  Future<void> _loadDistricts(int cityNo) async {
    setState(() {
      _districts = const [];
      _districtId = null;
    });
    final items = await GeneralService().getDistricts(cityNo);
    if (!mounted) return;
    setState(() {
      _districts = items;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = await StorageService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }

    setState(() => _loading = true);
    final resp = await const CompanyService().updateCompanyAddress(
      UpdateCompanyAddressRequest(
        userToken: token,
        compID: widget.compId,
        addressID: widget.address.addressID,
        addressType: _addressType!,
        addressCity: _cityId!,
        addressDistrict: _districtId!,
        addressAddress: _addressCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adres güncellendi.')));
      Navigator.of(context).pop(true);
    } else {
      final msg = resp.errorMessage ?? resp.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.isNotEmpty ? msg : 'Adres güncellenemedi')));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adres Düzenle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Adres Tipi (Cupertino)
            _buildCupertinoField(
              placeholder: 'Adres Tipi',
              value: (_addressType == null)
                  ? null
                  : (() {
                      try {
                        return _addressTypes.firstWhere((t) => t.typeID == _addressType).typeName;
                      } catch (_) { return null; }
                    })(),
              onTap: _loading || _addressTypes.isEmpty
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
                        onSelected: (t) { setState(() { _addressType = t.typeID; }); },
                      );
                    },
            ),
            const SizedBox(height: 12),

            // İl (Cupertino)
            _buildCupertinoField(
              placeholder: 'İl',
              value: (_cityId == null)
                  ? null
                  : (() {
                      try { return _cities.firstWhere((c) => c.cityNo == _cityId).cityName; } catch (_) { return null; }
                    })(),
              onTap: _loading || _cities.isEmpty
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
                          await _loadDistricts(city.cityNo);
                        },
                      );
                    },
            ),
            const SizedBox(height: 12),

            // İlçe (Cupertino)
            _buildCupertinoField(
              placeholder: 'İlçe',
              value: (_districtId == null)
                  ? null
                  : (() { try { return _districts.firstWhere((d) => d.districtNo == _districtId).districtName; } catch (_) { return null; } })(),
              onTap: _loading || _districts.isEmpty
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
                        onSelected: (d) { setState(() { _districtId = d.districtNo; }); },
                      );
                    },
            ),
            const SizedBox(height: 12),

            TextFormField(
            textCapitalization: TextCapitalization.sentences,
              controller: _addressCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Adres'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Kaydet'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


