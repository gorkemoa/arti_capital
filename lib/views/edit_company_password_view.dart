import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/company_models.dart';
import '../services/company_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class EditCompanyPasswordView extends StatefulWidget {
  const EditCompanyPasswordView({
    super.key,
    required this.compId,
    required this.password,
  });
  
  final int compId;
  final CompanyPasswordItem password;

  @override
  State<EditCompanyPasswordView> createState() => _EditCompanyPasswordViewState();
}

class _EditCompanyPasswordViewState extends State<EditCompanyPasswordView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  
  bool _loading = false;
  bool _typesLoading = true;
  bool _obscurePassword = true;
  int? _selectedPasswordType;
  List<PasswordTypeItem> _passwordTypes = [];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.password.passwordUsername);
    _passwordController = TextEditingController(text: widget.password.passwordPassword);
    _selectedPasswordType = widget.password.passwordTypeID;
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

  Future<void> _updatePassword() async {
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

      final request = UpdateCompanyPasswordRequest(
        userToken: token,
        compID: widget.compId,
        passID: widget.password.passwordID,
        passType: _selectedPasswordType!,
        passUsername: _usernameController.text.trim(),
        passPassword: _passwordController.text.trim(),
      );

      final response = await const CompanyService().updateCompanyPassword(request);

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
          content: Text('Şifre güncellenirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  Future<void> _showPasswordTypeSelector() async {
    if (_passwordTypes.isEmpty) return;

    final currentIndex = _selectedPasswordType == null
        ? 0
        : _passwordTypes.indexWhere((t) => t.typeID == _selectedPasswordType).clamp(0, _passwordTypes.length - 1);

    final FixedExtentScrollController controller = FixedExtentScrollController(initialItem: currentIndex);
    int tempIndex = currentIndex;

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
                        'Şifre Türü Seç',
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
                          if (_passwordTypes.isNotEmpty) {
                            setState(() {
                              _selectedPasswordType = _passwordTypes[tempIndex].typeID;
                            });
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
                    tempIndex = index;
                  },
                  children: _passwordTypes.map((type) {
                    return Center(child: Text(type.typeName));
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Şifre Düzenle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: _typesLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle(context, 'Şifre Bilgileri'),
                    const SizedBox(height: 16),
                    
                    // Password Type Dropdown
                    _buildCupertinoField(
                      theme: theme,
                      label: 'Şifre Türü *',
                      value: _selectedPasswordType != null
                          ? _passwordTypes.firstWhere((t) => t.typeID == _selectedPasswordType).typeName
                          : null,
                      onTap: _showPasswordTypeSelector,
                    ),
                    const SizedBox(height: 16),
                    
                    // Username Field
                    _buildTextField(
                      theme: theme,
                      controller: _usernameController,
                      label: 'Kullanıcı Adı *',
                    ),
                    const SizedBox(height: 16),
                    
                    // Password Field
                    _buildTextField(
                      theme: theme,
                      controller: _passwordController,
                      label: 'Şifre *',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword 
                              ? Icons.visibility 
                              : Icons.visibility_off,
                          color: AppColors.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ],
                ),
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
                onPressed: _loading ? null : _updatePassword,
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
                            'Güncelleniyor...',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Güncelle',
                        style: theme.textTheme.titleMedium?.copyWith(
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

  Widget _buildTextField({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      textCapitalization: obscureText ? TextCapitalization.none : TextCapitalization.sentences,
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
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
        suffixIcon: suffixIcon,
      ),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _buildCupertinoField({
    required ThemeData theme,
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                value ?? label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: value == null
                      ? AppColors.onSurface.withOpacity(0.6)
                      : AppColors.onSurface,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: AppColors.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
