import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/company_models.dart';
import '../models/support_models.dart';
import '../models/project_models.dart';
import '../services/projects_service.dart';
import '../services/company_service.dart';
import '../services/general_service.dart';
import '../theme/app_colors.dart';
import 'select_company_view.dart';

class EditProjectView extends StatefulWidget {
  final ProjectDetail project;

  const EditProjectView({
    super.key,
    required this.project,
  });

  @override
  State<EditProjectView> createState() => _EditProjectViewState();
}

class _EditProjectViewState extends State<EditProjectView> {
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
  bool _loadingCompany = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _projectTitleController.text = widget.project.appTitle;
    _projectDescController.text = widget.project.appDesc ?? '';
    _loadInitialData();
  }

  @override
  void dispose() {
    _projectTitleController.dispose();
    _projectDescController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadServices(),
      _loadCompanyAndAddress(),
    ]);
  }

  Future<void> _loadServices() async {
    setState(() => _loadingServices = true);
    try {
      final services = await _generalService.getAllServices();
      if (mounted) {
        setState(() {
          _services = services;
          // Mevcut servisi seç
          if (widget.project.serviceID != null) {
            _selectedService = _services.firstWhere(
              (s) => s.serviceID == widget.project.serviceID,
              orElse: () => _services.isNotEmpty ? _services.first : ServiceItem(serviceID: 0, serviceName: '', serviceDesc: '', serviceIcon: '', duties: []),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Servisler yüklenemedi: $e')),
        );
      }
    } finally {
      setState(() => _loadingServices = false);
    }
  }

  Future<void> _loadCompanyAndAddress() async {
    setState(() => _loadingCompany = true);
    try {
      // Firma detayını yükle
      final company = await _companyService.getCompanyDetail(widget.project.compID);
      if (company != null && mounted) {
        setState(() {
          _selectedCompany = company;
        });

        // Adresleri yükle
        final addresses = await _companyService.getCompanyAddresses(company.compID);
        if (mounted) {
          setState(() {
            _addresses = addresses;
            // Mevcut adresi seç
            _selectedAddress = _addresses.firstWhere(
              (a) => a.addressID == widget.project.compAdrID,
              orElse: () => _addresses.isNotEmpty ? _addresses.first : CompanyAddressItem(addressID: 0),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firma bilgileri yüklenemedi: $e')),
        );
      }
    } finally {
      setState(() => _loadingCompany = false);
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

  Widget _buildCupertinoField({
    required String placeholder,
    String? value,
    VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled 
              ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('İptal'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Seç'),
                      onPressed: () {
                        setState(() {
                          _selectedService = _services[selectedIndex];
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  itemExtent: 32,
                  onSelectedItemChanged: (int index) {
                    selectedIndex = index;
                  },
                  children: _services.map((service) => Center(child: Text(service.serviceName))).toList(),
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
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('İptal'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Seç'),
                      onPressed: () {
                        setState(() {
                          _selectedAddress = _addresses[selectedIndex];
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  itemExtent: 32,
                  onSelectedItemChanged: (int index) {
                    selectedIndex = index;
                  },
                  children: _addresses.map((addr) => Center(child: Text('${addr.addressType ?? 'Adres'} - ${addr.addressCity ?? ''}'))).toList(),
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
        title: const Text('Proje Düzenle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: _loadingServices || _loadingCompany
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  // Adres Seçimi
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
                    isDisabled: _selectedCompany == null || _addresses.isEmpty,
                    onTap: _selectedCompany == null || _addresses.isEmpty ? null : _showAddressPicker,
                  ),
                  const SizedBox(height: 16),

                  // Servis Seçimi
                  Text(
                    'Servis',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCupertinoField(
                    placeholder: 'Servis seçin',
                    value: _selectedService?.serviceName,
                    onTap: _loadingServices ? null : _showServicePicker,
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
                    controller: _projectTitleController,
                    decoration: InputDecoration(
                      hintText: 'Proje başlığı',
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
                    controller: _projectDescController,
                    decoration: InputDecoration(
                      hintText: 'Proje açıklaması (opsiyonel)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // Güncelle Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _handleUpdate,
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
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text(
                              'Güncelle',
                              style: TextStyle(
                                fontSize: 16,
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

  Future<void> _handleUpdate() async {
    // Validasyonlar
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir firma seçin')),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir adres seçin')),
      );
      return;
    }

    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir servis seçin')),
      );
      return;
    }

    if (_projectTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen proje başlığı girin')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await _projectsService.updateProject(
        projectID: widget.project.appID,
        compID: _selectedCompany!.compID,
        compAdrID: _selectedAddress!.addressID,
        serviceID: _selectedService!.serviceID,
        projectTitle: _projectTitleController.text.trim(),
        projectDesc: _projectDescController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'İşlem tamamlandı'),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
        
        if (response.success) {
          // Detay sayfasına geri dön ve yenile
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
