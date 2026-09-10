import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/modern_app_bar.dart';
import '../audit/audit_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../data/data_hub_screen.dart';
import '../map/map_screen.dart';
import '../master/master_home_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../resources/resource_screens.dart';
import '../security/security_home_screen.dart';
import '../sos/sos_screen.dart';
import '../users/users_screen.dart';

/// Authenticated application shell with a modern Material 3 bottom navigation.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;
  NotificationProvider? _notifications;

  static const _titles = ['Beranda', 'Peta', 'Data', 'SOS', 'Notifikasi'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifications = context.read<NotificationProvider>();
      _startNotificationWiring();
    });
  }

  @override
  void dispose() {
    _notifications?.stopPolling();
    super.dispose();
  }

  Future<void> _startNotificationWiring() async {
    final provider = _notifications;
    if (provider == null) return;
    await NotificationService.instance.requestNotificationsPermission();
    await provider.load(silent: true);
    provider.startPolling();
  }

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
    final auth = context.watch<AuthProvider>();
    final notif = context.watch<NotificationProvider>();

    final body = IndexedStack(
      index: _index,
      children: const [
        DashboardScreen(),
        MapScreen(),
        DataHubScreen(),
        SosScreen(),
        NotificationScreen(),
      ],
    );

    return Scaffold(
      appBar: ModernAppBar(
        title: _titles[_index],
        onMenu: null,
        unreadCount: notif.unreadCount,
        onNotifications: _index == 4
            ? null
            : () => setState(() => _index = 4),
        onProfile: () => _go(context, const ProfileScreen()),
      ),
      drawer: _buildDrawer(context, auth),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Beranda',
            tooltip: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Peta',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined, color: AppColors.dataPendidikan),
            selectedIcon: Icon(Icons.school_rounded, color: AppColors.dataPendidikan),
            label: 'Data',
            tooltip: 'Data Publik',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.emergency_outlined,
              color: AppColors.red600,
            ),
            selectedIcon: Icon(
              Icons.emergency_rounded,
              color: AppColors.red600,
            ),
            label: 'SOS',
          ),
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (notif.unreadCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.red600,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        notif.unreadCount > 9
                            ? '9+'
                            : '${notif.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            selectedIcon: const Icon(Icons.notifications_rounded),
            label: 'Notifikasi',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
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
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
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
                      if (auth.user?.isResponder ?? false)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.red500.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'PETUGAS · ${auth.user!.responderType!.label.toUpperCase()}',
                            style: const TextStyle(
                              color: AppColors.red100,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 8),
              _navItem(
                context,
                Icons.dashboard_outlined,
                'Dashboard',
                () {
                  Navigator.of(context).pop();
                  setState(() => _index = 0);
                },
              ),
              const SizedBox(height: 8),
              _sectionLabel('PENDIDIKAN'),
              _navItem(
                context,
                Icons.school_outlined,
                'Sekolah',
                () => _go(context, const SchoolScreen()),
              ),
              const SizedBox(height: 8),
              _sectionLabel('KETERTIBAN'),
              _navItem(
                context,
                Icons.shield_outlined,
                'Keamanan & Ketertiban',
                () => _go(context, const SecurityHomeScreen()),
              ),
              const SizedBox(height: 8),
              _sectionLabel('KESEHATAN'),
              _navItem(
                context,
                Icons.local_hospital_outlined,
                'Fasilitas Kesehatan',
                () => _go(context, const HealthFacilityScreen()),
              ),
              const SizedBox(height: 8),
              _sectionLabel('MASTER DATA'),
              _navItem(
                context,
                Icons.account_tree_outlined,
                'Kecamatan & Subjek',
                () => _go(context, const MasterHomeScreen()),
              ),
              if (auth.isAdmin) ...[
                const SizedBox(height: 8),
                _sectionLabel('ADMINISTRASI'),
                _navItem(
                  context,
                  Icons.people_outline,
                  'Pengguna',
                  () => _go(context, const UsersScreen()),
                ),
                _navItem(
                  context,
                  Icons.receipt_long_outlined,
                  'Audit Log',
                  () => _go(context, const AuditScreen()),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              _navItem(
                context,
                Icons.logout,
                'Keluar',
                () => _confirmLogout(context),
                danger: true,
              ),
            ],
          ),
        ),
      ),
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
