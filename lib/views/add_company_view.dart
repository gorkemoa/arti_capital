import 'package:arti_capital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:intl/intl.dart'; // Kaldırıldı - doğum tarihi alanı kaldırıldı
import 'package:flutter/cupertino.dart';

import '../models/company_models.dart';
import '../models/location_models.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../services/logger.dart';
import '../services/general_service.dart';

class AddCompanyView extends StatefulWidget {
  const AddCompanyView({super.key});

  @override
  State<AddCompanyView> createState() => _AddCompanyViewState();
}

enum FormStep { company, location, additional, logo }

class _AddCompanyViewState extends State<AddCompanyView> {
  // _formKey kaldırıldı - artık step-specific form key'ler kullanılıyor
  // Kişisel alanlar kaldırıldı
  final _compNameController = TextEditingController();
  final _compTaxNoController = TextEditingController();
  final _compTaxPalaceController = TextEditingController();
  final _compKepAddressController = TextEditingController();
  final _compMersisNoController = TextEditingController();
  final _compAddressController = TextEditingController();
  
  final UserService _userService = UserService();
  final GeneralService _generalService = GeneralService();
  
  List<CityItem> _cities = const [];
  List<DistrictItem> _districts = const [];
  CityItem? _selectedCity;
  DistrictItem? _selectedDistrict;
  bool _loading = false; // submit için
  bool _loadingMeta = true; // şehir/ilçe yükleme için
  String _logoBase64 = '';
  FormStep _currentStep = FormStep.company;
  // _selectedBirthday kaldırıldı - doğum tarihi alanı kaldırıldı
  
  // Step-specific form keys
  // Kişisel step kaldırıldı
  final _companyFormKey = GlobalKey<FormBuilderState>();
  final _locationFormKey = GlobalKey<FormBuilderState>();
  final _additionalFormKey = GlobalKey<FormBuilderState>();
  final _logoFormKey = GlobalKey<FormBuilderState>();
  
  @override
  void initState() {
    super.initState();
    _loadCities();
    // Kişisel alanlar kaldırıldığı için prefill yok
  }

