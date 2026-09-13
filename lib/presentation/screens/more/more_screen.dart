import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/sector_dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_logo.dart';
import '../audit/audit_screen.dart';
import '../data/data_hub_screen.dart';
import '../map/map_screen.dart';
import '../master/master_home_screen.dart';
import '../profile/profile_screen.dart';
import '../sector/sector_dashboard_screen.dart';
import '../users/users_screen.dart';

/// "Lainnya" page: the mobile home for everything that does not belong on the
/// bottom navigation bar — sector dashboards, public data, master data and
/// administration.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _go(BuildContext context, Widget screen, {bool replace = false}) {
    if (replace) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => screen),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _ProfileBanner(
            name: auth.user?.name ?? 'Pengguna',
            email: auth.user?.email ?? '',
            onTap: () => _go(context, const ProfileScreen()),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _Section(
            title: 'Layanan Utama',
            icon: Icons.bolt_outlined,
            children: [
              _Tile(
                icon: Icons.map_outlined,
                color: AppColors.primary,
                label: 'Peta Gabungan',
                subtitle: 'Semua sektor dalam satu peta',
                onTap: () => _go(context, const MapScreen()),
              ),
              _Tile(
                icon: Icons.dataset_outlined,
                color: AppColors.dataPendidikan,
                label: 'Data Publik',
                subtitle: 'Statistik terbuka semua sektor',
                onTap: () => _go(context, const DataHubScreen()),
              ),
            ],
          ),
          _Section(
            title: 'Dashboard Sektor',
            icon: Icons.dashboard_outlined,
            children: [
              _Tile(
                icon: Icons.school_outlined,
                color: AppColors.dataPendidikan,
                label: 'Dashboard Pendidikan',
                subtitle: 'Siswa, guru & sarana',
                onTap: () => _go(
                  context,
                  const SectorDashboardScreen(kind: SectorKind.education),
                ),
              ),
              _Tile(
                icon: Icons.security_outlined,
                color: AppColors.dataKeamanan,
                label: 'Dashboard Ketertiban',
                subtitle: 'Polsek, kamling, pasar',
                onTap: () => _go(
                  context,
                  const SectorDashboardScreen(kind: SectorKind.security),
                ),
              ),
              _Tile(
                icon: Icons.local_hospital_outlined,
                color: AppColors.dataKesehatan,
                label: 'Dashboard Kesehatan',
                subtitle: 'Fasilitas & tenaga kesehatan',
                onTap: () => _go(
                  context,
                  const SectorDashboardScreen(kind: SectorKind.health),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Pengelolaan',
            icon: Icons.settings_outlined,
            children: [
              _Tile(
                icon: Icons.account_tree_outlined,
                color: AppColors.warning,
                label: 'Master Data',
                subtitle: 'Kecamatan, kelurahan & subjek',
                onTap: () => _go(context, const MasterHomeScreen()),
              ),
              if (auth.isAdmin) ...[
                _Tile(
                  icon: Icons.people_outline,
                  color: AppColors.info,
                  label: 'Manajemen Pengguna',
                  subtitle: 'Aktivasi akun & peran',
                  onTap: () => _go(context, const UsersScreen()),
                ),
                _Tile(
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.dataKeamanan,
                  label: 'Audit Log',
                  subtitle: 'Jejak aktivitas sistem',
                  onTap: () => _go(context, const AuditScreen()),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _LogoutButton(),
        ],
      ),
    );
  }
}

/// Compact user/profile banner with MJCC branding.
class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner({
    required this.name,
    required this.email,
    required this.onTap,
  });

  final String name;
  final String email;
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppThemeColors.of(context).cardBorder),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.emerald700, AppColors.emerald600, Color(0xFF0E7490)],
            ),
          ),
          child: Row(
            children: [
              const AppLogo(size: 52),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD1FAE5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'MJCC · MOROWALI JUARA',
                      style: TextStyle(
                        color: Color(0xFFA7F3D0),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = MediaQuery.sizeOf(context).width;
            final columns = width >= 840 ? 3 : (width >= 400 ? 2 : 1);
            final gap = AppSpacing.sm;
            final tileWidth =
                (constraints.maxWidth - (columns - 1) * gap) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final child in children)
                  SizedBox(width: tileWidth, child: child),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Tappable card tile used across the "Lainnya" page.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm - 3),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.red100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd - 4),
        onTap: () => _confirmLogout(context),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 18, color: AppColors.red600),
            SizedBox(width: 6),
            Text(
              'Keluar',
              style: TextStyle(
                color: AppColors.red600,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red600),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.logout();
    }
  }
}