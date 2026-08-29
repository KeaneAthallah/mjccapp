import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/health_facility.dart';
import '../../../data/models/market.dart';
import '../../../data/models/polsek.dart';
import '../../../data/models/poskamling.dart';
import '../../../data/models/school.dart';
import '../../../data/models/tipkamtikmas.dart';
import '../../providers/auth_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/resource_list_providers.dart';
import '../../widgets/app_status_badge.dart';
import '../../widgets/form/form_field_spec.dart';
import '../../widgets/form/resource_form_screen.dart';
import '../../widgets/list_screen.dart';

/// A concrete list+form screen for one CRUD resource.
class ResourceListView<T> extends StatefulWidget {
  const ResourceListView({
    super.key,
    required this.title,
    required this.providerFactory,
    required this.fieldBuilder,
    this.canWrite = true,
  });

  final String title;
  final ListProvider<T> Function() providerFactory;

  /// Builds form fields; receives [MasterDataProvider] for pickers.
  final List<FormFieldSpec> Function(
    BuildContext context,
    MasterDataProvider master,
  )
  fieldBuilder;

  final bool canWrite;

  @override
  State<ResourceListView<T>> createState() => _ResourceListViewState<T>();
}

class _ResourceListViewState<T> extends State<ResourceListView<T>> {
  late final ListProvider<T> _provider = widget.providerFactory();

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _openForm({T? item}) async {
    final master = context.read<MasterDataProvider>();
    await master.ensureLoaded().catchError((_) => []);
    if (!mounted) return;

    final editId = item == null ? null : (item as dynamic).id as int;
    final fields = widget.fieldBuilder(context, master);
    final initial = item == null ? null : (item as dynamic).toRequest();

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ResourceFormScreen<T>(
          title: editId == null
              ? 'Tambah ${widget.title}'
              : 'Ubah ${widget.title}',
          api: _provider.api,
          fields: fields,
          initial: initial,
          editId: editId,
        ),
      ),
    );
    if (saved == true) _provider.loadFirst();
  }

  String? _subtitle(dynamic item) {
    if (item is School) {
      return [
        if (item.schoolType != null) item.schoolType!,
        if (item.kecamatan != null) item.kecamatan!,
      ].join(' • ');
    }
    if (item is HealthFacility) {
      return [
        if (item.facilityType != null) item.facilityType!,
        if (item.kecamatan != null) item.kecamatan!,
      ].join(' • ');
    }
    if (item is Polsek) {
      return [if (item.kecamatan != null) item.kecamatan!].join(' • ');
    }
    if (item is Market) {
      return [
        if (item.status != null) item.status!,
        if (item.kecamatan != null) item.kecamatan!,
      ].join(' • ');
    }
    if (item is Poskamling) {
      return [
        if (item.status != null) item.status!,
        if (item.kecamatan != null) item.kecamatan!,
      ].join(' • ');
    }
    if (item is Tipkamtikmas) {
      return [
        if (item.status != null) item.status!,
        if (item.kecamatan != null) item.kecamatan!,
      ].join(' • ');
    }
    return null;
  }

  (IconData, Color, String?) _iconFor(dynamic item) {
    if (item is School) return (Icons.school_outlined, AppColors.primary, null);
    if (item is HealthFacility) {
      return (
        Icons.local_hospital_outlined,
        AppColors.primary,
        item.status,
      );
    }
    if (item is Polsek) {
      return (Icons.local_police_outlined, AppColors.error, item.status);
    }
    if (item is Market) {
      return (Icons.storefront_outlined, AppColors.amber700, item.status);
    }
    if (item is Poskamling) {
      return (Icons.visibility_outlined, AppColors.teal700, item.status);
    }
    if (item is Tipkamtikmas) {
      return (Icons.report_outlined, AppColors.error, item.status);
    }
    return (Icons.label_outline, AppColors.primary, null);
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = widget.canWrite;
    final colors = AppThemeColors.of(context);
    return ListScreen<T>(
      title: widget.title,
      provider: _provider,
      canWrite: canWrite,
      itemBuilder: (context, item) {
        final name = (item as dynamic).name ?? (item as dynamic).title ?? '';
        final subtitle = _subtitle(item);
        final (icon, color, status) = _iconFor(item);
        return Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm - 2),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (status != null && status.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.xs),
              AppStatusBadge(
                label: status,
                tone: AppStatusBadge.toneFrom(status),
              ),
            ],
          ],
        );
      },
      onCreate: canWrite ? () => _openForm() : null,
      onEdit: canWrite ? (ctx, item) => _openForm(item: item) : null,
    );
  }
}

/// Public constructors for each resource list screen.
List<FormOption> kecamatanOptions(MasterDataProvider master) {
  final kecamatans = master.kecamatans ?? [];
  return [for (final k in kecamatans) FormOption(k.id, k.name ?? '-')];
}

List<FormOption> subjectOptions(MasterDataProvider master) {
  final subjects = master.subjects ?? [];
  return [for (final s in subjects) FormOption(s.id, s.name ?? '-')];
}

