import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../resources/resource_screens.dart';

/// Hub screen for the security (ketertiban) sector.
class SecurityHomeScreen extends StatelessWidget {
  const SecurityHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ketertiban')),
      body: GridView.count(
        padding: const EdgeInsets.all(AppSpacing.md),
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1,
        children: [
          _Tile(
            icon: Icons.local_police_outlined,
            color: AppColors.error,
            label: 'Polsek',
            onTap: () => _go(context, const PolsekScreen()),
          ),
          _Tile(
            icon: Icons.report_outlined,
            color: AppColors.error,
            label: 'Tipkamtikmas',
            onTap: () => _go(context, const TipkamtikmasScreen()),
          ),
          _Tile(
            icon: Icons.visibility_outlined,
            color: AppColors.teal700,
            label: 'Poskamling',
            onTap: () => _go(context, const PoskamlingScreen()),
          ),
          _Tile(
            icon: Icons.storefront_outlined,
            color: AppColors.amber700,
            label: 'Pasar',
            onTap: () => _go(context, const MarketScreen()),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppThemeColors.of(context).surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppThemeColors.of(context).cardBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm + 4),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppThemeColors.of(context).textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
