import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/input_field.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/user_model.dart';
import '../../models/tarif_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../services/admin_auth_service.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedMenuIndex = 0; // 0: Users, 1: Tarif, 2: Laporan

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Kelola Pengguna', 'icon': Icons.people_alt_rounded},
    {'title': 'Kelola Tarif', 'icon': Icons.payments_rounded},
    {'title': 'Laporan Keuangan', 'icon': Icons.assessment_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;

    Widget body;
    switch (_selectedMenuIndex) {
      case 1:
        body = const _ManageTarifView();
        break;
      case 2:
        body = const _LaporanView();
        break;
      case 0:
      default:
        body = const _ManageUsersView();
        break;
    }

    Widget sidebar = Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SP3A Admin',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Sistem Pengelolaan Air',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textDarkSecondary.withOpacity(0.6) : AppColors.textLightSecondary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Profile Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDark.withOpacity(0.4) : AppColors.bgLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    child: Text(
                      authState.user?.namaLengkap.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.user?.namaLengkap ?? 'Admin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        const StatusBadge(status: 'ADMIN'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Menu Items
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedMenuIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: AppColors.primary.withOpacity(0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      item['icon'] as IconData,
                      size: 20,
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                    ),
                    title: Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
                        fontSize: 13.5,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedMenuIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              title: const Text('Keluar', style: TextStyle(color: AppColors.error, fontSize: 13.5, fontWeight: FontWeight.w600)),
              onTap: () => ref.read(authProvider.notifier).signOut(),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      drawer: isLargeScreen ? null : Drawer(child: sidebar),
      appBar: isLargeScreen
          ? null
          : AppBar(
              title: Text(_menuItems[_selectedMenuIndex]['title'] as String),
              elevation: 0,
            ),
      body: Row(
        children: [
          if (isLargeScreen) sidebar,
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SUB-VIEW: Kelola Pengguna ---
class _ManageUsersView extends ConsumerStatefulWidget {
  const _ManageUsersView();

  @override
  ConsumerState<_ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends ConsumerState<_ManageUsersView> {
  void _openAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => const _UserFormDialog(),
    ).then((_) => ref.invalidate(usersListProvider));
  }

  void _openEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => _UserFormDialog(user: user),
    ).then((_) => ref.invalidate(usersListProvider));
  }

  void _openResetPasswordDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => _ResetPasswordDialog(user: user),
    );
  }

  void _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus pengguna ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(databaseServiceProvider).deleteUser(id);
      ref.invalidate(usersListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daftar Pengguna', style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Kelola admin, petugas lapangan, dan pelanggan air.', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 13)),
              ],
            ),
            PrimaryButton(
              text: 'Tambah Pengguna',
              icon: Icons.person_add_alt_1_rounded,
              width: 180,
              onPressed: _openAddUserDialog,
            ),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: usersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const Center(child: Text('Tidak ada pengguna ditemukan.'));
              }
              return CustomCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(isDark ? Colors.black12 : AppColors.bgLight),
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 52,
                        horizontalMargin: 24,
                        columnSpacing: 36,
                        columns: const [
                          DataColumn(label: Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          DataColumn(label: Text('Tipe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          DataColumn(label: Text('Alamat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        ],
                        rows: users.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(Text(user.namaLengkap, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
                              DataCell(Text(user.username, style: const TextStyle(fontSize: 13))),
                              DataCell(StatusBadge(status: user.role.name)),
                              DataCell(Text(user.role == UserRole.pelanggan ? user.tipePelanggan.name.toUpperCase() : '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(user.alamat, maxLines: 1, style: const TextStyle(fontSize: 13))),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.lock_reset_rounded, color: AppColors.warning, size: 18),
                                      tooltip: 'Reset Password',
                                      onPressed: () => _openResetPasswordDialog(user),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                                      onPressed: () => _openEditUserDialog(user),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                      onPressed: () => _deleteUser(user.id),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading users: $err')),
          ),
        ),
      ],
    );
  }
}

// Dialog for password resetting
class _ResetPasswordDialog extends ConsumerStatefulWidget {
  final UserModel user;
  const _ResetPasswordDialog({required this.user});

  @override
  ConsumerState<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tempPasswordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _tempPasswordController.dispose();
    super.dispose();
  }

  void _reset() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final tempPassword = _tempPasswordController.text.trim();
        await ref.read(adminAuthServiceProvider).adminResetPassword(
              userId: widget.user.id,
              tempPassword: tempPassword,
            );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password berhasil direset. Silakan infokan password sementara kepada pengguna.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mereset password: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Atur password sementara untuk ${widget.user.namaLengkap} (${widget.user.username}). Pengguna akan dipaksa untuk mengganti password mereka pada login berikutnya.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                InputField(
                  label: 'Password Sementara Baru',
                  hint: 'Minimal 6 karakter',
                  controller: _tempPasswordController,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (v.trim().length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _reset,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Reset Password'),
        ),
      ],
    );
  }
}