class SchoolScreen extends StatelessWidget {
  const SchoolScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ResourceListView<School>(
      title: 'Sekolah',
      canWrite: auth.canWrite,
      providerFactory: _schoolFactory,
      fieldBuilder: _schoolFields,
    );
  }
}

class HealthFacilityScreen extends StatelessWidget {
  const HealthFacilityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ResourceListView<HealthFacility>(
      title: 'Fasilitas Kesehatan',
      canWrite: auth.canWrite,
      providerFactory: _healthFactory,
      fieldBuilder: _healthFields,
    );
  }
}

class PolsekScreen extends StatelessWidget {
  const PolsekScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ResourceListView<Polsek>(
      title: 'Polsek',
      canWrite: auth.canWrite,
      providerFactory: _polsekFactory,
      fieldBuilder: _polsekFields,
    );
  }
}

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ResourceListView<Market>(
      title: 'Pasar',
      canWrite: auth.canWrite,
      providerFactory: _marketFactory,
      fieldBuilder: _marketFields,
    );
  }
}

class PoskamlingScreen extends StatelessWidget {
  const PoskamlingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ResourceListView<Poskamling>(
      title: 'Poskamling',
      canWrite: auth.canWrite,
      providerFactory: _poskamlingFactory,
      fieldBuilder: _poskamlingFields,
    );
  }
}

class TipkamtikmasScreen extends StatelessWidget {
  const TipkamtikmasScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ResourceListView<Tipkamtikmas>(
      title: 'Tipkamtikmas',
      canWrite: auth.canWrite,
      providerFactory: _tipkamtikmasFactory,
      fieldBuilder: _tipkamtikmasFields,
    );
  }
}

ListProvider<School> _schoolFactory() => SchoolListProvider();
List<FormFieldSpec> _schoolFields(
  BuildContext context,
  MasterDataProvider master,
) => [
  FormFieldSpec(key: 'name', label: 'Nama Sekolah', required: true),
  FormFieldSpec(
    key: 'school_type',
    label: 'Jenjang',
    type: FormFieldType.dropdown,
    required: true,
    options: const [FormOption('SD', 'SD'), FormOption('SMP', 'SMP')],
  ),
  FormFieldSpec(key: 'npsn', label: 'NPSN'),
  FormFieldSpec(
    key: 'kecamatan_id',
    label: 'Kecamatan',
    type: FormFieldType.dropdown,
    required: true,
    options: kecamatanOptions(master),
  ),
  FormFieldSpec(key: 'address', label: 'Alamat', type: FormFieldType.multiline),
  FormFieldSpec(
    key: 'latitude',
    label: 'Latitude',
    type: FormFieldType.decimal,
    hint: '-2.1234',
  ),
  FormFieldSpec(
    key: 'longitude',
    label: 'Longitude',
    type: FormFieldType.decimal,
    hint: '121.1234',
  ),
  FormFieldSpec(key: 'condition', label: 'Kondisi'),
  FormFieldSpec(
    key: 'students_male',
    label: 'Siswa Laki-laki',
    type: FormFieldType.number,
    required: true,
  ),
  FormFieldSpec(
    key: 'students_female',
    label: 'Siswa Perempuan',
    type: FormFieldType.number,
    required: true,
  ),
  FormFieldSpec(
    key: 'teachers',
    label: 'Guru',
    type: FormFieldType.number,
    required: true,
  ),
  FormFieldSpec(
    key: 'classes',
    label: 'Rombel',
    type: FormFieldType.number,
    required: true,
  ),
  FormFieldSpec(
    key: 'capacity',
    label: 'Kapasitas',
    type: FormFieldType.number,
    required: true,
  ),
  FormFieldSpec(key: 'is_active', label: 'Aktif', type: FormFieldType.bool),
  FormFieldSpec(
    key: 'subjects',
    label: 'Mata Pelajaran',
    type: FormFieldType.multiSelect,
    options: subjectOptions(master),
  ),
];

