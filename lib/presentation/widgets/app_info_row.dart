import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// A label/value pair used on detail screens and map info sheets.
///
/// Renders a muted fixed-width label with a wrapped value, matching the map
/// bottom-sheet style but reusable across all detail pages.
class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.valueWidget,
  });

  final String label;
  final String? value;
  final IconData? icon;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final resolved = valueWidget ??
        (value == null || value!.isEmpty
            ? Text('-', style: TextStyle(color: colors.textMuted, fontSize: 13))
            : Text(value!, style: TextStyle(color: colors.textPrimary, fontSize: 13, height: 1.4)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: colors.textMuted),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: resolved),
        ],
      ),
    );
  }
}