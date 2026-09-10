import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/theme_provider.dart';

/// Standard modern header for the app shell: compact with logo + title on the
/// left, theme toggle and optional notification bell on the right.
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ModernAppBar({
    super.key,
    required this.title,
    this.onMenu,
    this.unreadCount = 0,
    this.onNotifications,
    this.onProfile,
  });

  final String title;
  final VoidCallback? onMenu;
  final int unreadCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final colors = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: onMenu != null
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenu,
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logo.png',
              width: 26,
              height: 26,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const Icon(
                Icons.terrain,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'MJCC',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 1,
            height: 18,
            color: colors.outlineVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (onNotifications != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifikasi',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: onNotifications,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.red600,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        IconButton(
          tooltip: theme.isDark ? 'Mode terang' : 'Mode gelap',
          icon: Icon(
            theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
          onPressed: () => context.read<ThemeProvider>().toggle(),
        ),
        if (onProfile != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Profil',
              icon: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              onPressed: onProfile,
            ),
          ),
      ],
    );
  }
}
