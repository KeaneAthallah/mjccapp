import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Section heading used to separate dashboard blocks: an optional icon, an
/// extrabold title and an optional trailing badge/action on the right.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.count,
    this.iconColor,
  });

  final String title;
  final Widget? trailing;

  /// Optional count label shown as a pill on the right.
  final int? count;

  /// Optional leading icon.
  final IconData? icon;

  /// Icon color (defaults to the brand primary).
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ?trailing,
      ],
    );
  }
}
