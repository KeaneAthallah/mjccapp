import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// KPI card mirroring the website's `stat-card` component:
/// white `rounded-2xl`, 4px left accent border, tinted icon badge,
/// `26px` extrabold value and an uppercase label.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.iconBackground,
    this.footer,
  });

  final String label;
  final String value;
  final IconData icon;

  /// Border-left accent color (map `green`/`blue`/`red`/`amber`).
  final Color color;

  /// Tinted badge background; defaults to `color` at 10% opacity overlay.
  final Color? iconBackground;

  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final bg = iconBackground ?? color.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 4),
            Text(
              footer!,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
