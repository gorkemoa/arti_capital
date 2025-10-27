import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/company_models.dart';
import '../models/support_models.dart';
import '../services/projects_service.dart';
import '../services/company_service.dart';
import '../services/general_service.dart';
import '../theme/app_colors.dart';
import 'select_company_view.dart';

class AddProjectView extends StatefulWidget {
  const AddProjectView({super.key, this.preselectedService});

  final ServiceItem? preselectedService;

  @override
  State<AddProjectView> createState() => _AddProjectViewState();
}

class _AddProjectViewState extends State<AddProjectView> {
  final _projectTitleController = TextEditingController();
  final _projectDescController = TextEditingController();
  final ProjectsService _projectsService = ProjectsService();
  final CompanyService _companyService = CompanyService();
  final GeneralService _generalService = GeneralService();

  List<ServiceItem> _services = [];
  List<CompanyAddressItem> _addresses = [];
  
  CompanyItem? _selectedCompany;
  CompanyAddressItem? _selectedAddress;
  ServiceItem? _selectedService;
  
  bool _loadingServices = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
    if (widget.preselectedService != null) {
      _selectedService = widget.preselectedService;
    }
  }

  Future<void> _loadServices() async {
    setState(() => _loadingServices = true);
    try {
      final services = await _generalService.getAllServices();
      setState(() {
        _services = services;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Destekler yüklenemedi: $e')),
        );
      }
    } finally {
      setState(() => _loadingServices = false);
    }
  }

  void _onCompanySelected(CompanyItem? company) async {
    if (company == null) return;
    
    setState(() {
      _selectedCompany = company;
      _addresses = [];
      _selectedAddress = null;
    });

    try {
      final addresses = await _companyService.getCompanyAddresses(company.compID);
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Adresler yüklenemedi: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _projectTitleController.dispose();
    _projectDescController.dispose();
    super.dispose();
  }

  Widget _buildCupertinoField({
    required String placeholder,
    required String? value,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDisabled 
              ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled 
                ? Colors.grey.shade200
                : Colors.grey.shade300,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null || value.isEmpty ? placeholder : value,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (value == null || value.isEmpty)
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(isDisabled ? 0.4 : 0.6)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(isDisabled ? 0.5 : 1),
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(isDisabled ? 0.3 : 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showServicePicker() async {
    if (_services.isEmpty) return;

    int selectedIndex = _selectedService != null
        ? _services.indexWhere((s) => s.serviceID == _selectedService!.serviceID)
        : 0;
    if (selectedIndex < 0) selectedIndex = 0;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('İptal'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    Text('Destek Seç', style: Theme.of(context).textTheme.titleMedium),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('Bitti'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 44,
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedService = _services[index];
                    });
                  },
                  children: _services.map((service) {
                    return Container(
                      alignment: Alignment.center,
                      child: Text(
                        service.serviceName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddressPicker() async {
    if (_addresses.isEmpty) return;

    int selectedIndex = _selectedAddress != null
        ? _addresses.indexWhere((a) => a.addressID == _selectedAddress!.addressID)
        : 0;
    if (selectedIndex < 0) selectedIndex = 0;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('İptal'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    Text('Adres Seç', style: Theme.of(context).textTheme.titleMedium),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('Bitti'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 50,
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedAddress = _addresses[index];
                    });
                  },
                  children: _addresses.map((address) {
                    return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      child: Text(
                        '${address.addressType ?? 'Adres'} - ${address.addressAddress ?? ''}',
                        style: const TextStyle(fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 4,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Proje'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: _loadingServices
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Destek Seçimi (iOS Picker)
                    Text(
                      'Destek',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCupertinoField(
                      placeholder: 'Destek seçin',
                      value: _selectedService?.serviceName,
                      onTap: _loadingServices ? null : _showServicePicker,
                    ),
                    const SizedBox(height: 16),

                    // Firma Seçimi
                    Text(
                      'Firma',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCupertinoField(
                      placeholder: 'Firma seçin',
                      value: _selectedCompany?.compName,
                      onTap: () async {
                        final result = await Navigator.of(context).push<CompanyItem>(
                          MaterialPageRoute(builder: (_) => const SelectCompanyView()),
                        );
                        if (result != null) {
                          _onCompanySelected(result);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Adres Seçimi (iOS Picker)
                    Text(
                      'Adres',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCupertinoField(
                      placeholder: 'Adres seçin',
                      value: _selectedAddress != null
                          ? '${_selectedAddress!.addressType ?? 'Adres'} - ${_selectedAddress!.addressCity ?? ''}'
                          : null,
                      onTap: _selectedCompany == null || _addresses.isEmpty ? null : _showAddressPicker,
                    ),
                    const SizedBox(height: 16),

                    // Proje Başlığı
                    Text(
                      'Proje Başlığı',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
            textCapitalization: TextCapitalization.sentences,
                      controller: _projectTitleController,
                      decoration: InputDecoration(
                        hintText: 'Proje başlığını girin',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Proje Açıklaması
                    Text(
                      'Proje Açıklaması',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
            textCapitalization: TextCapitalization.sentences,
                      controller: _projectDescController,
                      decoration: InputDecoration(
                        hintText: 'Proje açıklaması',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // Kaydet Butonu
                    ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                              setState(() => _submitting = true);
                              try {
                                final response =
                                    await _projectsService.addProject(
                                  compID: _selectedCompany?.compID ?? 0,
                                  compAdrID: _selectedAddress?.addressID ?? 0,
                                  serviceID: _selectedService?.serviceID ?? 0,
                                  projectTitle:
                                      _projectTitleController.text.trim(),
                                  projectDesc:
                                      _projectDescController.text.trim(),
                                );

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        response.message ?? 'Proje başarıyla eklendi'
                                      ),
                                      backgroundColor: response.success ? Colors.green : Colors.red,
                                    ),
                                  );
                                  if (response.success && mounted) {
                                    // Proje ID'si ile geri dön
                                    Navigator.pop(context, response.projectID);
                                  }
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _submitting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Text(
                              'Proje Ekle',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
    );
  }
}
