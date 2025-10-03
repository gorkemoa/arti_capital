import 'package:flutter/material.dart';

import '../models/company_models.dart';
import '../services/company_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class AddCompanyPasswordView extends StatefulWidget {
  const AddCompanyPasswordView({super.key, required this.compId});
  final int compId;

  @override
  State<AddCompanyPasswordView> createState() => _AddCompanyPasswordViewState();
}

class _AddCompanyPasswordViewState extends State<AddCompanyPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _loading = false;
  bool _typesLoading = true;
  bool _obscurePassword = true;
  int? _selectedPasswordType;
  List<PasswordTypeItem> _passwordTypes = [];

  @override
  void initState() {
    super.initState();
    _loadPasswordTypes();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadPasswordTypes() async {
    setState(() { _typesLoading = true; });
    try {
      final response = await const CompanyService().getPasswordTypes();
      if (mounted) {
        setState(() {
          _passwordTypes = response.types;
          _typesLoading = false;
          if (_passwordTypes.isNotEmpty) {
            _selectedPasswordType = _passwordTypes.first.typeID;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _typesLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre türleri yüklenirken hata oluştu')),
        );
      }
    }
  }

  Future<void> _addPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPasswordType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir şifre türü seçin')),
      );
      return;
    }

    setState(() { _loading = true; });

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oturum bulunamadı')),
        );
        return;
      }

      final request = AddCompanyPasswordRequest(
        userToken: token,
        compID: widget.compId,
        passType: _selectedPasswordType!,
        passUsername: _usernameController.text.trim(),
        passPassword: _passwordController.text.trim(),
      );

      final response = await const CompanyService().addCompanyPassword(request);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre eklenirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifre Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Şifre Bilgileri',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Password Type Dropdown
                      _typesLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonFormField<int>(
                                value: _selectedPasswordType,
                                decoration: const InputDecoration(
                                  labelText: 'Şifre Türü *',
                                  hintText: 'Şifre türünü seçin',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  prefixIcon: Icon(Icons.category, color: Colors.blue),
                                ),
                                dropdownColor: Colors.white,
                                elevation: 8,
                                borderRadius: BorderRadius.circular(12),
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                                items: _passwordTypes.map((type) {
                                  return DropdownMenuItem<int>(
                                    value: type.typeID,
                                    child: Text(type.typeName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedPasswordType = value;
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Lütfen şifre türü seçin';
                                  }
                                  return null;
                                },
                              ),
                            ),
                      const SizedBox(height: 16),
                      
                      // Username Field
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Kullanıcı Adı *',
                          hintText: 'Kullanıcı adını girin',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Kullanıcı adı gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Şifre *',
                          hintText: 'Şifreyi girin',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword 
                                  ? Icons.visibility 
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Şifre gerekli';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Add Button
              ElevatedButton(
                onPressed: _loading ? null : _addPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Şifre Ekle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