  Future<void> _loadCities() async {
    setState(() { _loadingMeta = true; });
    try {
      final cities = await _generalService.getCities();
      setState(() {
        _cities = cities;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şehir listesi alınamadı')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _loadingMeta = false; });
      }
    }
  }

  Future<void> _loadDistricts(int cityNo) async {
    setState(() { _loadingMeta = true; });
    try {
      final districts = await _generalService.getDistricts(cityNo);
      setState(() {
        _districts = districts;
        _selectedDistrict = null; // Yeni şehir seçildiğinde ilçe sıfırla
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlçe listesi alınamadı')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _loadingMeta = false; });
      }
    }
  }

  // Kişisel alanlar kaldırıldığı için prefill fonksiyonu kaldırıldı


  @override
  void dispose() {
    // Kişisel controllerlar kaldırıldı
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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes = file.bytes;
        
        // Bazı platformlarda bytes null olabilir, path üzerinden oku
        if (bytes == null && file.path != null) {
          try {
            bytes = await File(file.path!).readAsBytes();
          } catch (_) {}
        }
        
        if (bytes != null) {
          final base64String = base64Encode(bytes);
          
          // Dosya tipini belirle
          String mimeType = 'image/png';
          final fileName = file.name.toLowerCase();
          if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
            mimeType = 'image/jpeg';
          }
          
          setState(() {
            _logoBase64 = 'data:$mimeType;base64,$base64String';
          });
        }
      }
    } catch (e) {
      AppLogger.e('Logo seçme hatası: $e', tag: 'ADD_COMPANY');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo seçilirken bir hata oluştu')),
        );
      }
    }
  }

  Future<void> _removeLogo() async {
    setState(() {
      _logoBase64 = '';
    });
  }

  Future<void> _submitForm() async {
    // Tüm step formlarını kaydet
    // Kişisel step yok
    _companyFormKey.currentState?.save();
    _locationFormKey.currentState?.save();
    _additionalFormKey.currentState?.save();
    _logoFormKey.currentState?.save();
    
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir şehir seçin')),
      );
      return;
    }
    
    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir ilçe seçin')),
      );
      return;
    }
    

    setState(() {
      _loading = true;
    });

    try {
      final token = StorageService.getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final request = AddCompanyRequest(
        userToken: token,
        compName: _compNameController.text.trim(),
        compTaxNo: _compTaxNoController.text.trim(),
        compTaxPalace: _compTaxPalaceController.text.trim(),
        compKepAddress: _compKepAddressController.text.trim(),
        compMersisNo: _compMersisNoController.text.trim(),
        compType: 1,
        compCity: _selectedCity!.cityNo,
        compDistrict: _selectedDistrict!.districtNo,
        compAddress: _compAddressController.text.trim(),
        compLogo: _logoBase64,
      );

      final response = await _userService.addCompany(request);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
          Navigator.of(context).pop(true); // true döndürerek refresh tetikle
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty 
                  ? response.message 
                  : response.errorMessage ?? 'Bir hata oluştu'),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.e('Firma ekleme hatası: $e', tag: 'ADD_COMPANY');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firma eklenirken bir hata oluştu')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Firma Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
        ],
      ),
      body: Column(
                  children: [
          // Top step indicator
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: _buildStepIndicator(),
          ),
          // Main content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStepContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  // Step Navigation Methods
  void _nextStep() {
    setState(() {
      switch (_currentStep) {
        case FormStep.company:
          _currentStep = FormStep.location;
          break;
        case FormStep.location:
          _currentStep = FormStep.additional;
          break;
        case FormStep.additional:
          _currentStep = FormStep.logo;
          break;
        case FormStep.logo:
          // Last step, submit form
          _submitForm();
          break;
      }
    });
  }

  void _previousStep() {
    setState(() {
      switch (_currentStep) {
        case FormStep.company:
          // First step, can't go back
          break;
        case FormStep.location:
          _currentStep = FormStep.company;
          break;
        case FormStep.additional:
          _currentStep = FormStep.location;
          break;
        case FormStep.logo:
          _currentStep = FormStep.additional;
          break;
      }
    });
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case FormStep.company:
        return FormBuilder(
          key: _companyFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              _buildSectionTitle('Şirket Bilgileri'),
                    const SizedBox(height: 24),
              _buildCompanyInfoFields(),
                  ],
                ),
              );
      case FormStep.location:
        return FormBuilder(
          key: _locationFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
              _buildSectionTitle('Konum Bilgileri'),
                          const SizedBox(height: 24),
              _buildLocationInfoFields(),
                          const SizedBox(height: 24),
              _buildAddressField(),
            ],
          ),
        );
      case FormStep.additional:
        return FormBuilder(
          key: _additionalFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Ek Bilgiler'),
              const SizedBox(height: 24),
              _buildCompanyTypeField(),
            ],
          ),
        );
      case FormStep.logo:
        return FormBuilder(
          key: _logoFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Logo Yükleme'),
              const SizedBox(height: 24),
              _buildLogoUploadSection(),
            ],
          ),
        );
    }
  }

  Widget _buildStepIndicator() {
    final steps = [
      ('Şirket', FormStep.company, Icons.business_outlined),
      ('Konum', FormStep.location, Icons.location_on_outlined),
      ('Ek Bilgiler', FormStep.additional, Icons.info_outline),
      ('Logo', FormStep.logo, Icons.image_outlined),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final (title, step, icon) = entry.value;
            final isActive = _currentStep == step;
            final isCompleted = _currentStep.index > step.index;
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Step indicator
        Container(
                  width: 28,
                  height: 30,
          decoration: BoxDecoration(
                    color: isActive 
                        ? AppColors.primary
                        : isCompleted 
                            ? Colors.green 
                            : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : icon,
                    color: isActive || isCompleted ? AppColors.onPrimary : Colors.grey[600],
                    size: 14,
                  ),
                ),
                // Connector line (except for last item)
                if (index < steps.length - 1)
                  Container(
                    width: 12,
                    height: 2,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNavigationBar() {
      return Container(
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
          // Previous button
          if (_currentStep != FormStep.company)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Geri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          if (_currentStep != FormStep.company)
            const SizedBox(width: 16),
          
          // Next/Submit button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _loading ? null : _nextStep,
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
                      _currentStep == FormStep.logo ? 'Kaydet' : 'İleri',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // New UI Helper Methods
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    );
  }

  // _buildPersonalInfoFields kaldırıldı - kişisel alanlar kaldırıldı

  Widget _buildCompanyInfoFields() {
    return Column(
      children: [
        _buildTextField(
          name: 'compName',
          label: 'Şirket Adı',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          name: 'compTaxNo',
          label: 'Vergi No',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          name: 'compTaxPalace',
          label: 'Vergi Dairesi',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          name: 'compMersisNo',
          label: 'MERSİS No',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          name: 'compKepAddress',
          label: 'KEP Adresi',
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildLocationInfoFields() {
    return Column(
      children: [
        _buildCityDropdown(Theme.of(context)),
        const SizedBox(height: 16),
        _buildDistrictDropdown(Theme.of(context)),
      ],
    );
  }

  Widget _buildDistrictDropdown(ThemeData theme) {
    if (_selectedCity == null) {
    return Container(
        height: 56,
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
              Icon(Icons.expand_more, color: AppColors.onSurface.withOpacity(0.6)),
                const SizedBox(width: 12),
              Text(
                'Önce il seçin',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.6),
                ),
              ),
            ],
        ),
      ),
    );
  }

    if (_loadingMeta && _districts.isEmpty) {
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
                Icon(Icons.expand_more, color: AppColors.onSurface.withOpacity(0.6)),
                const SizedBox(width: 12),
                Text(
                  'İlçe',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          items: _districts.map((district) {
            return DropdownMenuItem<DistrictItem>(
              value: district,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  district.districtName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (DistrictItem? district) {
            setState(() {
              _selectedDistrict = district;
            });
          },
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return TextField(
      controller: _compAddressController,
          decoration: InputDecoration(
        labelText: 'Şirket Adresi',
        hintText: 'Detaylı adres bilgilerini girin',
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface.withOpacity(0.6),
        ),
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface.withOpacity(0.4),
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
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
        fillColor: AppColors.surface,
        alignLabelWithHint: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurface,
      ),
      maxLines: 4,
    );
  }

  Widget _buildCompanyTypeField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: null,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
                children: [
                Icon(Icons.expand_more, color: AppColors.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 12),
                  Text(
                  'Şirket Türü',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
            ),
          ),
          items: const [
            DropdownMenuItem(value: '1', child: Text('Limited Şirket')),
            DropdownMenuItem(value: '2', child: Text('Anonim Şirket')),
            DropdownMenuItem(value: '3', child: Text('Kollektif Şirket')),
            DropdownMenuItem(value: '4', child: Text('Komandit Şirket')),
          ],
          onChanged: (String? value) {
            // Handle dropdown selection
          },
              ),
      ),
    );
  }

  Widget _buildLogoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Şirket Logosunu Yükle',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'PNG, JPG, GIF (MAX. 800×400px)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 20),
        if (_logoBase64.isEmpty) ...[
          ElevatedButton(
            onPressed: _pickLogo,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Dosya Seç',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ] else ...[
          Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(_logoBase64.split(',').last),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
              children: [
              TextButton.icon(
                onPressed: _pickLogo,
                icon: Icon(Icons.edit, color: AppColors.primary),
                label: Text(
                  'Değiştir',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: _removeLogo,
                icon: Icon(Icons.delete_outline, color: Colors.red),
                label: Text(
                  'Kaldır',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                  ),
            ),
          ),
        ],
      ),
        ],
      ],
    );
  }

  // _buildBirthdayField kaldırıldı - doğum tarihi alanı kaldırıldı

  // Date picker metodları kaldırıldı - doğum tarihi alanı kaldırıldı

  Widget _buildTextField({
    required String name,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    // Controller'ı name'e göre bul
    TextEditingController? controller;
    switch (name) {
     
      case 'compName':
        controller = _compNameController;
        break;
      case 'compTaxNo':
        controller = _compTaxNoController;
        break;
      case 'compTaxPalace':
        controller = _compTaxPalaceController;
        break;
      case 'compKepAddress':
        controller = _compKepAddressController;
        break;
      case 'compMersisNo':
        controller = _compMersisNoController;
        break;
      case 'compAddress':
        controller = _compAddressController;
        break;
    }
    
    return TextField(
      controller: controller,
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
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
        fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurface,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
                Icon(Icons.expand_more, color: AppColors.onSurface.withOpacity(0.6)),
                const SizedBox(width: 12),
                Text(
                  'İl',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
          items: _cities.map((city) {
            return DropdownMenuItem<CityItem>(
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
              );
          }).toList(),
          onChanged: (CityItem? city) {
            setState(() {
              _selectedCity = city;
            });
            if (city != null) {
              _loadDistricts(city.cityNo);
            }
            },
          ),
        ),
    );
  }








}


class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
