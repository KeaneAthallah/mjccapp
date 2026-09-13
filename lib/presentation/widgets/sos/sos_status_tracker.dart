import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/sos_alert.dart';

/// Step-by-step visual tracker for an SOS lifecycle:
/// active -> acknowledged -> responding -> resolved (or cancelled).
class SosStatusTracker extends StatelessWidget {
  const SosStatusTracker({super.key, required this.alert});

  final SosAlert alert;

  static const _steps = [
    (key: 'active', label: 'SOS Dikirim'),
    (key: 'acknowledged', label: 'SOS Diterima'),
    (key: 'responding', label: 'Petugas Menuju Lokasi'),
    (key: 'on_the_way', label: 'Petugas di Perjalanan'),
    (key: 'arrived', label: 'Petugas Tiba di Lokasi'),
    (key: 'resolved', label: 'SOS Selesai'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isCancelled = alert.status == SosAlert.statusCancelled;
    final current = _stepIndex(alert.status);

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: colors.onErrorContainer, size: 20),
            const SizedBox(width: 8),
            Text(
              'SOS ini telah dibatalkan dan tidak memerlukan penanganan.',
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          _stepRow(
            index: i,
            reached: i <= current,
            last: i == _steps.length - 1,
            label: _steps[i].label,
            colors: colors,
          ),
        ],
        if (alert.status == SosAlert.statusConstrained &&
            alert.constraintReason != null)
          _constraintBanner(alert),
      ],
    );
  }

  int _stepIndex(String status) {
    return switch (status) {
      SosAlert.statusActive => 0,
      SosAlert.statusAcknowledged => 1,
      SosAlert.statusResponding => 2,
      SosAlert.statusOnTheWay => 3,
      SosAlert.statusConstrained => 3,
      SosAlert.statusArrived => 4,
      SosAlert.statusResolved => 5,
      _ => -1,
    };
  }

  Widget _constraintBanner(SosAlert alert) {
    final typeLabel = alert.constraintTypeDisplay;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amber100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber500),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.amber700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Petugas Terkendala',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amber700,
                  ),
                ),
                if (typeLabel != null)
                  Text(
                    typeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray800,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  alert.constraintReason!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepRow({
    required int index,
    required bool reached,
    required bool last,
    required String label,
    required ColorScheme colors,
  }) {
    final onColor = reached ? colors.primary : colors.outlineVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reached ? colors.primary : colors.surfaceContainerHighest,
              ),
              child: Center(
                child: reached
                    ? Icon(Icons.check, size: 16, color: colors.onPrimary)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            if (!last)
              Container(width: 2, height: 22, color: onColor.withValues(alpha: 0.4)),
          ],
        ),
        const SizedBox(width: 10),
        Padding(
          padding: EdgeInsets.only(top: reached ? 4 : 4, left: 2),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: reached ? FontWeight.w800 : FontWeight.w500,
              color: reached ? colors.onSurface : colors.outline,
            ),
          ),
        ),
      ],
    );
  }
}