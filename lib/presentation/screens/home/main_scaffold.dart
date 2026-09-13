import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/sector_dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/sos_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/modern_app_bar.dart';
import '../audit/audit_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../data/data_hub_screen.dart';
import '../map/map_screen.dart';
import '../master/master_home_screen.dart';
import '../more/more_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../sector/sector_dashboard_screen.dart';
import '../sos/sos_screen.dart';
import '../users/users_screen.dart';

/// Authenticated application shell.
///
/// Smartphones get a modern Material 3 bottom navigation bar (Beranda · Peta ·
/// SOS · Alerts · Lainnya) with SOS kept visually distinct, while tablets and
/// wide screens switch to a persistent [NavigationRail]. The full menu remains
/// available through the drawer.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with WidgetsBindingObserver {
  int _index = 0;
  NotificationProvider? _notifications;
  SosProvider? _sos;

  static const _titles = ['Beranda', 'Peta', 'SOS Darurat', 'Alerts', 'Lainnya'];
  static const _labels = ['Beranda', 'Peta', 'SOS', 'Alerts', 'Lainnya'];

  /// Width threshold where the permanent navigation rail replaces the bottom
  /// navigation bar (Material 3 guideline ~ tablet portrait/landscape).
  static const double _railBreakpoint = 840;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifications = context.read<NotificationProvider>();
      _sos = context.read<SosProvider>();
      _startNotificationWiring();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifications?.stopPolling();
    _sos?.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notif = _notifications;
    final sos = _sos;
    if (state == AppLifecycleState.resumed) {
      // Refresh from a cold server state and resume background polling.
      notif?.load(silent: true);
      notif?.startPolling();
      if (sos != null) {
        sos.refreshMyOpen(silent: true);
        if (sos.hasOpen) sos.startPolling();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // Never poll while the app is not in the foreground.
      notif?.stopPolling();
      sos?.stopPolling();
    }
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

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notif = context.watch<NotificationProvider>();
    final wide = MediaQuery.sizeOf(context).width >= _railBreakpoint;

    final body = IndexedStack(
      index: _index,
      children: [
        DashboardScreen(onOpenSos: () => _select(2)),
        const MapScreen(),
        const SosScreen(),
        const NotificationScreen(),
        const MoreScreen(),
      ],
    );

    return Scaffold(
      appBar: ModernAppBar(
        title: _titles[_index],
        onMenu: null,
        unreadCount: notif.unreadCount,
        onNotifications: _index == 3
            ? null
            : () => _select(3),
        onProfile: () => _go(context, const ProfileScreen()),
      ),
      drawer: _buildDrawer(context, auth),
      body: wide
          ? Row(
              children: [
                _buildRail(context, notif, wide),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide ? null : _buildNavBar(notif),
    );
  }

  Widget _buildNavBar(NotificationProvider notif) {
    return NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: _select,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        _destination(0, notif),
        _destination(1, notif),
        _destination(2, notif),
        _destination(3, notif),
        _destination(4, notif),
      ],
    );
  }

  NavigationDestination _destination(int i, NotificationProvider notif) {
    return NavigationDestination(
      icon: _navIcon(i, notif, selected: false),
      selectedIcon: _navIcon(i, notif, selected: true),
      label: _labels[i],
      tooltip: _titles[i],
    );
  }

  Widget _buildRail(BuildContext context, NotificationProvider notif, bool wide) {
    return NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: _select,
      labelType: NavigationRailLabelType.all,
      groupAlignment: -0.9,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            const AppLogo(size: 42),
            const SizedBox(height: 4),
            if (wide)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.emerald500,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
      destinations: [
        for (var i = 0; i < 5; i++)
          NavigationRailDestination(
            icon: _navIcon(i, notif, selected: false),
            selectedIcon: _navIcon(i, notif, selected: true),
            label: i == 2
                ? const Text(
                    'SOS',
                    style: TextStyle(
                      color: AppColors.red600,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Text(_labels[i]),
          ),
      ],
    );
  }

  Widget _navIcon(int i, NotificationProvider notif, {required bool selected}) {
    if (i == 2) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: selected ? AppColors.red600 : AppColors.red50,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.red600.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(
          selected ? Icons.emergency_rounded : Icons.emergency_outlined,
          size: 20,
          color: selected ? Colors.white : AppColors.red600,
        ),
      );
    }
    final icon = switch (i) {
      0 => selected ? Icons.home_rounded : Icons.home_outlined,
      1 => selected ? Icons.map_rounded : Icons.map_outlined,
      3 => selected
          ? Icons.notifications_active_rounded
          : Icons.notifications_active_outlined,
      _ => selected ? Icons.grid_view_rounded : Icons.grid_view_outlined,
    };
    if (i == 3 && notif.unreadCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          Positioned(
            top: -6,
            right: -10,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
              decoration: const BoxDecoration(
                color: AppColors.red600,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                notif.unreadCount > 9 ? '9+' : '${notif.unreadCount}',
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
      );
    }
    return Icon(icon);
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
                Icons.home_outlined,
                'Beranda',
                () {
                  Navigator.of(context).pop();
                  _select(0);
                },
              ),
              _navItem(
                context,
                Icons.map_outlined,
                'Peta',
                () {
                  Navigator.of(context).pop();
                  _select(1);
                },
              ),
              _navItem(
                context,
                Icons.emergency_outlined,
                'SOS / Darurat',
                () {
                  Navigator.of(context).pop();
                  _select(2);
                },
                danger: true,
              ),
              _navItem(
                context,
                Icons.notifications_active_outlined,
                'Alerts',
                () {
                  Navigator.of(context).pop();
                  _select(3);
                },
              ),
              const SizedBox(height: 8),
              _sectionLabel('DATA & SEKTOR'),
              _navItem(
                context,
                Icons.dataset_outlined,
                'Data Publik',
                () {
                  Navigator.of(context).pop();
                  _go(context, const DataHubScreen());
                },
              ),
              _navItem(
                context,
                Icons.school_outlined,
                'Pendidikan',
                () {
                  Navigator.of(context).pop();
                  _go(
                    context,
                    const SectorDashboardScreen(kind: SectorKind.education),
                  );
                },
              ),
              _navItem(
                context,
                Icons.shield_outlined,
                'Keamanan & Ketertiban',
                () {
                  Navigator.of(context).pop();
                  _go(
                    context,
                    const SectorDashboardScreen(kind: SectorKind.security),
                  );
                },
              ),
              _navItem(
                context,
                Icons.local_hospital_outlined,
                'Kesehatan',
                () {
                  Navigator.of(context).pop();
                  _go(
                    context,
                    const SectorDashboardScreen(kind: SectorKind.health),
                  );
                },
              ),
              const SizedBox(height: 8),
              _sectionLabel('PENGELOLAAN'),
              _navItem(
                context,
                Icons.account_tree_outlined,
                'Master Data',
                () {
                  Navigator.of(context).pop();
                  _go(context, const MasterHomeScreen());
                },
              ),
              if (auth.isAdmin) ...[
                _navItem(
                  context,
                  Icons.people_outline,
                  'Pengguna',
                  () {
                    Navigator.of(context).pop();
                    _go(context, const UsersScreen());
                  },
                ),
                _navItem(
                  context,
                  Icons.receipt_long_outlined,
                  'Audit Log',
                  () {
                    Navigator.of(context).pop();
                    _go(context, const AuditScreen());
                  },
                ),
              ],
              const SizedBox(height: 8),
              _sectionLabel('AKUN'),
              _navItem(
                context,
                Icons.person_outline,
                'Profil Saya',
                () {
                  Navigator.of(context).pop();
                  _go(context, const ProfileScreen());
                },
              ),
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
        icon,
        color: danger ? AppColors.red400 : Colors.white,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: danger ? AppColors.red200 : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selectedTileColor: Colors.white12,
      onTap: onTap,
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