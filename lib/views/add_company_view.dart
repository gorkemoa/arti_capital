import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

import '../theme/app_colors.dart';
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

class _AddCompanyViewState extends State<AddCompanyView> {
  final _formKey = GlobalKey<FormState>();
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
  
  @override
  void initState() {
    super.initState();
    _loadCities();
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
    setState(() { _loadingMeta = true; _districts = const []; _selectedDistrict = null; });
    try {
      final d = await _generalService.getDistricts(cityNo);
      setState(() { _districts = d; });
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
    if (!_formKey.currentState!.validate()) return;
    
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

      final request = AddCompanyRequest(
        userToken: token,
        userIdentityNo: identityNo,
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
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firma Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Section
              _buildLogoSection(theme),
              const SizedBox(height: 24),
              
              // Company Name
              _buildTextField(
                controller: _compNameController,
                label: 'Firma Adı *',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Firma adı gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Tax Number
              _buildTextField(
                controller: _compTaxNoController,
                label: 'Vergi No *',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vergi numarası gereklidir';
                  }
                  if (value.trim().length != 10) {
                    return 'Vergi numarası 10 haneli olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Tax Office
              _buildTextField(
                controller: _compTaxPalaceController,
                label: 'Vergi Dairesi *',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vergi dairesi gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // City Dropdown
              _buildCityDropdown(theme),
              const SizedBox(height: 16),
              
              // District Dropdown
              _buildDistrictDropdown(theme),
              const SizedBox(height: 16),
              
              // Address
              _buildTextField(
                controller: _compAddressController,
                label: 'Adres',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // KEP Address
              _buildTextField(
                controller: _compKepAddressController,
                label: 'KEP Adresi',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // MERSIS No
              _buildTextField(
                controller: _compMersisNoController,
                label: 'MERSIS No',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              ElevatedButton(
                onPressed: _loading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _loading ? 'Ekleniyor...' : 'Firmayı Ekle',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
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
        // ignore: deprecated_member_use
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(
            'Firma Logosu',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (_logoBase64.isEmpty)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                // ignore: deprecated_member_use
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.apartment_outlined,
                size: 40,
                color: theme.colorScheme.outline,
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                // ignore: deprecated_member_use
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
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
                icon: const Icon(Icons.photo_library),
                label: Text(_logoBase64.isEmpty ? 'Logo Seç' : 'Değiştir'),
              ),
              if (_logoBase64.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _removeLogo,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Kaldır'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
    );
  }

  Widget _buildCityDropdown(ThemeData theme) {
    if (_loadingMeta && _cities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CityItem>(
          isExpanded: true,
          value: _selectedCity,
          hint: const Text('Şehir Seçin *'),
          items: _cities.map((city) {
            return DropdownMenuItem<CityItem>(
              value: city,
              child: Text(city.cityName),
            );
          }).toList(),
          onChanged: (CityItem? city) {
            setState(() {
              _selectedCity = city;
              _selectedDistrict = null; // Reset district when city changes
            });
            if (city != null) {
              _loadDistricts(city.cityNo);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown(ThemeData theme) {
    if (_loadingMeta && _selectedCity != null && _districts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DistrictItem>(
          isExpanded: true,
          value: _selectedDistrict,
          hint: const Text('İlçe Seçin *'),
          items: _districts.map((district) {
            return DropdownMenuItem<DistrictItem>(
              value: district,
              child: Text(district.districtName),
            );
          }).toList(),
          onChanged: _districts.isEmpty ? null : (DistrictItem? district) {
            setState(() {
              _selectedDistrict = district;
            });
          },
        ),
      ),
    );
  }
}
