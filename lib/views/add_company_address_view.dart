import 'package:flutter/material.dart';

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
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
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
    setState(() => _loading = false);

    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adres eklendi.')));
      Navigator.of(context).pop(true);
    } else {
      final msg = resp.errorMessage ?? resp.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.isNotEmpty ? msg : 'Adres eklenemedi')));
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adres Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Adres Tipi'),
              value: _addressType,
              items: _addressTypes
                  .map((t) => DropdownMenuItem(value: t.typeID, child: Text(t.typeName)))
                  .toList(),
              onChanged: _loading ? null : (v) => setState(() => _addressType = v),
              validator: (v) => v == null ? 'Adres tipi seçiniz' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'İl'),
              value: _cityId,
              items: _cities
                  .map((c) => DropdownMenuItem(value: c.cityNo, child: Text(c.cityName)))
                  .toList(),
              onChanged: _loading
                  ? null
                  : (v) {
                      setState(() => _cityId = v);
                      if (v != null) _loadDistricts(v);
                    },
              validator: (v) => v == null ? 'İl seçiniz' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'İlçe'),
              value: _districtId,
              items: _districts
                  .map((d) => DropdownMenuItem(value: d.districtNo, child: Text(d.districtName)))
                  .toList(),
              onChanged: _loading ? null : (v) => setState(() => _districtId = v),
              validator: (v) => v == null ? 'İlçe seçiniz' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
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


