import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_logo.dart';
import '../audit/audit_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../map/map_screen.dart';
import '../master/master_home_screen.dart';
import '../profile/profile_screen.dart';
import '../resources/resource_screens.dart';
import '../security/security_home_screen.dart';
import '../sos/sos_screen.dart';
import '../users/users_screen.dart';

/// Authenticated application shell with a dashboard home and navigation.
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
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

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: colors.cardBorder, width: 2),
        ),
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
            const SizedBox(width: 8),
            Text(
              'MJCC',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: theme.isDark ? 'Mode terang' : 'Mode gelap',
            icon: Icon(
              theme.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: colors.textSecondary,
            ),
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
          IconButton(
            tooltip: 'Profil',
            icon: Icon(Icons.person_outline, color: colors.textSecondary),
            onPressed: () => _go(context, const ProfileScreen()),
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout, color: AppColors.red600),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.gray900,
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.sidebarGradient,
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      const AppLogo(
                        size: 48,
                        background: AppColors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.name ?? 'Pengguna',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        auth.role.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),
                _navItem(
                  context,
                  Icons.dashboard_outlined,
                  Icons.dashboard,
                  'Dashboard',
                  () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
                const SizedBox(height: 8),
                _sectionLabel('DARURAT'),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.sos, color: AppColors.red100),
                  title: const Text(
                    'SOS Darurat',
                    style: TextStyle(
                      color: AppColors.red100,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  selectedTileColor: AppColors.red600.withValues(alpha: 0.22),
                  onTap: () => _go(context, const SosScreen()),
                ),
                const SizedBox(height: 4),
                _navItem(
                  context,
                  Icons.map_outlined,
                  Icons.map,
                  'Peta',
                  () => _go(context, const MapScreen()),
                ),
                const SizedBox(height: 8),
                _sectionLabel('KETERTIBAN'),
                _navItem(
                  context,
                  Icons.shield_outlined,
                  Icons.shield,
                  'Keamanan & Ketertiban',
                  () => _go(context, const SecurityHomeScreen()),
                ),
                const SizedBox(height: 8),
                _sectionLabel('PENDIDIKAN'),
                _navItem(
                  context,
                  Icons.school_outlined,
                  Icons.school,
                  'Sekolah',
                  () => _go(context, const SchoolScreen()),
                ),
                const SizedBox(height: 8),
                _sectionLabel('KESEHATAN'),
                _navItem(
                  context,
                  Icons.local_hospital_outlined,
                  Icons.local_hospital,
                  'Fasilitas Kesehatan',
                  () => _go(context, const HealthFacilityScreen()),
                ),
                const SizedBox(height: 8),
                _sectionLabel('MASTER DATA'),
                _navItem(
                  context,
                  Icons.account_tree_outlined,
                  Icons.account_tree,
                  'Kecamatan & Subjek',
                  () => _go(context, const MasterHomeScreen()),
                ),
                if (auth.isAdmin) ...[
                  const SizedBox(height: 8),
                  _sectionLabel('ADMINISTRASI'),
                  _navItem(
                    context,
                    Icons.people_outline,
                    Icons.people,
                    'Pengguna',
                    () => _go(context, const UsersScreen()),
                  ),
                  _navItem(
                    context,
                    Icons.receipt_long_outlined,
                    Icons.receipt_long,
                    'Audit Log',
                    () => _go(context, const AuditScreen()),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                _navItem(
                  context,
                  Icons.logout,
                  Icons.logout,
                  'Keluar',
                  () => _confirmLogout(context),
                  danger: true,
                ),
              ],
            ),
          ),
        ),
      ),
      body: const DashboardScreen(),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: AppColors.emerald400,
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    IconData activeIcon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        danger ? Icons.logout : icon,
        color: danger ? AppColors.red100 : Colors.white,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: danger ? AppColors.red100 : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selectedTileColor: Colors.white12,
      onTap: onTap,
    );
  }
}
