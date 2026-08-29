import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// Button mirroring the website's `x-button` component variants.
///
/// Use [variant] for the color/intent (primary, secondary, danger, outline,
/// ghost) and [expanded] for a full-width block button.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.expanded = false,
    this.icon,
    this.loading = false,
    this.size = AppButtonSize.md,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool expanded;
  final IconData? icon;
  final bool loading;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final v = switch (variant) {
      AppButtonVariant.primary => (bg: AppColors.primary, fg: Colors.white),
      AppButtonVariant.secondary => (bg: AppColors.secondary, fg: Colors.white),
      AppButtonVariant.danger => (bg: AppColors.error, fg: Colors.white),
      AppButtonVariant.outline =>
        (bg: Colors.transparent, fg: colors.textPrimary),
      AppButtonVariant.ghost =>
        (bg: Colors.transparent, fg: colors.textSecondary),
    };

    final child = loading
        ? SizedBox(
            width: size == AppButtonSize.sm ? 16 : 18,
            height: size == AppButtonSize.sm ? 16 : 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: v.fg,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: size == AppButtonSize.sm ? 12 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );

    final content = expanded
        ? SizedBox(width: double.infinity, child: Center(child: child))
        : child;

    final padding = switch (size) {
      AppButtonSize.sm => const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 8,
        ),
      AppButtonSize.md => const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
    };

    if (variant == AppButtonVariant.outline ||
        variant == AppButtonVariant.ghost) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: v.fg,
          side: BorderSide(color: colors.inputBorder),
          backgroundColor: variant == AppButtonVariant.ghost
              ? colors.surfaceAlt
              : colors.surface,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
        child: content,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: v.bg,
        foregroundColor: v.fg,
        disabledBackgroundColor: v.bg.withValues(alpha: 0.5),
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
      child: content,
    );
  }
}

enum AppButtonVariant { primary, secondary, danger, outline, ghost }

enum AppButtonSize { sm, md }
