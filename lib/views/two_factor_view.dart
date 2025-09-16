import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_view_model.dart';

class TwoFactorView extends StatefulWidget {
  const TwoFactorView({super.key, this.sendType});
  final int? sendType; // 1 - SMS, 2 - E-Posta

  @override
  State<TwoFactorView> createState() => _TwoFactorViewState();
}

class _TwoFactorViewState extends State<TwoFactorView> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _sending = false;
  bool _verifying = false;
  String? _codeToken;
  int _sendType = 1;

  @override
  void initState() {
    super.initState();
    _sendType = widget.sendType ?? StorageService.getTwoFactorSendType();
  }

  bool _routeInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeInitialized) return;
    _routeInitialized = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is int) {
      _sendType = arg;
    }
    _sendCode();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() { _sending = true; });
    try {
      final resp = await AuthService().sendAuthCode(sendType: _sendType);
      if (!mounted) return;
      if (resp.success && resp.data != null) {
        _codeToken = resp.data!.codeToken;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message ?? 'Doğrulama kodu gönderildi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message ?? resp.errorMessage ?? 'Kod gönderilemedi')),
        );
      }
    } finally {
      if (mounted) setState(() { _sending = false; });
    }
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty || _codeToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kodu giriniz')),
      );
      return;
    }
    setState(() { _verifying = true; });
    try {
      final resp = await AuthService().checkAuthCode(code: code, codeToken: _codeToken!);
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş başarılı')),
        );
        // Panel sekmesine geç
        if (mounted) {
          try {
            context.read<HomeViewModel>().setCurrentIndex(0);
          } catch (_) {}
        }
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message ?? resp.errorMessage ?? 'Kod doğrulanamadı')),
        );
      }
    } finally {
      if (mounted) setState(() { _verifying = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);
    final methodText = _sendType == 1 ? 'SMS' : 'E-Posta';

    return Scaffold(
      appBar: AppBar(
        title: const Text('İki Aşamalı Doğrulama'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Doğrulama Gerekli', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Hesabınız için 2 aşamalı doğrulama aktif. Lütfen $methodText ile gelen kodu giriniz.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'Doğrulama Kodu',
                          prefixIcon: const Icon(Icons.verified_user_outlined),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: subtleBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _sending ? null : _sendCode,
                              icon: _sending
                                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.refresh_outlined, size: 18),
                              label: const Text('Kodu Yeniden Gönder'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _verifying ? null : _verify,
                              icon: _verifying
                                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.verified_outlined, size: 18),
                              label: const Text('Doğrula'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


