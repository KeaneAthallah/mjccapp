import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/repositories.dart';
import '../../providers/master_data_provider.dart';
import '../../widgets/async_view.dart';

/// Master data hub: kecamatan (with kelurahan) and subject reference lists.
class MasterHomeScreen extends StatefulWidget {
  const MasterHomeScreen({super.key});

  @override
  State<MasterHomeScreen> createState() => _MasterHomeScreenState();
}

class _MasterHomeScreenState extends State<MasterHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Data'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Kecamatan'),
            Tab(text: 'Subjek'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [KecamatanTab(), SubjectTab()],
      ),
    );
  }
}

class KecamatanTab extends StatelessWidget {
  const KecamatanTab({super.key});

  @override
  Widget build(BuildContext context) {
    final master = context.watch<MasterDataProvider>();
    if (master.kecamatans == null) {
      return const AsyncLoadingView();
    }
    if (master.kecamatans!.isEmpty) {
      return const AsyncEmptyView(message: 'Belum ada kecamatan.');
    }
    final kecamatans = master.kecamatans!;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xs),
      itemCount: kecamatans.length,
      itemBuilder: (context, i) {
        final k = kecamatans[i];
        final colors = AppThemeColors.of(context);
        return Card(
          margin: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: AppSpacing.xs,
          ),
          child: ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm - 3),
              ),
              child: const Icon(
                Icons.map_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              k.name ?? '-',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            subtitle: k.code != null && k.code!.isNotEmpty
                ? Text(
                    'Kode: ${k.code}',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  )
                : null,
            initiallyExpanded: i == 0,
            children: [_KelurahanList(kecamatanId: k.id)],
          ),
        );
      },
    );
  }
}

class _KelurahanList extends StatefulWidget {
  const _KelurahanList({required this.kecamatanId});

  final int kecamatanId;

  @override
  State<_KelurahanList> createState() => _KelurahanListState();
}

class _KelurahanListState extends State<_KelurahanList> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Repositories.instance.kecamatan.kelurahans(widget.kecamatanId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Belum ada kelurahan.'),
          );
        }
        return Column(
          children: [
            for (final kel in list)
              ListTile(
                dense: true,
                leading: const Icon(Icons.location_city_outlined, size: 20),
                title: Text(kel.name ?? '-'),
                subtitle: kel.population != null
                    ? Text('Penduduk: ${kel.population}')
                    : null,
              ),
          ],
        );
      },
    );
  }
}

class SubjectTab extends StatelessWidget {
  const SubjectTab({super.key});

  @override
  Widget build(BuildContext context) {
    final master = context.watch<MasterDataProvider>();
    if (master.subjects == null) {
      return const AsyncLoadingView();
    }
    final subjects = master.subjects!;
    if (subjects.isEmpty) {
      return const AsyncEmptyView(message: 'Belum ada subjek.');
    }
    return ListView.separated(
      itemCount: subjects.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final s = subjects[i];
        final colors = AppThemeColors.of(context);
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm - 3),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            s.name ?? '-',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: s.code != null
              ? Text('Kode: ${s.code}')
              : null,
        );
      },
    );
  }
}
