import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String? _profilePhotoDataUrl; // data:image/...;base64,xxxx
  Uint8List? _pickedImageBytes;

  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

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
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.surface),
        title: const Text('Profili Düzenle'),
       
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
                  _InputField(
                    controller: fullnameCtrl,
                    label: 'Ad Soyad',
                    icon: Icons.account_circle_outlined,
                  ),
                  _InputField(
                    controller: emailCtrl,
                    label: 'E-posta',
                    icon: Icons.alternate_email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _InputField(
                    controller: birthdayCtrl,
                    label: 'Doğum Tarihi (GG.AA.YYYY)',
                    icon: Icons.event_outlined,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: DropdownButtonFormField<String>(
                      value: _genderValue,
                      decoration: const InputDecoration(
                        labelText: 'Cinsiyet',
                        prefixIcon: Icon(Icons.wc_outlined),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('Erkek')),
                        DropdownMenuItem(value: '2', child: Text('Kadın')),
                      ],
                      onChanged: (v) => setState(() => _genderValue = v),
                    ),
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
                  _InputField(
                    controller: phoneCtrl,
                    label: 'Telefon',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  _InputField(
                    controller: addressCtrl,
                    label: 'Adres',
                    icon: Icons.home_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_submitting ? 'Kaydediliyor...' : 'Kaydet'),
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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
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


