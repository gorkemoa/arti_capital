import 'package:flutter/material.dart';
import '../models/user_request_models.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _againCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _againCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final token = StorageService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oturum bilgisi bulunamadı')),
      );
      return;
    }
    setState(() { _submitting = true; });
    final req = UpdatePasswordRequest(
      userToken: token,
      currentPassword: _currentCtrl.text.trim(),
      password: _newCtrl.text.trim(),
      passwordAgain: _againCtrl.text.trim(),
    );
    final resp = await UserService().updatePassword(req);
    if (!mounted) return;
    setState(() { _submitting = false; });

    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.message ?? 'Şifre başarıyla güncellendi.')),
      );
      Navigator.of(context).pop();
    } else {
      final msg = resp.errorMessage ?? 'Şifre güncellenemedi';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifreyi Değiştir'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Şifrenizi Güncelleyin',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Yeni şifre en az 8 karakter olmalı ve harf ile rakam içermelidir.',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _currentCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Mevcut Şifre',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu alan' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _newCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Yeni Şifre',
                                prefixIcon: const Icon(Icons.password_outlined),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu alan' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _againCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Yeni Şifre (Tekrar)',
                                prefixIcon: const Icon(Icons.repeat),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Zorunlu alan';
                                if (v != _newCtrl.text) return 'Şifreler eşleşmiyor';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: FilledButton(
                                onPressed: _submitting ? null : _submit,
                                child: _submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Güncelle'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


