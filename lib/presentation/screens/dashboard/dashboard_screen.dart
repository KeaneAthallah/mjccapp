import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/dashboard_overview.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_status_badge.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../map/map_screen.dart';
import '../resources/resource_screens.dart';
import '../security/security_home_screen.dart';

/// Main dashboard overview — a mobile-first adaptation of the Laravel
/// dashboard: welcome banner, KPI statistic cards, attention alerts,
/// rankings and per-kecamatan recap.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
      context.read<MasterDataProvider>().ensureLoaded().catchError((_) => []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final master = context.watch<MasterDataProvider>();
    final auth = context.watch<AuthProvider>();
    final overview = dashboard.overview;

    return RefreshIndicator(
      onRefresh: dashboard.load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _WelcomeBanner(name: auth.user?.name ?? 'Pengguna'),
          const SizedBox(height: AppSpacing.sectionGap),
          if (master.kecamatans != null && master.kecamatans!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
              child: DropdownButtonFormField<int>(
                initialValue: dashboard.kecamatanId ?? -1,
                decoration: const InputDecoration(
                  labelText: 'Kecamatan',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: -1,
                    child: Text('Semua Kecamatan'),
                  ),
                  for (final k in master.kecamatans!)
                    DropdownMenuItem<int>(
                      value: k.id,
                      child: Text(k.name ?? '-'),
                    ),
                ],
                onChanged: (v) => dashboard.selectKecamatan(v == -1 ? null : v),
              ),
            ),
          if (dashboard.error != null)
            AppErrorState(message: dashboard.error!, onRetry: dashboard.load),
          if (dashboard.loading && overview == null)
            const AppDashboardLoading()
          else if (overview != null) ...[
            _StatisticsGrid(overview: overview),
            const SizedBox(height: AppSpacing.xs),
            _AttentionCard(overview: overview),
            _SectionCard(
              title: 'Top Kecamatan · Sekolah',
              icon: Icons.emoji_events_outlined,
              rows: _rowsFrom(overview.topSchools),
              badgeTone: BadgeTone.green,
              rankBadge: true,
            ),
            _SectionCard(
              title: 'Top Kecamatan · Poskamling',
              icon: Icons.local_police_outlined,
              rows: _rowsFrom(overview.topPoskamling),
              badgeTone: BadgeTone.blue,
              rankBadge: true,
            ),
            _SectionCard(
              title: 'Top Kecamatan · Tenaga Kesehatan',
              icon: Icons.medical_services_outlined,
              rows: _rowsFrom(overview.topHealth),
              badgeTone: BadgeTone.teal,
              rankBadge: true,
            ),
            _RekapCard(perKecamatan: overview.perKecamatan),
          ],
        ],
      ),
    );
  }

  List<({String label, String value})> _rowsFrom(List<dynamic> list) {
    return [
      for (final item in list)
        if (item is Map)
          (
            label: item['name']?.toString() ?? '-',
            value: item['count']?.toString() ?? '0',
          ),
    ];
  }
}

/// Two-column responsive grid of KPI cards (6 on wide, 2 columns on mobile).
class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final o = overview;
    final cards = <Widget>[
      StatCard(
        label: 'Sekolah (Total)',
        value: _fmt(o.totalSchools),
        icon: Icons.school_outlined,
        color: AppColors.primary,
      ),
      StatCard(
        label: 'Siswa',
        value: _fmt(o.totalStudents),
        icon: Icons.groups_outlined,
        color: AppColors.secondary,
        footer: '${_fmt(o.totalTeachers)} Guru',
      ),
      StatCard(
        label: 'Fasilitas Kesehatan',
        value: _fmt(o.totalHealthFacilities),
        icon: Icons.local_hospital_outlined,
        color: AppColors.primary,
      ),
      StatCard(
        label: 'Tenaga Medis',
        value: _fmt(o.totalMedicalStaff),
        icon: Icons.medical_services_outlined,
        color: AppColors.secondary,
        footer: '${_fmt(o.totalDoctors)} Dokter',
      ),
      StatCard(
        label: 'Tipkamtikmas',
        value: _fmt(o.totalTipkamtikmas),
        icon: Icons.report_outlined,
        color: AppColors.error,
      ),
      StatCard(
        label: 'Poskamling & Pasar',
        value: _fmt(o.totalSecurityAssets),
        icon: Icons.storefront_outlined,
        color: AppColors.warning,
      ),
    ];

    final width = MediaQuery.sizeOf(context).width;
    // Use 4 columns only on very wide tablets.
    final columns = width >= 900 ? 4 : 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final c in cards) SizedBox(width: cardWidth, child: c),
          ],
        );
      },
    );
  }

  String _fmt(int value) {
    return Formatters.number(value);
  }
}

