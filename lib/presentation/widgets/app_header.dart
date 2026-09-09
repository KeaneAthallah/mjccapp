import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// Section header with a page title and supporting text, mirroring the
/// website's `x-page-title` component. Optionally accepts [actions] on the
/// right and an explicit [leading] widget.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
            ],
          ),
        ),
        ?actions,
      ],
    );
  }
}