ListProvider<HealthFacility> _healthFactory() => HealthFacilityListProvider();
List<FormFieldSpec> _healthFields(
  BuildContext context,
  MasterDataProvider master,
) => [
  FormFieldSpec(
    key: 'kecamatan_id',
    label: 'Kecamatan',
    type: FormFieldType.dropdown,
    required: true,
    options: kecamatanOptions(master),
  ),
  FormFieldSpec(key: 'name', label: 'Nama Fasilitas', required: true),
  FormFieldSpec(
    key: 'facility_type',
    label: 'Jenis',
    type: FormFieldType.dropdown,
    required: true,
    options: const [
      FormOption('Puskesmas', 'Puskesmas'),
      FormOption('Pustu', 'Pustu'),
      FormOption('Rumah Sakit', 'Rumah Sakit'),
      FormOption('Posyandu', 'Posyandu'),
    ],
  ),
  FormFieldSpec(key: 'address', label: 'Alamat', type: FormFieldType.multiline),
  FormFieldSpec(
    key: 'latitude',
    label: 'Latitude',
    type: FormFieldType.decimal,
  ),
  FormFieldSpec(
    key: 'longitude',
    label: 'Longitude',
    type: FormFieldType.decimal,
  ),
  FormFieldSpec(
    key: 'beds',
    label: 'Tempat Tidur',
    type: FormFieldType.number,
    required: true,
  ),
  FormFieldSpec(
    key: 'doctors',
    label: 'Dokter',
    type: FormFieldType.number,
    required: true,
  ),
  FormFieldSpec(
    key: 'nurses',
    label: 'Perawat',
    type: FormFieldType.number,
    required: true,
  ),
  FormFieldSpec(
    key: 'midwives',
    label: 'Bidan',
    type: FormFieldType.number,
    required: true,
  ),
  FormFieldSpec(key: 'status', label: 'Status'),
  FormFieldSpec(key: 'phone', label: 'Telepon', type: FormFieldType.number),
  FormFieldSpec(
    key: 'description',
    label: 'Deskripsi',
    type: FormFieldType.multiline,
  ),
];

ListProvider<Polsek> _polsekFactory() => PolsekListProvider();
List<FormFieldSpec> _polsekFields(
  BuildContext context,
  MasterDataProvider master,
) => [
  FormFieldSpec(
    key: 'kecamatan_id',
    label: 'Kecamatan',
    type: FormFieldType.dropdown,
    required: true,
    options: kecamatanOptions(master),
  ),
  FormFieldSpec(key: 'name', label: 'Nama Polsek', required: true),
  FormFieldSpec(key: 'address', label: 'Alamat', type: FormFieldType.multiline),
  FormFieldSpec(
    key: 'latitude',
    label: 'Latitude',
    type: FormFieldType.decimal,
  ),
  FormFieldSpec(
    key: 'longitude',
    label: 'Longitude',
    type: FormFieldType.decimal,
  ),
  FormFieldSpec(
    key: 'personnel_count',
    label: 'Jumlah Personel',
    type: FormFieldType.number,
    required: true,
  ),
  FormFieldSpec(
    key: 'poskamling_count',
    label: 'Jumlah Poskamling',
    type: FormFieldType.number,
    required: true,
  ),
  FormFieldSpec(key: 'status', label: 'Status'),
];

ListProvider<Market> _marketFactory() => MarketListProvider();
List<FormFieldSpec> _marketFields(
  BuildContext context,
  MasterDataProvider master,
) => [
  FormFieldSpec(
    key: 'kecamatan_id',
    label: 'Kecamatan',
    type: FormFieldType.dropdown,
    required: true,
    options: kecamatanOptions(master),
  ),
  FormFieldSpec(key: 'name', label: 'Nama Pasar', required: true),
  FormFieldSpec(key: 'address', label: 'Alamat', type: FormFieldType.multiline),
  FormFieldSpec(
    key: 'latitude',
    label: 'Latitude',
    type: FormFieldType.decimal,
  ),
  FormFieldSpec(
    key: 'longitude',
    label: 'Longitude',
    type: FormFieldType.decimal,
  ),
  FormFieldSpec(key: 'status', label: 'Status'),
];

ListProvider<Poskamling> _poskamlingFactory() => PoskamlingListProvider();
List<FormFieldSpec> _poskamlingFields(
  BuildContext context,
  MasterDataProvider master,
) => [
  FormFieldSpec(
    key: 'kecamatan_id',
    label: 'Kecamatan',
    type: FormFieldType.dropdown,
    required: true,
    options: kecamatanOptions(master),
  ),
  FormFieldSpec(key: 'name', label: 'Nama Poskamling', required: true),
  FormFieldSpec(
    key: 'latitude',
    label: 'Latitude',
    type: FormFieldType.decimal,
  ),
  FormFieldSpec(
    key: 'longitude',
    label: 'Longitude',
    type: FormFieldType.decimal,
  ),
  FormFieldSpec(key: 'status', label: 'Status'),
  FormFieldSpec(key: 'is_active', label: 'Aktif', type: FormFieldType.bool),
];

ListProvider<Tipkamtikmas> _tipkamtikmasFactory() => TipkamtikmasListProvider();
List<FormFieldSpec> _tipkamtikmasFields(
  BuildContext context,
  MasterDataProvider master,
) => [
  FormFieldSpec(
    key: 'kecamatan_id',
    label: 'Kecamatan',
    type: FormFieldType.dropdown,
    required: true,
    options: kecamatanOptions(master),
  ),
  FormFieldSpec(key: 'title', label: 'Judul', required: true),
  FormFieldSpec(
    key: 'description',
    label: 'Deskripsi',
    type: FormFieldType.multiline,
  ),
  FormFieldSpec(key: 'status', label: 'Status'),
  FormFieldSpec(
    key: 'latitude',
    label: 'Latitude',
    type: FormFieldType.decimal,
  ),
  FormFieldSpec(
    key: 'longitude',
    label: 'Longitude',
    type: FormFieldType.decimal,
  ),
];
