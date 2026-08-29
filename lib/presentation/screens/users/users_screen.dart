import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/repositories.dart';
import '../../providers/user_management_provider.dart';
import '../../widgets/async_view.dart';
import '../../widgets/app_status_badge.dart';

/// Admin users management screen.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  bool _moreCalled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementProvider>().loadFirst();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm(UserModel? user) async {
    final repo = Repositories.instance.userManagement;
    final userForm = UserFormData(user: user);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => UserFormDialog(data: userForm),
    );
    if (saved == true) {
      try {
        if (user == null) {
          await repo.create(
            name: userForm.name,
            email: userForm.email,
            role: userForm.role.wire,
            password: userForm.password,
          );
        } else {
          await repo.update(
            user.id,
            name: userForm.name,
            email: userForm.email,
            role: userForm.role.wire,
            password: userForm.password,
          );
        }
        if (mounted) context.read<UserManagementProvider>().loadFirst();
      } on AppException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
  }

  Future<void> _delete(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pengguna'),
        content: Text('Hapus pengguna "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final provider = context.read<UserManagementProvider>();
    await provider.delete(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserManagementProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengguna')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(null),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => provider.setSearch(v),
              decoration: const InputDecoration(
                hintText: 'Cari nama/email...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: provider,
              builder: (context, _) {
                if (provider.loading) return const AsyncLoadingView();
                if (provider.error != null) {
                  return AsyncErrorView(
                    message: provider.error!,
                    onRetry: provider.loadFirst,
                  );
                }
                if (provider.items.isEmpty) {
                  return const AsyncEmptyView(message: 'Belum ada pengguna.');
                }
                _moreCalled = false;
                return RefreshIndicator(
                  onRefresh: provider.loadFirst,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.items.length + 1,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == provider.items.length) {
                        return _loadMore(provider);
                      }
                      final user = provider.items[index];
                      final roleTone = switch (user.role) {
                        UserRole.admin => BadgeTone.red,
                        UserRole.operator => BadgeTone.blue,
                        UserRole.viewer => BadgeTone.gray,
                      };
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.emerald500,
                                AppColors.blue600,
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppStatusBadge(
                              label: user.role.wire,
                              tone: roleTone,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openForm(user),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _delete(user),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadMore(UserManagementProvider provider) {
    if (provider.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.hasMore && !_moreCalled) {
      _moreCalled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => provider.loadMore());
    }
    return const SizedBox.shrink();
  }
}

/// Mutable holder for user form values (shared via a ChangeNotifier-free class).
class UserFormData {
  UserFormData({this.user});

  final UserModel? user;

  late String name = user?.name ?? '';
  late String email = user?.email ?? '';
  late UserRole role = user?.role ?? UserRole.operator;
  String password = '';
}

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({super.key, required this.data});

  final UserFormData data;

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.data.name,
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.data.email,
  );
  late final TextEditingController _password = TextEditingController();
  late UserRole _role = widget.data.role;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.data.user == null ? 'Tambah Pengguna' : 'Ubah Pengguna',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Email wajib diisi'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Peran',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                ),
                items: [
                  for (final r in UserRole.values)
                    DropdownMenuItem(value: r, child: Text(r.wire)),
                ],
                onChanged: (v) => setState(() => _role = v ?? _role),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: widget.data.user == null
                      ? 'Kata Sandi'
                      : 'Kata Sandi (kosongkan jika tidak diubah)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: widget.data.user == null
                    ? (v) => (v == null || v.isEmpty)
                          ? 'Kata sandi wajib diisi'
                          : null
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            widget.data.name = _name.text.trim();
            widget.data.email = _email.text.trim();
            widget.data.role = _role;
            widget.data.password = _password.text;
            Navigator.pop(context, true);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
