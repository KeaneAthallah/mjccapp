import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A single dataset within a multi-series chart (web `datasets[]`).
class ChartDataset {
  const ChartDataset({required this.label, required this.data, this.color});

  final String label;
  final List<double> data;

  /// Optional override; when null the chart picks from its palette.
  final Color? color;

  factory ChartDataset.fromJson(Map<String, dynamic> json) {
    return ChartDataset(
      label: json['label']?.toString() ?? '',
      data: decodeNumbers(json['data']),
      color: _parseRgba(json['backgroundColor'] ?? json['borderColor']),
    );
  }

  /// Decodes a `datasets[].data` array, tolerating numeric strings and `null`
  /// entries (the API aggregates come from SQL so counts may be strings).
  static List<double> decodeNumbers(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        switch (item) {
          final num n => n.toDouble(),
          final String s => double.tryParse(s) ?? 0,
          _ => 0,
        },
    ];
  }

  /// Best-effort parse of `rgba(r,g,b,a)` colors used by the web charts.
  static Color? _parseRgba(Object? value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty || text.startsWith('#')) return null;
    final match = RegExp(r'rgba?\(([\d.]+),\s*([\d.]+),\s*([\d.]+)').firstMatch(text);
    if (match == null) return null;
    final r = double.tryParse(match.group(1)!)?.round() ?? 0;
    final g = double.tryParse(match.group(2)!)?.round() ?? 0;
    final b = double.tryParse(match.group(3)!)?.round() ?? 0;
    return Color.fromARGB(255, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
  }
}

/// Multi-series chart: `{ labels: [], datasets: [{ label, data, ... }] }`.
class MultiSeriesChart {
  const MultiSeriesChart({required this.labels, required this.datasets});

  final List<String> labels;
  final List<ChartDataset> datasets;

  bool get isEmpty => labels.isEmpty || datasets.isEmpty;

  factory MultiSeriesChart.fromJson(Map<String, dynamic> json) {
    final labels = <String>[
      for (final label in (json['labels'] as List? ?? const []))
        label?.toString() ?? '',
    ];
    final datasets = <ChartDataset>[
      for (final item in (json['datasets'] as List? ?? const []))
        if (item is Map)
          ChartDataset.fromJson(Map<String, dynamic>.from(item)),
    ];
    return MultiSeriesChart(labels: labels, datasets: datasets);
  }
}

/// Single-series chart: `{ labels: [], data: [] }` (pie/doughnut/hbar).
class SingleSeriesChart {
  const SingleSeriesChart({required this.labels, required this.data});

  final List<String> labels;
  final List<double> data;

  bool get isEmpty => labels.isEmpty || data.isEmpty;

  factory SingleSeriesChart.fromJson(Map<String, dynamic> json) {
    final labels = <String>[
      for (final label in (json['labels'] as List? ?? const []))
        label?.toString() ?? '',
    ];
    return SingleSeriesChart(
      labels: labels,
      data: ChartDataset.decodeNumbers(json['data']),
    );
  }
}

/// Facility progress asset: `{ name, pct, meta }`.
class FacilityProgress {
  const FacilityProgress({
    required this.name,
    required this.pct,
    this.meta,
  });

  final String name;
  final int pct;
  final String? meta;

  factory FacilityProgress.fromJson(Map<String, dynamic> json) {
    final pct = json['pct'];
    return FacilityProgress(
      name: json['name']?.toString() ?? '-',
      pct: pct is num
          ? pct.toInt()
          : int.tryParse(pct?.toString() ?? '') ?? 0,
      meta: json['meta']?.toString(),
    );
  }
}

/// Palette mirroring the Tailwind colors used by the website charts.
class ChartPalette {
  const ChartPalette._();

  static const List<Color> bars = [
    AppColors.emerald500,
    AppColors.blue500,
    AppColors.teal100,
    AppColors.red400,
    AppColors.amber500,
    AppColors.dataKeamanan,
  ];

  static const List<Color> pie = [
    AppColors.emerald500,
    AppColors.blue500,
    AppColors.red500,
    AppColors.amber500,
    AppColors.teal100,
    AppColors.dataPendidikan,
    AppColors.emerald700,
    AppColors.blue800,
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
  ];
}