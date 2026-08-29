import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Pill badge mirroring the website's `x-badge` component:
/// `rounded-full`, tinted background, 11px bold text.
///
/// Provide either [color] (concrete brand color) or a [tone] for a semantic
/// status. When [tone] is given the background is the tone at low opacity.
enum BadgeTone { green, blue, red, amber, gray, teal, indigo }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.gray,
    this.color,
    this.icon,
  });

  final String label;
  final BadgeTone tone;
  final Color? color;
  final IconData? icon;

  Color get _toneColor => switch (tone) {
        BadgeTone.green => AppColors.emerald600,
        BadgeTone.blue => AppColors.blue600,
        BadgeTone.red => AppColors.red600,
        BadgeTone.amber => AppColors.amber600,
        BadgeTone.gray => AppColors.gray600,
        BadgeTone.teal => AppColors.teal700,
        BadgeTone.indigo => const Color(0xFF4F46E5),
      };

  static BadgeTone toneFrom(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s.contains('aktif') || s.contains('active') || s == 'selesai' ||
        s == 'completed' || s == 'approved' || s == 'sukses') {
      return BadgeTone.green;
    }
    if (s.contains('tidak aktif') || s == 'inactive' || s == 'rejected' ||
        s == 'gagal' || s == 'nonaktif') {
      return BadgeTone.red;
    }
    if (s.contains('pending') || s.contains('proses') || s == 'draft') {
      return BadgeTone.amber;
    }
    if (s.contains('perawatan')) return BadgeTone.teal;
    return BadgeTone.gray;
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? _toneColor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