// Dialog for user creation/edition
class _UserFormDialog extends ConsumerStatefulWidget {
  final UserModel? user;
  const _UserFormDialog({this.user});

  @override
  ConsumerState<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _usernameController;
  late TextEditingController _alamatController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late UserRole _role;
  late TipePelanggan _tipePelanggan;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.user?.namaLengkap ?? '');
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _alamatController = TextEditingController(text: widget.user?.alamat ?? '');
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _role = widget.user?.role ?? UserRole.pelanggan;
    _tipePelanggan = widget.user?.tipePelanggan ?? TipePelanggan.rumahTangga;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _alamatController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final username = _usernameController.text.trim();
        final database = ref.read(databaseServiceProvider);
        
        if (widget.user == null) {
          final adminAuthService = ref.read(adminAuthServiceProvider);
          final email = _emailController.text.trim();
          final password = _passwordController.text.trim();

          final newUser = UserModel(
            id: '', // Will be set with the generated auth UUID
            username: username,
            role: _role,
            namaLengkap: _namaController.text.trim(),
            alamat: _alamatController.text.trim(),
            tipePelanggan: _tipePelanggan,
            isFirstLogin: true,
          );

          await adminAuthService.createAuthUserAndProfile(
            user: newUser,
            email: email,
            password: password,
          );
        } else {
          final updatedUser = widget.user!.copyWith(
            username: username,
            role: _role,
            namaLengkap: _namaController.text.trim(),
            alamat: _alamatController.text.trim(),
            tipePelanggan: _tipePelanggan,
          );
          await database.updateUser(updatedUser);
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan pengguna: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.user == null ? 'Tambah Pengguna Baru' : 'Edit Pengguna';
    return AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InputField(
                  label: 'Nama Lengkap',
                  controller: _namaController,
                  validator: (v) => v!.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                InputField(
                  label: 'Username',
                  controller: _usernameController,
                  validator: (v) => v!.trim().isEmpty ? 'Username tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                InputField(
                  label: 'Alamat',
                  controller: _alamatController,
                  validator: (v) => v!.trim().isEmpty ? 'Alamat tidak boleh kosong' : null,
                ),
                if (widget.user == null) ...[
                  const SizedBox(height: 16),
                  InputField(
                    label: 'Email',
                    hint: 'Email untuk login (misal: budi@gmail.com)',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.trim().isEmpty ? 'Email tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    label: 'Password',
                    hint: 'Minimal 6 karakter',
                    controller: _passwordController,
                    isPassword: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (v.trim().length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Role Akses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<UserRole>(
                  value: _role,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.inputBgDark : AppColors.inputBgLight,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role.name.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _role = val;
                      });
                    }
                  },
                ),
                if (_role == UserRole.pelanggan) ...[
                  const SizedBox(height: 16),
                  const Text('Tipe Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<TipePelanggan>(
                    value: _tipePelanggan,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.inputBgDark : AppColors.inputBgLight,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items: TipePelanggan.values.map((tipe) {
                      return DropdownMenuItem(value: tipe, child: Text(tipe.name.replaceAll('rumahTangga', 'rumah_tangga').toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _tipePelanggan = val;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

// --- SUB-VIEW: Kelola Tarif ---
class _ManageTarifView extends ConsumerStatefulWidget {
  const _ManageTarifView();

  @override
  ConsumerState<_ManageTarifView> createState() => _ManageTarifViewState();
}

class _ManageTarifViewState extends ConsumerState<_ManageTarifView> {
  final _rtM3Controller = TextEditingController();
  final _rtAbodemenController = TextEditingController();
  final _rtDendaController = TextEditingController();
  final _bisnisM3Controller = TextEditingController();
  final _bisnisAbodemenController = TextEditingController();
  final _bisnisDendaController = TextEditingController();
  
  bool _isSaving = false;
  List<TarifModel> _tarifs = [];

  void _loadTarifs(List<TarifModel> data) {
    if (_tarifs.isEmpty && data.isNotEmpty) {
      _tarifs = data;
      for (var t in data) {
        if (t.tipePelanggan == TipePelanggan.rumahTangga) {
          _rtM3Controller.text = t.hargaPerM3.toString();
          _rtAbodemenController.text = t.biayaAbodemen.toString();
          _rtDendaController.text = t.dendaPerBulan.toString();
        } else if (t.tipePelanggan == TipePelanggan.bisnis) {
          _bisnisM3Controller.text = t.hargaPerM3.toString();
          _bisnisAbodemenController.text = t.biayaAbodemen.toString();
          _bisnisDendaController.text = t.dendaPerBulan.toString();
        }
      }
    }
  }

  void _saveTarifs() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final db = ref.read(databaseServiceProvider);
      for (var t in _tarifs) {
        if (t.tipePelanggan == TipePelanggan.rumahTangga) {
          final updated = t.copyWith(
            hargaPerM3: double.parse(_rtM3Controller.text),
            biayaAbodemen: double.parse(_rtAbodemenController.text),
            dendaPerBulan: double.parse(_rtDendaController.text),
          );
          await db.updateTarif(updated);
        } else if (t.tipePelanggan == TipePelanggan.bisnis) {
          final updated = t.copyWith(
            hargaPerM3: double.parse(_bisnisM3Controller.text),
            biayaAbodemen: double.parse(_bisnisAbodemenController.text),
            dendaPerBulan: double.parse(_bisnisDendaController.text),
          );
          await db.updateTarif(updated);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarif berhasil diperbarui!'), backgroundColor: AppColors.success),
        );
      }
      ref.invalidate(tarifsListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _rtM3Controller.dispose();
    _rtAbodemenController.dispose();
    _rtDendaController.dispose();
    _bisnisM3Controller.dispose();
    _bisnisAbodemenController.dispose();
    _bisnisDendaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tarifsAsync = ref.watch(tarifsListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    tarifsAsync.whenData(_loadTarifs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kelola Tarif Air', style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('Atur harga per meter kubik (m³), biaya abodemen, dan denda keterlambatan berdasarkan tipe pelanggan.', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 13)),
        const SizedBox(height: 32),
        if (tarifsAsync.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rumah Tangga Card
                        Expanded(
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.home_rounded, color: AppColors.primary, size: 24),
                                    const SizedBox(width: 12),
                                    Text('Rumah Tangga', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                InputField(
                                  label: 'Harga per m³ (IDR)',
                                  controller: _rtM3Controller,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                                const SizedBox(height: 16),
                                InputField(
                                  label: 'Biaya Abodemen (IDR)',
                                  controller: _rtAbodemenController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                                const SizedBox(height: 16),
                                InputField(
                                  label: 'Denda Keterlambatan / Bulan (IDR)',
                                  controller: _rtDendaController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Bisnis Card
                        Expanded(
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.business_rounded, color: AppColors.secondary, size: 24),
                                    const SizedBox(width: 12),
                                    Text('Bisnis / Komersial', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                InputField(
                                  label: 'Harga per m³ (IDR)',
                                  controller: _bisnisM3Controller,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                                const SizedBox(height: 16),
                                InputField(
                                  label: 'Biaya Abodemen (IDR)',
                                  controller: _bisnisAbodemenController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                                const SizedBox(height: 16),
                                InputField(
                                  label: 'Denda Keterlambatan / Bulan (IDR)',
                                  controller: _bisnisDendaController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: PrimaryButton(
                        text: 'Simpan Perubahan Tarif',
                        isLoading: _isSaving,
                        width: 240,
                        onPressed: _saveTarifs,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// --- SUB-VIEW: Laporan Keuangan ---
class _LaporanView extends ConsumerWidget {
  const _LaporanView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(laporanProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Laporan Pembayaran Air', style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('Analisis konsumsi pemakaian air bulanan dan rekapitulasi pembayaran.', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 13)),
        const SizedBox(height: 32),
        reportsAsync.when(
          data: (reports) {
            double totalIncome = 0;
            int totalVolume = 0;
            int totalTx = 0;
            for (var r in reports) {
              final valIncome = r['total_pendapatan'];
              final valVolume = r['total_pemakaian_m3'];
              final valTx = r['jumlah_transaksi'];
              
              if (valIncome != null) {
                totalIncome += (valIncome as num).toDouble();
              }
              if (valVolume != null) {
                totalVolume += (valVolume as num).toInt();
              }
              if (valTx != null) {
                totalTx += (valTx as num).toInt();
              }
            }

            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Card 1
                      Expanded(
                        child: CustomCard(
                          color: AppColors.primary.withOpacity(0.04),
                          hasBorder: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Pendapatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                              const SizedBox(height: 12),
                              Text(formatter.format(totalIncome), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Text('Dari $totalTx transaksi lunas', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Card 2
                      Expanded(
                        child: CustomCard(
                          color: AppColors.secondary.withOpacity(0.04),
                          hasBorder: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pemakaian Air Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary)),
                              const SizedBox(height: 12),
                              Text('$totalVolume m³', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Text('Konsumsi keseluruhan pelanggan', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Card 3
                      Expanded(
                        child: CustomCard(
                          color: AppColors.warning.withOpacity(0.04),
                          hasBorder: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Rata-rata Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warning)),
                              const SizedBox(height: 12),
                              Text(formatter.format(totalTx > 0 ? totalIncome / totalTx : 0), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Text('Nilai rata-rata tagihan lunas', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text('Rincian Rekapitulasi Bulanan', style: theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: CustomCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(isDark ? Colors.black12 : AppColors.bgLight),
                            dataRowMinHeight: 52,
                            dataRowMaxHeight: 52,
                            horizontalMargin: 24,
                            columns: const [
                              DataColumn(label: Text('Periode Bulan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              DataColumn(label: Text('Tahun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              DataColumn(label: Text('Total Pemakaian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              DataColumn(label: Text('Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              DataColumn(label: Text('Total Pendapatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            ],
                            rows: reports.map((r) {
                              final int totalPemakaian = (r['total_pemakaian_m3'] as num?)?.toInt() ?? 0;
                              final int jmlTransaksi = (r['jumlah_transaksi'] as num?)?.toInt() ?? 0;
                              final double totalPendapatan = (r['total_pendapatan'] as num?)?.toDouble() ?? 0.0;
                              
                              return DataRow(
                                cells: [
                                  DataCell(Text(r['bulan'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
                                  DataCell(Text((r['tahun'] ?? '').toString(), style: const TextStyle(fontSize: 13))),
                                  DataCell(Text('$totalPemakaian m³', style: const TextStyle(fontSize: 13))),
                                  DataCell(Text('$jmlTransaksi kali', style: const TextStyle(fontSize: 13))),
                                  DataCell(Text(formatter.format(totalPendapatan), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading reports: $err')),
        ),
      ],
    );
  }
}
