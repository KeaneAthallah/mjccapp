import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/chart_data.dart';

/// Shared chart primitives that mirror the website's Chart.js charts
/// (bar / stacked bar / doughnut / polar) using `fl_chart`, adapted for a
/// mobile viewport with compact fonts and tooltips.
class AppCharts {
  AppCharts._();

  static String _thousands(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write('.');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  /// Vertical grouped bars (multi-series), e.g. Perbandingan Sektor.
  static Widget groupedBars({
    required BuildContext context,
    required MultiSeriesChart chart,
    double height = 220,
    bool stacked = false,
  }) {
    if (chart.isEmpty) {
      return _emptyBox(height, AppThemeColors.of(context).textMuted);
    }
    final theme = AppThemeColors.of(context);
    final labels = chart.labels;
    final datasets = chart.datasets;

    double seriesMax() => datasets.fold<double>(0, (acc, ds) {
          final m = ds.data.fold<double>(0, (a, v) => v > a ? v : a);
          return m > acc ? m : acc;
        });

    // For stacked bars the ceiling must be the per-group total (the sum of all
    // series in each group); the per-series max alone lets tall stacks
    // overflow the chart top edge.
    double stackedMax() {
      var m = 0.0;
      for (var i = 0; i < labels.length; i++) {
        var sum = 0.0;
        for (final ds in datasets) {
          sum += ds.data.elementAtOrNull(i) ?? 0;
        }
        if (sum > m) m = sum;
      }
      return m;
    }

    final maxValue = stacked ? stackedMax() : seriesMax();
    final effectiveMax = maxValue <= 0 ? 10.0 : maxValue * 1.15;

    // "Nice" y-axis step so labels are round (1, 2, 2.5, 5, 10, ...).
    double interval() {
      if (effectiveMax <= 0) return 1;
      const candidates = [1, 2, 2.5, 5, 10, 20, 25, 50, 100, 200, 250, 500, 1000];
      for (final c in candidates) {
        if (effectiveMax / c <= 5) return c.toDouble();
      }
      return 1000.0;
    }

    final rodBorderRadius = BorderRadius.circular(2);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: effectiveMax,
          alignment: BarChartAlignment.spaceAround,
          barGroups: [
            for (var i = 0; i < labels.length; i++)
              if (stacked)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    _stackedRod(chart, i, effectiveMax, theme.surfaceAlt),
                  ],
                )
              else
                BarChartGroupData(
                  x: i,
                  barsSpace: 2,
                  barRods: [
                    for (var d = 0; d < datasets.length; d++)
                      BarChartRodData(
                        toY: datasets[d].data.elementAtOrNull(i) ?? 0,
                        color: datasets[d].color ??
                            ChartPalette.bars[d % ChartPalette.bars.length],
                        width: 7,
                        borderRadius: rodBorderRadius,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: effectiveMax,
                          color: theme.surfaceAlt,
                        ),
                      ),
                  ],
                ),
          ],
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: interval(),
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 6,
                  child: Text(
                    _compact(value.round()),
                    style: TextStyle(fontSize: 9, color: theme.textMuted),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  final label = labels[index];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 2,
                    child: _BarLabel(
                      label: label,
                      rotate: labels.length > 7,
                      color: theme.textMuted,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval(),
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.cardBorder,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            handleBuiltInTouches: !stacked,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.gray900,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              fitInsideVertically: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final dataset = datasets.elementAtOrNull(rodIndex);
                if (dataset == null) return null;
                return BarTooltipItem(
                  '${dataset.label}\n${_thousands(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static BarChartRodData _stackedRod(
    MultiSeriesChart chart,
    int index,
    double effectiveMax,
    Color backgroundColor,
  ) {
    var cursor = 0.0;
    final items = <BarChartRodStackItem>[];
    for (var d = 0; d < chart.datasets.length; d++) {
      final dataset = chart.datasets[d];
      final value = dataset.data.elementAtOrNull(index) ?? 0;
      if (value <= 0) continue;
      items.add(
        BarChartRodStackItem(
          cursor,
          cursor + value,
          dataset.color ?? ChartPalette.bars[d % ChartPalette.bars.length],
        ),
      );
      cursor += value;
    }
    if (cursor <= 0) cursor = 1;
    return BarChartRodData(
      toY: cursor,
      width: 7,
      color: items.isEmpty ? AppColors.primary : items.first.color,
      rodStackItems: items,
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: effectiveMax,
        color: backgroundColor,
      ),
    );
  }

  /// Doughnut / pie chart for single-series data (teacher ratio, komposisi).
  static Widget doughnut({
    required BuildContext context,
    required SingleSeriesChart chart,
    double height = 210,
    bool hole = true,
  }) {
    if (chart.isEmpty || chart.data.every((v) => v <= 0)) {
      return _emptyBox(height, AppThemeColors.of(context).textMuted);
    }
    final colors = ChartPalette.pie;
    final total = chart.data.fold<double>(0, (a, v) => a + v);
    final sections = <PieChartSectionData>[
      for (var i = 0; i < chart.data.length; i++)
        PieChartSectionData(
          value: chart.data[i] < 0 ? 0 : chart.data[i],
          color: colors[i % colors.length],
          radius: 26,
          title: total > 0 && chart.data[i] >= 0
              ? '${((chart.data[i] / total) * 100).round()}%'
              : '',
          showTitle: chart.data[i] > 0,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
    ];
    return SizedBox(
      height: height,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: hole ? 30 : 2,
          sectionsSpace: hole ? 2 : 1,
          startDegreeOffset: -90,
          borderData: FlBorderData(show: false),
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {},
          ),
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }

  /// Polar chart for the infrastructure composition (RadarChart with 3+ axes).
  static Widget polar({
    required BuildContext context,
    required SingleSeriesChart chart,
    double height = 220,
  }) {
    if (chart.isEmpty || chart.labels.length < 3) {
      return _emptyBox(height, AppThemeColors.of(context).textMuted);
    }
    final theme = AppThemeColors.of(context);
    return SizedBox(
      height: height,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              dataEntries: [
                for (final v in chart.data) RadarEntry(value: v),
              ],
              fillColor: AppColors.emerald500.withValues(alpha: 0.30),
              borderColor: AppColors.emerald600,
              borderWidth: 2,
              entryRadius: 3,
            ),
          ],
          radarShape: RadarShape.polygon,
          radarBackgroundColor: Colors.transparent,
          radarBorderData: BorderSide(color: theme.cardBorder),
          gridBorderData: BorderSide(color: theme.cardBorder),
          tickBorderData: BorderSide(color: theme.cardBorder),
          ticksTextStyle: TextStyle(fontSize: 9, color: theme.textMuted),
          titleTextStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: theme.textPrimary,
          ),
          titlePositionPercentageOffset: 0.18,
          getTitle: (index, angle) => RadarChartTitle(
            text: chart.labels.elementAtOrNull(index) ?? '',
          ),
        ),
      ),
    );
  }

  /// Custom compact text that stays inside the reserved bottom slot.
  static String _compact(int value) {
    if (value >= 1000000) return '${(value / 1000000).round()}jt';
    if (value >= 1000) return '${(value / 1000).round()}rb';
    return '$value';
  }
}