/// The dashboard's `Perlu Perhatian` card: a standard [AppCard] with a
/// critical/warning count in the header, severity-tinted alert items (critical
/// listed first), and a clear all-clear state.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final alerts = overview.alertsSummary;
    final criticalCount = alerts.critical.length;
    final warningCount = alerts.warning.length;
    final issues = <Map>[
      for (final a in [...alerts.critical, ...alerts.warning])
        if (a is Map) a,
    ];
    final hasIssues = issues.isNotEmpty;
    final hasCritical = criticalCount > 0;

    return AppCard(
      icon: Icons.notifications_active_outlined,
      title: 'Perlu Perhatian',
      subtitle: hasIssues ? 'Isu yang memerlukan tindakan' : 'Status sistem',
      trailing: AppStatusBadge(
        label: hasIssues
            ? '$criticalCount kritis · $warningCount peringatan'
            : 'Semua aman',
        tone: hasCritical ? BadgeTone.red : BadgeTone.amber,
        icon: hasIssues
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline,
      ),
      child: hasIssues
          ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.82,
              ),
              itemCount: issues.length,
              itemBuilder: (context, index) =>
                  _AlertItem(alert: issues[index]),
            )
          : Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: AppColors.emerald600,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Tidak ada isu yang memerlukan perhatian saat ini.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  const _AlertItem({required this.alert});

  final Map alert;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final critical = alert['severity'] == 'critical';
    final title = alert['title']?.toString() ?? '';
    final sector = alert['sector']?.toString() ?? '';
    final detail = alert['detail']?.toString() ?? '';
    final accent = critical ? AppColors.red500 : AppColors.amber500;
    final tint = critical ? AppColors.red50 : AppColors.amber50;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: critical ? AppColors.red200 : AppColors.amber100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                critical ? Icons.error_outline : Icons.warning_amber_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (sector.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: AppStatusBadge(
                label: sector,
                tone: critical ? BadgeTone.red : BadgeTone.amber,
              ),
            ),
          ],
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ranked list card with a numbered badge for the top item.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.rows,
    this.badgeTone = BadgeTone.green,
    this.rankBadge = false,
  });

  final String title;
  final IconData icon;
  final List<({String label, String value})> rows;
  final BadgeTone badgeTone;
  final bool rankBadge;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return AppCard(
      title: title,
      icon: icon,
      child: rows.isEmpty
          ? Text(
              'Belum ada data.',
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            )
          : Column(
              children: [
                for (final (i, row) in rows.indexed)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        if (rankBadge) ...[
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? AppColors.amber100
                                  : AppColors.gray100,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: i == 0
                                    ? AppColors.amber600
                                    : AppColors.gray500,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Expanded(
                          child: Text(
                            row.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        AppStatusBadge(
                          label: row.value,
                          tone: i == 0 && rankBadge
                              ? BadgeTone.amber
                              : badgeTone,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Recap of assets grouped per kecamatan.
class _RekapCard extends StatelessWidget {
  const _RekapCard({required this.perKecamatan});

  final List<dynamic> perKecamatan;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final items = <({String label, String value})>[
      for (final item in perKecamatan)
        if (item is Map)
          (
            label: item['name']?.toString() ?? '-',
            value:
                'Sekolah ${item['schools'] ?? 0} · KS ${item['health_facilities'] ?? 0} · Kamling ${item['poskamlings'] ?? 0}',
          ),
    ];
    return AppCard(
      title: 'Rekapitulasi per Kecamatan',
      icon: Icons.table_chart_outlined,
      child: items.isEmpty
          ? Text(
              'Belum ada data.',
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            )
          : Column(
              children: [
                for (final row in items)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.label,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            row.value,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Welcome banner mirroring the website: emerald→blue gradient, greeting,
/// region subtitle, and sector quick actions.
class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald700, AppColors.emerald600, AppColors.blue700],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33047857),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) =>
                      const Icon(Icons.terrain, color: AppColors.emerald600),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang, $name!',
                      style: const TextStyle(
                        color: Color(0xFFF0FDF4),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'DASHBOARD PEMANTAUAN KABUPATEN MOROWALI',
                      style: TextStyle(
                        color: Color(0xFFD1FAE5),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _ActionChip(
                icon: Icons.school_outlined,
                label: 'Pendidikan',
                onTap: () => _push(context, const SchoolScreen()),
              ),
              _ActionChip(
                icon: Icons.shield_outlined,
                label: 'Ketertiban',
                onTap: () => _push(context, const SecurityHomeScreen()),
              ),
              _ActionChip(
                icon: Icons.local_hospital_outlined,
                label: 'Kesehatan',
                onTap: () => _push(
                  context,
                  const HealthFacilityScreen(),
                ),
              ),
              _ActionChip(
                icon: Icons.map_outlined,
                label: 'Peta',
                onTap: () => _push(context, const MapScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
