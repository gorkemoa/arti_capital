import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

import '../viewmodels/profile_view_model.dart';

class ProfileEditView extends StatefulWidget {
  const ProfileEditView({super.key});

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  late final TextEditingController fullnameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController birthdayCtrl;
  late final TextEditingController addressCtrl;
  late final TextEditingController phoneCtrl;
  String? _genderValue;
  String? _profilePhotoDataUrl;
  Uint8List? _pickedImageBytes;

  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

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
                          if (items.isNotEmpty) onSelected(items[currentIndex]);
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
                  onSelectedItemChanged: (index) { currentIndex = index; },
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
    IconData? leadingIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 20, color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  (value == null || value.isEmpty) ? placeholder : value,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: (value == null || value.isEmpty)
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
              Icon(CupertinoIcons.chevron_down, size: 18, color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final vm = context.read<ProfileViewModel>();
    final user = vm.user!;
    fullnameCtrl = TextEditingController(text: user.userFullname);
    emailCtrl = TextEditingController(text: user.userEmail);
    birthdayCtrl = TextEditingController();
    addressCtrl = TextEditingController();
    phoneCtrl = TextEditingController(text: user.userPhone);
    _genderValue = (user.userGender == '2') ? '2' : '1';
    // Başlangıçta mevcut profil fotoğrafı varsa (URL veya data URL), gönderimde boş bırakılabilir
  }

  @override
  void dispose() {
    fullnameCtrl.dispose();
    emailCtrl.dispose();
    birthdayCtrl.dispose();
    addressCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final vm = context.read<ProfileViewModel>();
    final resp = await vm.updateUserProfile(
      userFullname: fullnameCtrl.text.trim(),
      userEmail: emailCtrl.text.trim(),
      userBirthday: birthdayCtrl.text.trim(),
      userAddress: addressCtrl.text.trim(),
      userPhone: phoneCtrl.text.trim(),
      userGender: _genderValue ?? '1',
      profilePhoto: _profilePhotoDataUrl ?? '',
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil güncellendi')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.errorMessage ?? 'Güncelleme başarısız')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;
      // MIME türünü uzantıdan tahmin et
      final name = (file.name).toLowerCase();
      String mime = 'image/jpeg';
      if (name.endsWith('.png')) mime = 'image/png';
      if (name.endsWith('.jpg') || name.endsWith('.jpeg')) mime = 'image/jpeg';
      if (name.endsWith('.gif')) mime = 'image/gif';
      final b64 = base64Encode(bytes);
      setState(() {
        _pickedImageBytes = bytes;
        _profilePhotoDataUrl = 'data:$mime;base64,$b64';
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtleBorder = colorScheme.outline.withOpacity(0.12);
    final vm = context.watch<ProfileViewModel>();
    final existingPhoto = vm.user?.profilePhoto ?? '';

    ImageProvider? avatarImage;
    if (_pickedImageBytes != null) {
      avatarImage = MemoryImage(_pickedImageBytes!);
    } else if (existingPhoto.isNotEmpty) {
      if (existingPhoto.startsWith('data:')) {
        final commaIndex = existingPhoto.indexOf(',');
        if (commaIndex != -1) {
          final b64 = existingPhoto.substring(commaIndex + 1);
          try {
            final bytes = base64Decode(b64);
            avatarImage = MemoryImage(bytes);
          } catch (_) {}
        }
      } else if (existingPhoto.startsWith('http')) {
        avatarImage = NetworkImage(existingPhoto);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: colorScheme.surface,
                        backgroundImage: avatarImage,
                        child: (avatarImage == null)
                            ? const Icon(Icons.person, size: 44)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton(
                          onPressed: _pickImage,
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.all(6),
                          ),
                          icon: const Icon(Icons.edit, size: 14),
                          tooltip: 'Profil Fotoğrafını Değiştir',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Profil Bilgileri', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _Section(title: 'Hesap'),
            _InputCard(
              subtleBorder: subtleBorder,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: TextFormField(
                    controller: fullnameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Ad Soyad',
                        prefixIcon: const Icon(Icons.account_circle_outlined),
                        isDense: true,
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
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: const Icon(Icons.alternate_email_outlined),
                        isDense: true,
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
                      ),
                    ),
                  ),
                  // Doğum tarihi - Cupertino picker
                  _buildCupertinoField(
                    placeholder: 'Doğum Tarihi (GG.AA.YYYY)',
                    value: birthdayCtrl.text.trim().isEmpty ? null : birthdayCtrl.text.trim(),
                    leadingIcon: Icons.event_outlined,
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      final now = DateTime.now();
                      DateTime initial = DateTime(now.year - 30, now.month, now.day);
                      final text = birthdayCtrl.text.trim();
                      if (RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(text)) {
                        final parts = text.split('.');
                        final dd = int.tryParse(parts[0]);
                        final mm = int.tryParse(parts[1]);
                        final yyyy = int.tryParse(parts[2]);
                        if (dd != null && mm != null && yyyy != null) {
                          final candidate = DateTime(yyyy, mm, dd);
                          if (!candidate.isAfter(now) && yyyy >= 1900) initial = candidate;
                        }
                      }
                      DateTime temp = initial;
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
                                      Text('Doğum Tarihi', style: Theme.of(context).textTheme.titleMedium),
                                      CupertinoButton(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: const Text('Bitti'),
                                        onPressed: () {
                                          final dd = temp.day.toString().padLeft(2, '0');
                                          final mm = temp.month.toString().padLeft(2, '0');
                                          final yyyy = temp.year.toString();
                                          setState(() { birthdayCtrl.text = '$dd.$mm.$yyyy'; });
                                          Navigator.of(ctx).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime: initial,
                                    minimumDate: DateTime(1900, 1, 1),
                                    maximumDate: DateTime(now.year, now.month, now.day),
                                    onDateTimeChanged: (d) { temp = d; },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildCupertinoField(
                    placeholder: 'Cinsiyet',
                    value: _genderValue == null
                        ? null
                        : (_genderValue == '2' ? 'Kadın' : 'Erkek'),
                    leadingIcon: Icons.wc_outlined,
                    onTap: () async {
                      final items = const [
                        ('1', 'Erkek'),
                        ('2', 'Kadın'),
                      ];
                      final currentIndex = _genderValue == null
                          ? 0
                          : items.indexWhere((e) => e.$1 == _genderValue).clamp(0, items.length - 1);
                      await _showCupertinoSelector<(String, String)>(
                        items: items,
                        initialIndex: currentIndex,
                        labelBuilder: (t) => t.$2,
                        title: 'Cinsiyet Seç',
                        onSelected: (t) { setState(() { _genderValue = t.$1; }); },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            _Section(title: 'İletişim'),
            _InputCard(
              subtleBorder: subtleBorder,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Telefon',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        isDense: true,
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
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: TextFormField(
                    controller: addressCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Adres',
                        prefixIcon: const Icon(Icons.home_outlined),
                        isDense: true,
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
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
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
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _submitting
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
                        'Kaydet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
}


class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.child, required this.subtleBorder});
  final Widget child;
  final Color subtleBorder;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subtleBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: child,
    );
  }
}

// ignore: unused_element
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
    required this.validator,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          isDense: true,
        ),
      ),
    );
  }
}


