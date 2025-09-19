import 'package:arti_capital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
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

enum FormStep { personal, company, location, address, additional, logo }

class _AddCompanyViewState extends State<AddCompanyView> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _userFirstnameController = TextEditingController();
  final _userLastnameController = TextEditingController();
  final _userBirthdayController = TextEditingController();
  final _compNameController = TextEditingController();
  final _compTaxNoController = TextEditingController();
  final _compTaxPalaceController = TextEditingController();
  final _compKepAddressController = TextEditingController();
  final _compMersisNoController = TextEditingController();
  final _compAddressController = TextEditingController();
  
  final UserService _userService = UserService();
  final GeneralService _generalService = GeneralService();
  
  List<CityItem> _cities = const [];
  CityItem? _selectedCity;
  bool _loading = false; // submit için
  bool _loadingMeta = true; // şehir/ilçe yükleme için
  String _logoBase64 = '';
  FormStep _currentStep = FormStep.personal;
  DateTime? _selectedBirthday;
  
  @override
  void initState() {
    super.initState();
    _loadCities();
    _prefillUserFields();
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

  void _prefillUserFields() {
    final userData = StorageService.getUserData();
    if (userData == null || userData.isEmpty) return;
    try {
      final dynamic parsed = jsonDecode(userData);
      if (parsed is Map<String, dynamic>) {
        final f = parsed['userFirstname'] as String?;
        final l = parsed['userLastname'] as String?;
        final b = parsed['userBirthday'] as String?;
        if (f != null && f.isNotEmpty) {
          _userFirstnameController.text = f.toUpperCase();
        }
        if (l != null && l.isNotEmpty) {
          _userLastnameController.text = l.toUpperCase();
        }
        if (b != null && b.isNotEmpty) {
          _userBirthdayController.text = b;
        }
      }
    } catch (_) {}
  }


  @override
  void dispose() {
    _userFirstnameController.dispose();
    _userLastnameController.dispose();
    _userBirthdayController.dispose();
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
    _formKey.currentState!.save();
    
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir şehir seçin')),
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

      // Kullanıcı kimlik no'yu al (userData JSON değil; toString kaydediliyor)
      final userData = StorageService.getUserData();
      if (userData == null) {
        throw Exception('Kullanıcı verisi bulunamadı');
      }
      String? identityNo;
      try {
        // Önce JSON gibi parse etmeyi dene (ileride düzeltilebilir)
        final dynamic parsed = jsonDecode(userData);
        if (parsed is Map<String, dynamic>) {
          identityNo = parsed['userIdentityNo'] as String?;
        }
      } catch (_) {
        // Stringleştirilmiş Map formatından çek
        final match = RegExp(r'userIdentityNo[:=]\s*([^,}\s]+)').firstMatch(userData);
        identityNo = match?.group(1);
      }
      if (identityNo == null || identityNo.isEmpty) {
        throw Exception('Kimlik numarası bulunamadı');
      }

      // FormBuilder'dan değerleri al
      final formData = _formKey.currentState!.value;
      final uppercaseFirstname = (formData['userFirstname'] as String? ?? '').trim().toUpperCase();
      final uppercaseLastname = (formData['userLastname'] as String? ?? '').trim().toUpperCase();
      final normalizedBirthday = _selectedBirthday != null ? DateFormat('dd.MM.yyyy').format(_selectedBirthday!) : '';

      final request = AddCompanyRequest(
        userToken: token,
        userFirstname: uppercaseFirstname,
        userLastname: uppercaseLastname,
        userBirthday: normalizedBirthday,
        userIdentityNo: identityNo,
        compName: (formData['compName'] as String? ?? '').trim(),
        compTaxNo: (formData['compTaxNo'] as String? ?? '').trim(),
        compTaxPalace: (formData['compTaxPalace'] as String? ?? '').trim(),
        compKepAddress: (formData['compKepAddress'] as String? ?? '').trim(),
        compMersisNo: (formData['compMersisNo'] as String? ?? '').trim(),
        compType: 1,
        compCity: _selectedCity!.cityNo,
        compDistrict: 0, // District artık seçilmiyor
        compAddress: (formData['compAddress'] as String? ?? '').trim(),
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
      body: FormBuilder(
        key: _formKey,
                child: Column(
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
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  // Step Navigation Methods
  void _nextStep() {
    setState(() {
      switch (_currentStep) {
        case FormStep.personal:
          _currentStep = FormStep.company;
          break;
        case FormStep.company:
          _currentStep = FormStep.location;
          break;
        case FormStep.location:
          _currentStep = FormStep.address;
          break;
        case FormStep.address:
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
        case FormStep.personal:
          // First step, can't go back
          break;
        case FormStep.company:
          _currentStep = FormStep.personal;
          break;
        case FormStep.location:
          _currentStep = FormStep.company;
          break;
        case FormStep.address:
          _currentStep = FormStep.location;
          break;
        case FormStep.additional:
          _currentStep = FormStep.address;
          break;
        case FormStep.logo:
          _currentStep = FormStep.additional;
          break;
      }
    });
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case FormStep.personal:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            _buildSectionTitle('Kişisel Bilgiler'),
            const SizedBox(height: 24),
            _buildPersonalInfoFields(),
          ],
        );
      case FormStep.company:
        return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
            _buildSectionTitle('Şirket Bilgileri'),
                          const SizedBox(height: 24),
            _buildCompanyInfoFields(),
          ],
        );
      case FormStep.location:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Konum Bilgileri'),
                          const SizedBox(height: 24),
            _buildLocationInfoFields(),
          ],
        );
      case FormStep.address:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Şirket Adresi'),
            const SizedBox(height: 24),
            _buildAddressField(),
          ],
        );
      case FormStep.additional:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Ek Bilgiler'),
            const SizedBox(height: 24),
            _buildCompanyTypeField(),
          ],
        );
      case FormStep.logo:
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
            _buildSectionTitle('Logo Yükleme'),
            const SizedBox(height: 24),
            _buildLogoUploadSection(),
          ],
        );
    }
  }

  Widget _buildStepIndicator() {
    final steps = [
      ('Kişisel', FormStep.personal, Icons.person_outline),
      ('Şirket', FormStep.company, Icons.business_outlined),
      ('Konum', FormStep.location, Icons.location_on_outlined),
      ('Adres', FormStep.address, Icons.home_outlined),
      ('Ek Bilgiler', FormStep.additional, Icons.info_outline),
      ('Logo', FormStep.logo, Icons.image_outlined),
    ];

    return Column(
            children: [
                Text(
          'Form Adımları',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 15,
                    fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
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
                  height: 28,
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
          if (_currentStep != FormStep.personal)
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
          
          if (_currentStep != FormStep.personal)
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

  Widget _buildPersonalInfoFields() {
    return Column(
      children: [
        _buildTextField(
          name: 'userFirstname',
          label: 'Ad',
          inputFormatters: [UpperCaseTextFormatter()],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          name: 'userLastname',
          label: 'Soyad',
          inputFormatters: [UpperCaseTextFormatter()],
        ),
        const SizedBox(height: 16),
        _buildBirthdayField(),
        const SizedBox(height: 16),
        _buildTextField(
          name: 'userIdentityNo',
          label: 'T.C. Kimlik No',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

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
      ],
    );
  }


  Widget _buildAddressField() {
    return FormBuilderTextField(
          name: 'compAddress',
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

  Widget _buildBirthdayField() {
    return GestureDetector(
      onTap: _showDatePicker,
      child: Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
      ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.onSurface.withOpacity(0.6),
                size: 20,
              ),
          const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedBirthday != null 
                      ? DateFormat('dd.MM.yyyy').format(_selectedBirthday!)
                      : 'Doğum Tarihi',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _selectedBirthday != null 
                        ? AppColors.onSurface 
                        : AppColors.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: AppColors.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePicker() {
    if (Platform.isIOS) {
      _showIOSDatePicker();
    } else {
      _showAndroidDatePicker();
    }
  }

  void _showIOSDatePicker() {
    showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: AppColors.surface,
        child: Column(
      children: [
        Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.9),
            borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
            ),
          ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'İptal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context, _selectedBirthday),
                    child: Text(
                      'Tamam',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedBirthday ?? DateTime.now(),
                minimumDate: DateTime.now(),
                maximumDate: DateTime.now().add(const Duration(days: 365 * 100)), // 100 yıl sonrasına kadar
                dateOrder: DatePickerDateOrder.dmy, // Gün, Ay, Yıl sırası
                onDateTimeChanged: (DateTime newDate) {
                  setState(() {
                    _selectedBirthday = newDate;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAndroidDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 100)), // 100 yıl sonrasına kadar
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Widget _buildTextField({
    required String name,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return FormBuilderTextField(
      name: name,
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
