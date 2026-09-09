import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/sos_provider.dart';
import '../../widgets/app_button.dart';

/// SOS creation flow: category selection -> location -> confirmation.
class SosCreateScreen extends StatefulWidget {
  const SosCreateScreen({super.key});

  @override
  State<SosCreateScreen> createState() => _SosCreateScreenState();
}

class _SosCreateScreenState extends State<SosCreateScreen> {
  String? _category;
  LocationFix? _fix;
  final TextEditingController _messageCtrl = TextEditingController();
  bool _locating = false;

  static const _categories = [
    (
      key: SosAlertCat.medical,
      title: 'MEDIS',
      subtitle: 'Bantuan medis dan kesehatan',
      icon: Icons.medical_services_outlined,
      color: AppColors.sosMedical,
      light: AppColors.medicalLight,
    ),
    (
      key: SosAlertCat.fire,
      title: 'PEMADAM KEBAKARAN',
      subtitle: 'Kebakaran dan evakuasi',
      icon: Icons.local_fire_department_outlined,
      color: AppColors.sosFire,
      light: AppColors.fireLight,
    ),
    (
      key: SosAlertCat.police,
      title: 'POLISI',
      subtitle: 'Keamanan dan ketertiban',
      icon: Icons.local_police_outlined,
      color: AppColors.sosPolice,
      light: AppColors.policeLight,
    ),
  ];

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final provider = context.watch<SosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporkan Keadaan Darurat'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: _category == null
          ? _buildCategory(colors)
          : _buildForm(colors, provider),
    );
  }

  Widget _buildCategory(AppThemeColors colors) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Pilih Jenis Keadaan Darurat',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pilih kategori yang sesuai agar petugas terdekat dapat segera '
          'merespons bantuan Anda.',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final cat in _categories) ...[
          _CategoryCard(
            title: cat.title,
            subtitle: cat.subtitle,
            icon: cat.icon,
            color: cat.color,
            light: cat.light,
            onTap: () => _selectCategory(cat.key),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        _CategoryCard(
          title: 'UMUM / LAINNYA',
          subtitle: 'Keadaan darurat lain yang membutuhkan bantuan',
          icon: Icons.help_outline,
          color: AppColors.sosGeneral,
          light: AppColors.gray100,
          onTap: () => _selectCategory(SosAlertCat.general),
        ),
      ],
    );
  }

  Future<void> _selectCategory(String category) async {
    setState(() {
      _category = category;
      _locating = true;
    });
    try {
      final fix = await const LocationService().currentPosition();
      if (!mounted) return;
      setState(() => _fix = fix);
    } on LocationFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red600,
        ),
      );
      setState(() => _category = null);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Widget _buildForm(AppThemeColors colors, SosProvider provider) {
    final cat = _category!;
    final catColor = _colorFor(cat);
    final catTitle = _titleFor(cat);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                _iconFor(cat),
                color: catColor,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    catTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Lokasi Anda akan dikirim ke petugas',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Ganti Kategori',
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {
                _category = null;
                _fix = null;
                _messageCtrl.clear();
              }),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_locating)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_fix != null) ...[
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(_fix!.latitude, _fix!.longitude),
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'id.go.morowali.mjcc',
                    maxNativeZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_fix!.latitude, _fix!.longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color: AppColors.red600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.gps_fixed,
                size: 14,
                color: AppColors.emerald600,
              ),
              const SizedBox(width: 4),
              Text(
                '${_fix!.latitude.toStringAsFixed(5)}, '
                '${_fix!.longitude.toStringAsFixed(5)}'
                '${_fix!.accuracy != null ? ' (±${_fix!.accuracy!.round()} m)' : ''}',
                style: const TextStyle(
                  color: AppColors.emerald700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _messageCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Deskripsi (opsional)',
              hintText: 'Contoh: Kebakaran di rumah makan dekat pasar',
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'KIRIM SOS',
            icon: Icons.sos,
            variant: AppButtonVariant.danger,
            expanded: true,
            loading: provider.locating,
            onPressed: provider.locating ? null : () => _confirm(context),
          ),
        ],
      ],
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.sos, color: AppColors.red600, size: 40),
        title: const Text('Kirim SOS?'),
        content: Text(
          'Lokasi Anda saat ini akan dikirim ke petugas. Apakah Anda yakin '
          'ingin mengirim permintaan SOS ${
            _titleFor(_category!).toLowerCase()
          } ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red600),
            child: const Text('Kirim SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final provider = context.read<SosProvider>();
    final success = await provider.sendSos(
      message: _messageCtrl.text.trim().isEmpty
          ? null
          : _messageCtrl.text.trim(),
      category: _category!,
    );
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald700,
          content: Text('SOS terkirim! Petugas akan segera menghubungi Anda.'),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.red600,
          content: Text(provider.error ?? 'Gagal mengirim SOS. Coba lagi.'),
        ),
      );
    }
  }

  String _titleFor(String category) => switch (category) {
        SosAlertCat.medical => 'Medis',
        SosAlertCat.fire => 'Pemadam Kebakaran',
        SosAlertCat.police => 'Polisi',
        _ => 'Umum',
      };

  IconData _iconFor(String category) => switch (category) {
        SosAlertCat.medical => Icons.medical_services_outlined,
        SosAlertCat.fire => Icons.local_fire_department_outlined,
        SosAlertCat.police => Icons.local_police_outlined,
        _ => Icons.help_outline,
      };

  Color _colorFor(String category) => switch (category) {
        SosAlertCat.medical => AppColors.sosMedical,
        SosAlertCat.fire => AppColors.sosFire,
        SosAlertCat.police => AppColors.sosPolice,
        _ => AppColors.sosGeneral,
      };
}

class SosAlertCat {
  static const general = 'general';
  static const medical = 'medical';
  static const fire = 'fire';
  static const police = 'police';
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.light,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color light;
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: light,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
