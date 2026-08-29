import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Circular MJCC logo badge mirroring the website's logo treatment.
///
/// The website shows the logo inside a white circle (`rounded-full bg-white`).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.background,
  });

  final double size;

  /// Circle background; when null the logo is drawn on a transparent circle.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) =>
            const Icon(Icons.terrain, color: AppColors.primary),
      ),
    );
  }
}
