import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/chart_data.dart';
import '../../../data/models/sector_dashboard.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/sector_dashboard_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_states.dart';
import '../../widgets/charts/app_charts.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../map/map_screen.dart';
import '../resources/resource_screens.dart';
import '../security/security_home_screen.dart';

/// Infographic sector dashboards (Pendidikan / Ketertiban / Kesehatan),
/// mirroring the website's `/education`, `/security` and `/health` screens:
/// KPI stats, charts and per-kecamatan recaps from the sector API endpoints.
class SectorDashboardScreen extends StatefulWidget {
  const SectorDashboardScreen({super.key, required this.kind});

  final SectorKind kind;

  @override
  State<SectorDashboardScreen> createState() => _SectorDashboardScreenState();
}

class _SectorDashboardScreenState extends State<SectorDashboardScreen> {
  String get _sectorKey => switch (widget.kind) {
        SectorKind.education => 'pendidikan',
        SectorKind.security => 'ketertiban',
        SectorKind.health => 'kesehatan',
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SectorDashboardProvider>().load(widget.kind);
    });
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SectorDashboardProvider>();
    final master = context.watch<MasterDataProvider>();
    final model = provider.modelFor(widget.kind);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kind.title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            tooltip: 'Peta',
            icon: const Icon(Icons.map_outlined),
            onPressed: () =>
                _push(context, MapScreen(initialSector: _sectorKey)),
          ),
          IconButton(
            tooltip: 'Daftar',
            icon: const Icon(Icons.format_list_bulleted),
            onPressed: () => _push(context, _listScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _HeaderCard(kind: widget.kind),
            const SizedBox(height: AppSpacing.sectionGap),
            if (master.kecamatans != null && master.kecamatans!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
                child: DropdownButtonFormField<int>(
                  key: ValueKey(provider.kecamatanId),
                  initialValue: provider.kecamatanId ?? -1,
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
                  onChanged: (v) => provider
                      .selectKecamatan(widget.kind, v == -1 ? null : v),
                ),
              ),
            if (provider.loading && model == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.error != null && model == null)
              AppErrorState(
                message: provider.error!,
                onRetry: () => provider.load(widget.kind),
              )
            else if (model != null)
              ..._contentFor(context, widget.kind, model),
          ],
        ),
      ),
    );
  }

  Widget _listScreen() => switch (widget.kind) {
        SectorKind.education => const SchoolScreen(),
        SectorKind.security => const SecurityHomeScreen(),
        SectorKind.health => const HealthFacilityScreen(),
      };

  List<Widget> _contentFor(BuildContext context, SectorKind kind, Object model) =>
      switch (kind) {
        SectorKind.education => _educationBody(context, model as EducationDashboard),
        SectorKind.security => _securityBody(context, model as SecurityDashboard),
        SectorKind.health => _healthBody(context, model as HealthDashboard),
      };

  // ---------------------------------------------------------------- education

  List<Widget> _educationBody(BuildContext context, EducationDashboard d) {
    return [
      _StatsGrid(stats: [
        StatCard(
          label: 'SD',
          value: _fmt(d.totalSd),
          icon: Icons.school_outlined,
          color: AppColors.dataPendidikan,
        ),
        StatCard(
          label: 'SMP',
          value: _fmt(d.totalSmp),
          icon: Icons.account_balance_outlined,
          color: AppColors.info,
        ),
        StatCard(
          label: 'Siswa Laki-laki',
          value: _fmt(d.totalMaleStudents),
          icon: Icons.male,
          color: AppColors.emerald600,
        ),
        StatCard(
          label: 'Siswa Perempuan',
          value: _fmt(d.totalFemaleStudents),
          icon: Icons.female,
          color: AppColors.blue600,
        ),
        StatCard(
          label: 'Guru',
          value: _fmt(d.totalTeachers),
          icon: Icons.people_alt_outlined,
          color: AppColors.warning,
        ),
        StatCard(
          label: 'Mata Pelajaran',
          value: _fmt(d.totalSubjects),
          icon: Icons.book_outlined,
          color: AppColors.error,
        ),
      ]),
      const SizedBox(height: AppSpacing.sectionGap),
      AppCard(
        title: 'Siswa per Kecamatan',
        subtitle: 'Laki-laki & Perempuan',
        icon: Icons.bar_chart,
        child: AppCharts.groupedBars(context: context, chart: d.students),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppCard(
        title: 'Sebaran Guru per Kecamatan',
        subtitle: 'Distribusi tenaga pendidik',
        icon: Icons.donut_large_outlined,
        child: Column(
          children: [
            AppCharts.doughnut(context: context, chart: d.teacherRatio),
            _legendIfSmall(d.teacherRatio),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppCard(
        title: 'Kelengkapan Sarana (Rata-rata)',
        subtitle: 'Persentase fasilitas sekolah',
        icon: Icons.build_outlined,
        child: HorizontalBarList(
          color: AppColors.emerald600,
          valueSuffix: '%',
          items: [
            for (final f in d.facilityProgress)
              (label: f.name, value: f.pct, pct: f.pct),
          ],
        ),
      ),
      if (d.table.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        _InfoTableCard(
          title: 'Rekapitulasi Pendidikan per Kecamatan',
          icon: Icons.table_chart_outlined,
          rows: [
            for (final row in d.table)
              if (row is Map)
                (
                  label: row['name']?.toString() ?? '-',
                  value:
                      'SD ${row['sd_count'] ?? 0} · SMP ${row['smp_count'] ?? 0} · '
                      'Kelas ${row['kelas'] ?? 0}',
                ),
          ],
        ),
      ],
    ];
  }

  // ----------------------------------------------------------------- security

  List<Widget> _securityBody(BuildContext context, SecurityDashboard d) {
    return [
      _StatsGrid(stats: [
        StatCard(
          label: 'Kelurahan/Desa',
          value: _fmt(d.totalKelurahan),
          icon: Icons.home_work_outlined,
          color: AppColors.emerald600,
        ),
        StatCard(
          label: 'Polsek',
          value: _fmt(d.totalPolsek),
          icon: Icons.local_police_outlined,
          color: AppColors.info,
        ),
        StatCard(
          label: 'Tipkamtikmas',
          value: _fmt(d.totalTipkamtikmas),
          icon: Icons.report_outlined,
          color: AppColors.error,
        ),
        StatCard(
          label: 'Poskamling Aktif',
          value: _fmt(d.totalPoskamling),
          icon: Icons.visibility_outlined,
          color: AppColors.warning,
        ),
        StatCard(
          label: 'Pasar',
          value: _fmt(d.totalPasar),
          icon: Icons.storefront_outlined,
          color: AppColors.dataFasilitas,
        ),
      ]),
      const SizedBox(height: AppSpacing.sectionGap),
      AppCard(
        title: 'Tipkamtikmas vs Poskamling per Kecamatan',
        subtitle: 'Perbandingan aset ketertiban',
        icon: Icons.bar_chart,
        child: AppCharts.groupedBars(context: context, chart: d.compare),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppCard(
        title: 'Sebaran Poskamling Aktif',
        subtitle: 'Distribusi pos kamling per kecamatan',
        icon: Icons.pie_chart_outline,
        child: Column(
          children: [
            AppCharts.doughnut(context: context, chart: d.distribution),
            _legendIfSmall(d.distribution),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppCard(
        title: 'Banyak Kelurahan per Kecamatan',
        icon: Icons.landscape_outlined,
        child: HorizontalBarList(
          color: AppColors.dataPendidikan,
          items: [for (final (i, _) in d.kelurahan.labels.indexed) (
            label: d.kelurahan.labels[i],
            value: d.kelurahan.data.elementAtOrNull(i) ?? 0,
            pct: null,
          )],
        ),
      ),
      if (d.polseks.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        _InfoTableCard(
          title: 'Daftar Polsek',
          icon: Icons.local_police_outlined,
          rows: [
            for (final p in d.polseks)
              if (p is Map)
                (
                  label: p['name']?.toString() ?? '-',
                  value:
                      'Personel ${p['personnel_count'] ?? 0} · '
                      'Kamling ${p['poskamling_count'] ?? 0}',
                ),
          ],
        ),
      ],
    ];
  }

  // -------------------------------------------------------------------- health

  List<Widget> _healthBody(BuildContext context, HealthDashboard d) {
    return [
      _StatsGrid(stats: [
        StatCard(
          label: 'Puskesmas',
          value: _fmt(d.totalPuskesmas),
          icon: Icons.local_hospital_outlined,
          color: AppColors.emerald600,
        ),
        StatCard(
          label: 'Pustu',
          value: _fmt(d.totalPustu),
          icon: Icons.medical_services_outlined,
          color: AppColors.info,
        ),
        StatCard(
          label: 'Rumah Sakit',
          value: _fmt(d.totalRs),
          icon: Icons.health_and_safety_outlined,
          color: AppColors.error,
        ),
        StatCard(
          label: 'Posyandu',
          value: _fmt(d.totalPosyandu),
          icon: Icons.child_care_outlined,
          color: AppColors.warning,
        ),
        StatCard(
          label: 'Dokter',
          value: _fmt(d.totalDoctors),
          icon: Icons.medical_information_outlined,
          color: AppColors.dataPendidikan,
        ),
        StatCard(
          label: 'Perawat',
          value: _fmt(d.totalNurses),
          icon: Icons.medication_outlined,
          color: AppColors.blue700,
        ),
        StatCard(
          label: 'Bidan',
          value: _fmt(d.totalMidwives),
          icon: Icons.baby_changing_station_outlined,
          color: AppColors.dataKeamanan,
        ),
        StatCard(
          label: 'Tempat Tidur',
          value: _fmt(d.totalBeds),
          icon: Icons.bed_outlined,
          color: AppColors.blue600,
        ),
      ]),
      const SizedBox(height: AppSpacing.sectionGap),
      AppCard(
        title: 'Kapasitas Tempat Tidur per Kecamatan',
        icon: Icons.bed_outlined,
        child: HorizontalBarList(
          color: AppColors.blue600,
          items: [for (final (i, _) in d.capacity.labels.indexed) (
            label: d.capacity.labels[i],
            value: d.capacity.data.elementAtOrNull(i) ?? 0,
            pct: null,
          )],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppCard(
        title: 'Komposisi Fasilitas',
        subtitle: 'Puskesmas · Pustu · RS · Posyandu',
        icon: Icons.donut_large_outlined,
        child: Column(
          children: [
            AppCharts.doughnut(context: context, chart: d.proportion),
            ChartLegend(items: [
              for (final (i, label) in d.proportion.labels.indexed)
                (
                  label: label,
                  color: ChartPalette.pie[i % ChartPalette.pie.length],
                ),
            ]),
            const SizedBox(height: 4),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppCard(
        title: 'Tenaga Kesehatan per Kecamatan',
        subtitle: 'Dokter · Perawat · Bidan',
        icon: Icons.group_outlined,
        child: Column(
          children: [
            AppCharts.groupedBars(context: context, chart: d.workforce),
            const SizedBox(height: AppSpacing.sm),
            ChartLegend(items: [
              for (final ds in d.workforce.datasets)
                (label: ds.label, color: ds.color),
            ]),
          ],
        ),
      ),
      if (d.table.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        _InfoTableCard(
          title: 'Rekapitulasi Kesehatan per Kecamatan',
          icon: Icons.table_chart_outlined,
          rows: [
            for (final row in d.table)
              if (row is Map)
                (
                  label: row['name']?.toString() ?? '-',
                  value:
                      'Pusk ${row['puskesmas_count'] ?? 0} · Pustu ${row['pustu_count'] ?? 0} · '
                      'RS ${row['rs_count'] ?? 0} · Posy ${row['posyandu_count'] ?? 0} · '
                      'Bed ${row['bed'] ?? 0}',
                ),
          ],
        ),
      ],
    ];
  }

  Widget _legendIfSmall(SingleSeriesChart chart) {
    if (chart.labels.isEmpty || chart.labels.length > 8) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        ChartLegend(items: [
          for (final (i, label) in chart.labels.indexed)
            (
              label: label,
              color: ChartPalette.pie[i % ChartPalette.pie.length],
            ),
        ]),
      ],
    );
  }

  static String _fmt(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write('.');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }
}

/// Gradient header identifying the sector dashboard.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.kind});

  final SectorKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kind.color.withValues(alpha: 0.9),
            kind.color,
            AppColors.blue700,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: kind.color.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(kind.icon, size: 28, color: kind.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kind.subtitle.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'DASHBOARD PEMANTAUAN',
                  style: TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

/// Responsive grid of [StatCard]s (2 columns mobile, up to 4 on wide).
/// Uses [Wrap] like the main dashboard grid so cards size to their own
/// content height instead of a fixed aspect ratio (no overflow on phones).
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final List<StatCard> stats;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in stats) SizedBox(width: cardWidth, child: s),
          ],
        );
      },
    );
  }
}

/// Per-kecamatan recap rows in the app's card-list style.
class _InfoTableCard extends StatelessWidget {
  const _InfoTableCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<({String label, String value})> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: title,
      icon: icon,
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        color: AppColors.gray700,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.gray600,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
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