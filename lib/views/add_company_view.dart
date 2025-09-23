import 'dart:ui';

import 'package:arti_capital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
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

enum FormStep { company, location, logo }
enum PickerSource { gallery, files }

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
  List<TaxPalaceItem> _taxPalaces = const [];
  List<AddressTypeItem> _addressTypes = const [];
  CityItem? _selectedCity;
  DistrictItem? _selectedDistrict;
  TaxPalaceItem? _selectedTaxPalace;
  int? _selectedAddressTypeId;
  int? _selectedCompanyTypeId;
  bool _loading = false; // submit için
  bool _loadingMeta = true; // şehir/ilçe yükleme için
  String _logoBase64 = '';
  // Dashed container helper
  bool _hasUnsavedChanges = false;
  FormStep _currentStep = FormStep.company;
  // _selectedBirthday kaldırıldı - doğum tarihi alanı kaldırıldı
  
  // Step-specific form keys
  // Kişisel step kaldırıldı
  final _companyFormKey = GlobalKey<FormBuilderState>();
  final _locationFormKey = GlobalKey<FormBuilderState>();
  final _logoFormKey = GlobalKey<FormBuilderState>();
  
  @override
  void initState() {
    super.initState();
    _loadCities();
    _loadAddressTypes();
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

  Future<void> _loadAddressTypes() async {
    try {
      final types = await _generalService.getAddressTypes();
      if (!mounted) return;
      setState(() {
        _addressTypes = types;
      });
    } catch (_) {}
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

  Future<void> _loadTaxPalaces(int cityNo) async {
    setState(() { _loadingMeta = true; });
    try {
      final taxPalaces = await _generalService.getTaxPalaces(cityNo);
      setState(() {
        _taxPalaces = taxPalaces;
        _selectedTaxPalace = null; // Yeni şehir seçildiğinde vergi dairesi sıfırla
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vergi dairesi listesi alınamadı')),
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

  Future<PickerSource?> _askPickerSource() async {
    if (Platform.isIOS) {
      return await showCupertinoModalPopup<PickerSource>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Logo Ekle'),
          message: const Text('Kaynak seçin'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, PickerSource.gallery),
              child: const Text('Fotoğraflar'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, PickerSource.files),
              child: const Text('Dosyalar'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            isDestructiveAction: false,
            child: const Text('İptal'),
          ),
        ),
      );
    }

    // Android / others: Material bottom sheet
    return await showModalBottomSheet<PickerSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Fotoğraflar'),
                onTap: () => Navigator.pop(context, PickerSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Dosyalar'),
                onTap: () => Navigator.pop(context, PickerSource.files),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('İptal'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickLogo() async {
    try {
      // Kullanıcıya seçim kaynağını sor (native UI)
      final PickerSource? source = await _askPickerSource();

      Uint8List? bytes;
      String pickedFilePath = '';

      if (source == PickerSource.gallery) {
        final ImagePicker picker = ImagePicker();
        final XFile? xfile = await picker.pickImage(source: ImageSource.gallery);
        if (xfile != null) {
          pickedFilePath = xfile.path;
          bytes = await xfile.readAsBytes();
        }
      } else if (source == PickerSource.files) {
        // Dosyalardan seç: FilePicker
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['png','jpg','jpeg','gif','webp','heic','heif'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
          pickedFilePath = file.path ?? '';
          bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
        }
      } else {
        return; // iptal
        }
        
        if (bytes != null) {
          // 1) Geçici dosya oluştur ve kırpma ekranını aç
          final String tempPath = pickedFilePath;
          final CroppedFile? cropped = await ImageCropper().cropImage(
            sourcePath: tempPath,
            compressFormat: ImageCompressFormat.jpg,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Görseli Düzenle',
                toolbarColor: AppColors.primary,
                toolbarWidgetColor: AppColors.onPrimary,
                activeControlsWidgetColor: AppColors.primary,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
              ),
              IOSUiSettings(
                title: 'Görseli Düzenle',
                aspectRatioLockEnabled: true,
                resetButtonHidden: false,
                rotateButtonsHidden: false,
              ),
            ],
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          );

          Uint8List finalBytes;
          if (cropped != null) {
            final croppedBytes = await File(cropped.path).readAsBytes();
            finalBytes = croppedBytes;
          } else {
            finalBytes = bytes; // kullanıcı iptal ettiyse orijinali kullan
          }

          // 2) 600x600'e yeniden boyutlandır
          try {
            final img.Image? original = img.decodeImage(finalBytes);
            if (original != null) {
              final img.Image resized = img.copyResizeCropSquare(original, size: 600);
              // JPEG ile sıkıştır (daha küçük boyut için)
              finalBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 80));
            }
          } catch (_) {}

          final base64String = base64Encode(finalBytes);
          // Dosya tipini belirle
          String mimeType = 'image/jpeg';
          
          setState(() {
            _logoBase64 = 'data:$mimeType;base64,$base64String';
            _hasUnsavedChanges = true;
          });
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
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _submitForm() async {
    // Tüm step formlarını kaydet
    // Kişisel step yok
    _companyFormKey.currentState?.save();
    _locationFormKey.currentState?.save();
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

      // userIdentityNo çek (bulunamazsa boş gönder)
      String identityNo = '';
      final userData = StorageService.getUserData();
      if (userData != null) {
        try {
          final dynamic parsed = jsonDecode(userData);
          if (parsed is Map<String, dynamic>) identityNo = (parsed['userIdentityNo'] as String?)?.trim() ?? '';
        } catch (_) {
          final match = RegExp(r'userIdentityNo[:=]\s*([^,}\s]+)').firstMatch(userData);
          identityNo = (match != null ? match.group(1) : '') ?? '';
        }
      }

      // Vergi dairesi ID'si (seçilen vergi dairesinden)
      final int compTaxPalaceInt = _selectedTaxPalace?.palaceID ?? 0;

      final request = AddCompanyRequest(
        userToken: token,
        userIdentityNo: identityNo,
        compName: _compNameController.text.trim(),
        compTaxNo: _compTaxNoController.text.trim(),
        compTaxPalace: compTaxPalaceInt,
        compKepAddress: _compKepAddressController.text.trim(),
        compMersisNo: _compMersisNoController.text.trim(),
        compType: _selectedCompanyTypeId ?? 1,
        compCity: _selectedCity!.cityNo,
        compDistrict: _selectedDistrict!.districtNo,
        compAddress: _compAddressController.text.trim(),
        compAddressType: _selectedAddressTypeId ?? 1,
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
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          final bool? leave = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Çıkmak istiyor musunuz?'),
                content: const Text('Kaydedilmemiş değişiklikler var. Çıkarsanız kaybolacak.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('İptal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Çık'),
                  ),
                ],
              );
            },
          );
          return leave ?? false;
        }
        return true;
      },
      child: Scaffold(
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
      ),
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
        case FormStep.logo:
          _currentStep = FormStep.location;
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
                    width: 100,
                    height: 3,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 8),
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
        _buildCompanyTypeField(),
        const SizedBox(height: 16),
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
        // Vergi dairesi artık dropdown olarak konum bölümünde
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
         _buildAddressTypeDropdown(Theme.of(context)),
        const SizedBox(height: 16),
        _buildCityDropdown(Theme.of(context)),
        const SizedBox(height: 16),
        _buildDistrictDropdown(Theme.of(context)),
        const SizedBox(height: 16),
       
        _buildTaxPalaceDropdown(Theme.of(context)),
      ],
    );
  }

  Widget _buildAddressTypeDropdown(ThemeData theme) {
    if (_addressTypes.isEmpty) {
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
        child: DropdownButton<int>(
          isExpanded: true,
          value: _selectedAddressTypeId,
          // Seçim yoksa placeholder görünsün diye `value` null kalmalı
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Adres Tipi',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    // ignore: deprecated_member_use
                    color: AppColors.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          items: _addressTypes.map((type) {
            return DropdownMenuItem<int>(
              value: type.typeID,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  type.typeName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (int? typeId) {
            setState(() {
              _selectedAddressTypeId = typeId;
              _hasUnsavedChanges = true;
            });
          },
        ),
      ),
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
    return FutureBuilder<List<CompanyTypeItem>>(
      future: _generalService.getCompanyTypes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Şirket türleri alınamadı',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final types = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _selectedCompanyTypeId,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
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
              items: types.map((type) {
                return DropdownMenuItem<int>(
                  value: type.typeID,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      type.typeName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (int? typeId) {
                setState(() {
                  _selectedCompanyTypeId = typeId;
                  _hasUnsavedChanges = true;
                });
              },
            ),
          ),
        );
      },
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
        const SizedBox(height: 20),
        if (_logoBase64.isEmpty) ...[
          GestureDetector(
            onTap: _pickLogo,
            child: DashedBorderContainer(
              width: 240,
              height: 140,
              borderColor: AppColors.primary.withOpacity(0.6),
              dashWidth: 6,
              dashSpace: 4,
              radius: 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, color: AppColors.primary, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'Görsel Seç \n (PNG, JPG, JPEG, HEIC)',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 160,
            child: ElevatedButton.icon(
              onPressed: _pickLogo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Logo Ekle'),
            ),
          ),
        ] else ...[
          DashedBorderContainer(
            width: 240,
            height: 140,
            borderColor: Colors.grey.shade400,
            dashWidth: 6,
            dashSpace: 4,
            radius: 8,
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



  Widget _buildTaxPalaceDropdown(ThemeData theme) {
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

    if (_loadingMeta && _taxPalaces.isEmpty) {
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
          value: _selectedTaxPalace,
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
          items: _taxPalaces.map((palace) {
            return DropdownMenuItem<TaxPalaceItem>(
              value: palace,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  palace.palaceName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (TaxPalaceItem? palace) {
            setState(() {
              _selectedTaxPalace = palace;
              _hasUnsavedChanges = true;
            });
          },
        ),
      ),
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
              _loadTaxPalaces(city.cityNo);
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

class DashedBorderContainer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color borderColor;
  final double dashWidth;
  final double dashSpace;
  final Widget child;

  const DashedBorderContainer({
    super.key,
    required this.width,
    required this.height,
    required this.borderColor,
    required this.dashWidth,
    required this.dashSpace,
    this.radius = 8,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: borderColor,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
        radius: radius,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  _DashedRectPainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final PathMetrics metrics = path.computeMetrics();
    for (final PathMetric metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
