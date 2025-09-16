import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../viewmodels/login_view_model.dart';
import '../theme/app_colors.dart';
import '../viewmodels/home_view_model.dart';
import '../services/storage_service.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Builder(
        builder: (context) {
          final vm = context.watch<LoginViewModel>();
          return Scaffold(
            backgroundColor: AppColors.background,
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  curve: Curves.easeOutCubic,
                  height: isKeyboardOpen ? 380 : 580,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                
                  ),
                   
                  child: SafeArea(
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 50),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(horizontal:10, vertical: isKeyboardOpen ? 20 : 50),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Image.asset(
                          height: 34,
                          'assets/arti_capital.png',
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ),
                  ),
                ),
                // İçerik kartı ve form

                SafeArea(
                  
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          height: isKeyboardOpen ? 40 : 140,
                        ),
                        ClipPath(
                      clipper: _TopWaveClipper(),
                      child: Container(
                      decoration: BoxDecoration(
                        
                        color: theme.colorScheme.surface,
                      ),      
                      child: Padding(
                         padding: const EdgeInsets.fromLTRB(24, 10, 24, 300),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [      
                           AnimatedContainer(
                             duration: const Duration(milliseconds: 150),
                             curve: Curves.easeOutCubic,
                             height: isKeyboardOpen ? 40 : 100,
                           ),
                           
                           _Card(
                             child: Form(
                             
                               key: vm.formKey,
                               child: Column(
                                 children: [
                                  Text('Giriş Yap', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
                                 SizedBox(height: 16),
                                   TextFormField(
                                     controller: vm.userController,
                                     focusNode: vm.userFocusNode,
                                     textInputAction: TextInputAction.next,
                                     onFieldSubmitted: (_) => vm.passFocusNode.requestFocus(),
                                     onEditingComplete: () => vm.passFocusNode.requestFocus(),
                                     decoration: const InputDecoration(
                                       hintText: 'Kullanıcı adı',
                                       border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                                       filled: true,
                                       prefixIcon: Icon(Icons.person_outline),
                                     ),
                                     validator: (v) => (v == null || v.trim().isEmpty) ? 'Kullanıcı adı gerekli' : null,
                                   ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: vm.passController,
                                      focusNode: vm.passFocusNode,
                                      obscureText: vm.obscure,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) async {
                                        if (vm.loading) return;
                                        FocusScope.of(context).unfocus();
                                        if (vm.formKey.currentState?.validate() ?? false) {
                                          try {
                                            final resp = await context.read<LoginViewModel>().submit();
                                            if (resp.success && resp.data != null) {
                                              // 2FA kontrolü
                                              final isAuth = resp.data!.isAuth == true;
                                              final authType = resp.data!.authType ?? 1;
                                              await StorageService.saveTwoFactorEnabled(isAuth);
                                              await StorageService.saveTwoFactorSendType(authType);

                                              if (isAuth) {
                                                if (context.mounted) {
                                                  Navigator.of(context).pushReplacementNamed('/2fa', arguments: authType);
                                                }
                                              } else {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Giriş başarılı')),
                                                  );
                                                  try {
                                                    context.read<HomeViewModel>().setCurrentIndex(0);
                                                  } catch (_) {}
                                                  Navigator.of(context).pushReplacementNamed('/home');
                                                }
                                              }
                                            } else {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(resp.errorMessage ?? 'Giriş başarısız')),
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Hata: $e')),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      onEditingComplete: () async {
                                        if (vm.loading) return;
                                        FocusScope.of(context).unfocus();
                                        if (vm.formKey.currentState?.validate() ?? false) {
                                          try {
                                            final resp = await context.read<LoginViewModel>().submit();
                                            if (resp.success && resp.data != null) {
                                              final isAuth = resp.data!.isAuth == true;
                                              final authType = resp.data!.authType ?? 1;
                                              await StorageService.saveTwoFactorEnabled(isAuth);
                                              await StorageService.saveTwoFactorSendType(authType);

                                              if (isAuth) {
                                                if (context.mounted) {
                                                  Navigator.of(context).pushReplacementNamed('/2fa', arguments: authType);
                                                }
                                              } else {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Giriş başarılı')),
                                                  );
                                                  try {
                                                    context.read<HomeViewModel>().setCurrentIndex(0);
                                                  } catch (_) {}
                                                  Navigator.of(context).pushReplacementNamed('/home');
                                                }
                                              }
                                            } else {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(resp.errorMessage ?? 'Giriş başarısız')),
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Hata: $e')),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Şifre',
                                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                                        filled: true,
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          onPressed: vm.toggleObscure,
                                          icon: Icon(vm.obscure ? Icons.visibility : Icons.visibility_off),
                                        ),
                                      ),
                                      validator: (v) => (v == null || v.isEmpty) ? 'Şifre gerekli' : null,
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Siyah büyük buton
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.onBackground,
                                  foregroundColor: AppColors.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                  elevation: 0,
                                ),
                                onPressed: vm.loading
                                    ? null
                                    : () async {
                                        try {
                                          final resp = await context.read<LoginViewModel>().submit();
                                          if (resp.success && resp.data != null) {
                                            final isAuth = resp.data!.isAuth == true;
                                            final authType = resp.data!.authType ?? 1;
                                            await StorageService.saveTwoFactorEnabled(isAuth);
                                            await StorageService.saveTwoFactorSendType(authType);

                                            if (isAuth) {
                                              if (context.mounted) {
                                                Navigator.of(context).pushReplacementNamed('/2fa', arguments: authType);
                                              }
                                            } else {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Giriş başarılı')),
                                                );
                                                try {
                                                  context.read<HomeViewModel>().setCurrentIndex(0);
                                                } catch (_) {}
                                                Navigator.of(context).pushReplacementNamed('/home');
                                              }
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(resp.errorMessage ?? 'Giriş başarısız')),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Hata: $e')),
                                            );
                                          }
                                        }
                                      },
                                child: vm.loading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Giriş Yap'),
                              ),
                            ),
                           
                          ],
                        ),
                      ),
                        ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}

class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    // Start from top-left
    path.lineTo(0, 40);
    // Create a wavy/diagonal top edge
    final double controlPointX1 = size.width * 0.25;
    final double controlPointY1 = 0;
    final double endPointX1 = size.width * 0.5;
    final double endPointY1 = 30;

    final double controlPointX2 = size.width * 0.75;
    final double controlPointY2 = 60;
    final double endPointX2 = size.width;
    final double endPointY2 = 20;

    path.quadraticBezierTo(controlPointX1, controlPointY1, endPointX1, endPointY1);
    path.quadraticBezierTo(controlPointX2, controlPointY2, endPointX2, endPointY2);

    // Right side and bottom edges
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}

// eski popup tabanlı 2FA akışı kaldırıldı; yerine ayrı sayfa kullanılmaktadır