class _BarLabel extends StatelessWidget {
  const _BarLabel({
    required this.label,
    required this.rotate,
    required this.color,
  });

  final String label;
  final bool rotate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: rotate ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: rotate ? 9.0 : 8.5, color: color),
    );
    if (label.length <= 8 && !rotate) return text;
    if (rotate) {
      final short = label.split(' ').first;
      return Transform.rotate(
        angle: -0.9,
        child: Text(
          short,
          style: TextStyle(fontSize: 9, color: color),
        ),
      );
    }
    return text;
  }
}

Widget _emptyBox(double height, Color textColor) => SizedBox(
      height: height,
      child: Center(
        child: Text(
          'Belum ada data grafik.',
          style: TextStyle(fontSize: 12, color: textColor),
        ),
      ),
    );

/// Color legend row (chips) used below doughnut/pie charts.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.items});

  /// (label, color) pairs; colors default to the pie palette when null.
  final List<({String label, Color? color})> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final (i, item) in items.indexed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.color ??
                      ChartPalette.pie[i % ChartPalette.pie.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppThemeColors.of(context).textSecondary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Track-based horizontal bars for single-series distributions
/// (e.g. kapasitas tempat tidur, kelurahan per kecamatan, sarana rata-rata).
class HorizontalBarList extends StatelessWidget {
  const HorizontalBarList({
    super.key,
    required this.items,
    this.color = AppColors.blue500,
    this.showValue = true,
    this.valueSuffix = '',
  });

  /// (label, value, pct) — pct optional; when null it is derived from max.
  final List<({String label, num value, int? pct})> items;
  final Color color;
  final bool showValue;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'Belum ada data.',
        style: TextStyle(
          fontSize: 12,
          color: AppThemeColors.of(context).textMuted,
        ),
      );
    }
    final theme = AppThemeColors.of(context);
    final maxValue = items
        .map((e) => e.value)
        .fold<num>(1, (a, v) => v > a ? v : a);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                    if (showValue)
                      Text(
                        '${AppCharts._thousands(item.value)}$valueSuffix',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (item.pct ?? ((item.value / maxValue) * 100)) / 100,
                    minHeight: 8,
                    color: color,
                    backgroundColor: theme.surfaceAlt,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}