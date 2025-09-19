import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(BuildContext context) {
    // final base = Theme.of(context).textTheme;
    
    // Poppins ailesi, başlık 15, gövde 12
    return TextTheme(
      titleMedium: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        // ignore: deprecated_member_use
        color: AppColors.onSurface.withOpacity(0.8),
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
      ),
    ).apply(
      displayColor: AppColors.onSurface,
      bodyColor: AppColors.onSurface,
    );
  }
}


