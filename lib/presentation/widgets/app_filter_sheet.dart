import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// A single-select option shown inside the filter sheet.
class FilterOption<T> {
  const FilterOption(this.value, this.label, {this.icon, this.color});

  final T value;
  final String label;
  final IconData? icon;
  final Color? color;
}

/// Modal bottom sheet that lets the user pick one option for a filter field.
///
/// Returns the selected `FilterOption` (or `FilterOption(null, …)` for
/// "Semua"). Prefer this over hand-rolled dialogs so every list screen uses
/// the same picking UX.
Future<FilterOption<T>?> showFilterSheet<T>({
  required BuildContext context,
  required String title,
  required List<FilterOption<T>> options,
  required T current,
  IconData icon = Icons.tune,
}) {
  return showModalBottomSheet<FilterOption<T>>(
    context: context,
    backgroundColor: AppThemeColors.of(context).surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final option in options)
                      _optionTile(ctx, option, option.value == current),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _optionTile<T>(BuildContext context, FilterOption<T> option, bool selected) {
  final colors = AppThemeColors.of(context);
  return InkWell(
    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
    onTap: () => Navigator.of(context).pop(option),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 10),
      child: Row(
        children: [
          if (option.icon != null) ...[
            Icon(option.icon, size: 18, color: option.color ?? colors.textMuted),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              option.label,
              style: TextStyle(
                color: selected ? AppColors.primary : colors.textPrimary,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
        ],
      ),
    ),
  );
}