import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/chart_data.dart';
import '../../../data/models/dashboard_overview.dart';
import '../../../data/models/data_sector.dart';
import '../../../data/models/public_data_overview.dart';
import '../../../data/models/sector_dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/public_data_provider.dart';
import '../../providers/sos_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_status_badge.dart';
import '../../widgets/charts/app_charts.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../data/data_hub_screen.dart';
import '../data/public_data_list_screen.dart';
import '../map/map_screen.dart';
import '../sector/sector_dashboard_screen.dart';
import '../sos/sos_create_screen.dart';

/// Main dashboard overview — a mobile-first adaptation of the Laravel
/// dashboard: welcome banner, SOS quick access, attention alerts, a compact
/// "Ringkasan Hari Ini" KPI grid, sector summaries, rankings and the
/// per-kecamatan recap.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onOpenSos});

  /// Switches the shell to the SOS tab (used by the SOS quick-access card).
  final VoidCallback? onOpenSos;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
      context.read<PublicDataProvider>().load();
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
          _SosAccessCard(onOpenSos: widget.onOpenSos),
          if (dashboard.error != null)
            AppErrorState(message: dashboard.error!, onRetry: dashboard.load),
          if (dashboard.loading && overview == null)
            const AppDashboardLoading()
          else if (overview != null) ...[
            if (overview.alertsSummary.critical.isNotEmpty ||
                overview.alertsSummary.warning.isNotEmpty)
              _AttentionCard(overview: overview),
            if (master.kecamatans != null && master.kecamatans!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
                child: DropdownButtonFormField<int>(
                  key: ValueKey(dashboard.kecamatanId),
                  initialValue: dashboard.kecamatanId ?? -1,
                  isExpanded: true,
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
                  onChanged: (v) =>
                      dashboard.selectKecamatan(v == -1 ? null : v),
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppSectionHeader(
                title: 'Ringkasan Hari Ini',
                icon: Icons.today_outlined,
              ),
            ),
            _StatisticsGrid(overview: overview),
            const SizedBox(height: AppSpacing.xs),
            const _DataPublikCard(),
            const SizedBox(height: AppSpacing.xs),
            _DashboardCharts(overview: overview),
            const SizedBox(height: AppSpacing.sm),
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

/// SOS quick access — a compact card that keeps the emergency entry point a
/// first-class part of the mobile home. When the user has an open alert it
/// switches to the live SOS status; otherwise it starts the create flow.
class _SosAccessCard extends StatelessWidget {
  const _SosAccessCard({required this.onOpenSos});

  final VoidCallback? onOpenSos;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SosProvider>();
    final colors = AppThemeColors.of(context);
    final hasOpen = provider.hasOpen;

    if (hasOpen) {
      final alert = provider.myOpen!;
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.red700, AppColors.red600],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.red600.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd - 4),
          onTap: onOpenSos,
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sos, size: 30, color: AppColors.red600),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SOS ANDA SEDANG AKTIF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${alert.categoryLabel} · ${alert.statusLabel}',
                      style: const TextStyle(
                        color: Color(0xFFFFC7C7),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      );
    }

    return AppCard(
      icon: Icons.sos,
      title: 'Bantuan Darurat',
      subtitle: 'Kirim lokasi Anda ke petugas secara instan',
      trailing: AppStatusBadge(
        label: 'Lapor',
        tone: BadgeTone.red,
        icon: Icons.emergency_outlined,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tekan tombol untuk melaporkan keadaan darurat. '
              'Koordinat GPS terkini akan dikirim ke Pusat Pengendalian.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ElevatedButton(
            onPressed: provider.locating
                ? null
                : () async {
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const SosCreateScreen(),
                      ),
                    );
                    if (created == true && context.mounted) {
                      await context.read<SosProvider>().refreshMyOpen();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red600,
              foregroundColor: Colors.white,
              elevation: 3,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            child: provider.locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sos, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'SOS',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Charts mirroring the website overview: per-sector comparison bar chart,
/// infra composition polar chart, stacked student bar chart and a workforce
/// doughnut — each with its own legend.
class _DashboardCharts extends StatelessWidget {
  const _DashboardCharts({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final comparison = MultiSeriesChart.fromJson(overview.comparison);
    final infra = SingleSeriesChart.fromJson(overview.infraComposition);
    final student = MultiSeriesChart.fromJson(overview.studentChart);
    final workforce = SingleSeriesChart.fromJson(overview.healthWorkforceChart);

    final hasData =
        comparison.labels.isNotEmpty ||
        student.labels.isNotEmpty ||
        infra.labels.isNotEmpty ||
        workforce.labels.isNotEmpty;
    if (!hasData) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppSectionHeader(
            title: 'Grafik & Statistik',
            icon: Icons.analytics_outlined,
          ),
        ),
        AppCard(
          title: 'Perbandingan antar Sektor',
          subtitle: 'Sekolah · Tipkamtikmas · Faskes per kecamatan',
          icon: Icons.bar_chart,
          child: Column(
            children: [
              AppCharts.groupedBars(context: context, chart: comparison),
              const SizedBox(height: AppSpacing.sm),
              ChartLegend(
                items: [
                  for (final ds in comparison.datasets)
                    (label: ds.label, color: ds.color),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          title: 'Komposisi Infrastruktur',
          subtitle: 'Pendidikan · Ketertiban · Kesehatan',
          icon: Icons.donut_large_outlined,
          child: Column(
            children: [
              AppCharts.polar(context: context, chart: infra),
              const SizedBox(height: AppSpacing.sm),
              ChartLegend(
                items: [
                  for (final (i, label) in infra.labels.indexed)
                    (
                      label: label,
                      color: ChartPalette.pie[i % ChartPalette.pie.length],
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          title: 'Siswa per Kecamatan',
          subtitle: 'Laki-laki & Perempuan',
          icon: Icons.bar_chart,
          child: Column(
            children: [
              AppCharts.groupedBars(
                context: context,
                chart: student,
                stacked: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              ChartLegend(
                items: [
                  for (final ds in student.datasets)
                    (label: ds.label, color: ds.color),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          title: 'Tenaga Kesehatan',
          subtitle: 'Dokter · Perawat · Bidan',
          icon: Icons.medical_services_outlined,
          child: Column(
            children: [
              AppCharts.doughnut(context: context, chart: workforce),
              const SizedBox(height: AppSpacing.sm),
              ChartLegend(
                items: [
                  for (final (i, label) in workforce.labels.indexed)
                    (
                      label: label,
                      color: ChartPalette.pie[i % ChartPalette.pie.length],
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
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

/// Data Publik quick-access card linking to the hub; taps into the Data tab's
/// screens via the supported sectors.
class _DataPublikCard extends StatelessWidget {
  const _DataPublikCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicDataProvider>();
    final overview = provider.overview;

    return AppCard(
      icon: Icons.dataset_outlined,
      title: 'Data Publik',
      subtitle: 'Statistik terbaru dari semua sektor',
      trailing: IconButton(
        tooltip: 'Lihat semua data',
        icon: const Icon(Icons.arrow_forward, size: 18),
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DataHubScreen())),
      ),
      child: provider.loading && overview == null
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : overview == null
          ? Text(
              'Belum ada data.',
              style: TextStyle(
                color: AppThemeColors.of(context).textMuted,
                fontSize: 13,
              ),
            )
          : _sectorTiles(context, overview),
    );
  }

  Widget _sectorTiles(BuildContext context, PublicDataOverview overview) {
    final entries = <(DataSector, int, String)>[
      (DataSector.pendidikan, overview.pendidikan.sekolah, 'sekolah'),
      (DataSector.kesehatan, overview.kesehatan.faskes, 'faskes'),
      (DataSector.ketertiban, overview.ketertiban.total, 'aspek keamanan'),
      (DataSector.fasilitas, overview.fasilitas.pasar, 'pasar'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (sector, count, noun) in entries)
              _sectorTile(
                context,
                sector: sector,
                count: count,
                noun: noun,
                width: tileWidth,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicDataListScreen(sector: sector),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sectorTile(
    BuildContext context, {
    required DataSector sector,
    required int count,
    required String noun,
    required double width,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: sector.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(sector.icon, size: 18, color: sector.color),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        sector.label,
                        style: TextStyle(
                          color: AppThemeColors.of(context).textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  Formatters.number(count),
                  style: TextStyle(
                    color: sector.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  noun,
                  style: TextStyle(
                    color: AppThemeColors.of(context).textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The dashboard's `Perlu Perhatian` card: a standard [AppCard] with a
/// critical/warning count in the header, severity-tinted alert items (critical
/// listed first), and a clear all-clear state. Only the first [maxVisible]
/// items are shown at once; a "Lihat Semua" toggle reveals the rest so the
/// dashboard never floods the whole screen with issue cards.
class _AttentionCard extends StatefulWidget {
  const _AttentionCard({required this.overview});

  final DashboardOverview overview;

  @override
  State<_AttentionCard> createState() => _AttentionCardState();
}

class _AttentionCardState extends State<_AttentionCard> {
  static const int maxVisible = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final alerts = widget.overview.alertsSummary;
    final criticalCount = alerts.critical.length;
    final warningCount = alerts.warning.length;
    final issues = <Map>[
      for (final a in [...alerts.critical, ...alerts.warning])
        if (a is Map) a,
    ];
    final hasIssues = issues.isNotEmpty;
    final hasCritical = criticalCount > 0;
    final visible = _expanded ? issues : issues.take(maxVisible).toList();
    final hasMore = issues.length > maxVisible;

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
          ? Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) =>
                      _AlertItem(alert: visible[index]),
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: TextButton.icon(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                      ),
                      label: Text(
                        _expanded ? 'Tutup' : 'Lihat Semua (${issues.length})',
                      ),
                    ),
                  ),
              ],
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
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
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
    final tint = critical
        ? AppColors.red500.withValues(alpha: 0.12)
        : AppColors.amber500.withValues(alpha: 0.12);
    final border = critical
        ? AppColors.red500.withValues(alpha: 0.35)
        : AppColors.amber500.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: border),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
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
          colors: [
            AppColors.emerald700,
            AppColors.emerald600,
            AppColors.blue700,
          ],
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
                onTap: () => _push(
                  context,
                  const SectorDashboardScreen(kind: SectorKind.education),
                ),
              ),
              _ActionChip(
                icon: Icons.shield_outlined,
                label: 'Ketertiban',
                onTap: () => _push(
                  context,
                  const SectorDashboardScreen(kind: SectorKind.security),
                ),
              ),
              _ActionChip(
                icon: Icons.local_hospital_outlined,
                label: 'Kesehatan',
                onTap: () => _push(
                  context,
                  const SectorDashboardScreen(kind: SectorKind.health),
                ),
              ),
              _ActionChip(
                icon: Icons.dataset_outlined,
                label: 'Data Publik',
                onTap: () => _push(context, const DataHubScreen()),
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
