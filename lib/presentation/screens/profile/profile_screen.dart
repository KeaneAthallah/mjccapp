import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/repositories.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_card.dart';

/// View + edit profile and change password.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _editProfile() => _showEditDialog();

  Future<void> _showEditDialog() async {
    final auth = context.read<AuthProvider>();
    final nameCtrl = TextEditingController(text: auth.user?.name ?? '');
    final emailCtrl = TextEditingController(text: auth.user?.email ?? '');
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Profil'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Email wajib diisi'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved == true) {
      try {
        await Repositories.instance.profile.update(
          name: nameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
        );
        if (!mounted) return;
        await context.read<AuthProvider>().refreshUser();
        _snack('Profil berhasil diperbarui.');
      } on AppException catch (e) {
        if (mounted) _snack(e.message);
      }
    }
  }

  void _changePassword() {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Ubah Kata Sandi'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: current,
                  obscureText: obscure,
                  decoration: const InputDecoration(
                    labelText: 'Kata sandi saat ini',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: next,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Kata sandi baru',
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Minimal 8 karakter' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: confirm,
                  obscureText: obscure,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi kata sandi baru',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      (v != next.text) ? 'Konfirmasi tidak cocok' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  await Repositories.instance.profile.changePassword(
                    currentPassword: current.text,
                    newPassword: next.text,
                  );
                  if (mounted) _snack('Kata sandi berhasil diperbarui.');
                } on AppException catch (e) {
                  if (mounted) _snack(e.message);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final colors = AppThemeColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            padding: true,
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.emerald500, AppColors.blue600],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (user?.name.isNotEmpty ?? false)
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  user?.name ?? '-',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    (user?.role.wire ?? 'viewer').toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                if (user?.isResponder ?? false) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _ResponderBadge(type: user!.responderType!),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.edit_outlined,
                  title: 'Ubah Profil',
                  subtitle: 'Nama dan email',
                  onTap: _editProfile,
                ),
                const Divider(height: 1),
                _ProfileTile(
                  icon: Icons.lock_outline,
                  title: 'Ubah Kata Sandi',
                  subtitle: 'Perbarui kata sandi akun',
                  onTap: _changePassword,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponderBadge extends StatelessWidget {
  const _ResponderBadge({required this.type});

  final ResponderType type;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (type) {
      ResponderType.medical => (
          AppColors.sosMedical,
          Icons.medical_services_outlined,
          'PETUGAS MEDIS',
        ),
      ResponderType.fire => (
          AppColors.sosFire,
          Icons.local_fire_department_outlined,
          'PETUGAS PEMADAM KEBAKARAN',
        ),
      ResponderType.police => (
          AppColors.sosPolice,
          Icons.local_police_outlined,
          'PETUGAS POLISI',
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm - 3),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
