import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'app_status_badge.dart';

/// Consistent list row for a Data Publik entity: tinted icon block, name +
/// optional subtitle, optional status badge and chevron.
class DataEntityTile extends StatelessWidget {
  const DataEntityTile({
    super.key,
    required this.name,
    this.subtitle,
    this.icon,
    this.color = AppColors.primary,
    this.status,
    this.trailing,
    this.onTap,
  });

  final String name;
  final String? subtitle;
  final IconData? icon;
  final Color color;
  final String? status;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final content = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm - 2),
          ),
          child: Icon(icon ?? Icons.place_outlined, color: color, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
            ],
          ),
        ),
        if (status != null && status!.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          AppStatusBadge(label: status!, tone: AppStatusBadge.toneFrom(status)),
        ],
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.xs),
          trailing!,
        ],
        if (onTap != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.chevron_right, size: 20, color: colors.textMuted),
        ],
      ],
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      onTap: onTap,
      child: content,
    );
  }
}