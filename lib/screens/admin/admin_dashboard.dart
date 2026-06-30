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
import '../../core/widgets/logout_confirmation_dialog.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/statistics_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/laporan_pembayaran_model.dart';

class AdminDashboardMain extends ConsumerStatefulWidget {
  const AdminDashboardMain({super.key});

  @override
  ConsumerState<AdminDashboardMain> createState() => _AdminDashboardMainState();
}

class _AdminDashboardMainState extends ConsumerState<AdminDashboardMain> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Dashboard SP3A',
    'Kelola Pengguna',
    'Laporan Keuangan',
    'Pengaturan',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      const _StatistikView(),
      const _ManageUsersView(),
      const _LaporanView(),
      const _SettingsView(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentIndex == 0 ? 'Dashboard SP3A' : _titles[_currentIndex],
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.5,
                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
              ),
            ),
            if (_currentIndex == 0)
              Text(
                'Halo, Admin',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? AppColors.textDarkSecondary.withAlpha(128) : AppColors.textLightSecondary.withAlpha(128),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded, size: 22),
              activeIcon: Icon(Icons.dashboard_rounded, size: 22),
              label: 'Statistik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded, size: 22),
              activeIcon: Icon(Icons.people_alt_rounded, size: 22),
              label: 'Pelanggan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded, size: 22),
              activeIcon: Icon(Icons.receipt_long_rounded, size: 22),
              label: 'Laporan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded, size: 22),
              activeIcon: Icon(Icons.settings_rounded, size: 22),
              label: 'Pengaturan',
            ),
          ],
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class _SettingsView extends ConsumerWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Summary Card
          CustomCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withAlpha(20),
                  child: Text(
                    authState.user?.namaLengkap.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.user?.namaLengkap ?? 'Admin',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      const StatusBadge(status: 'ADMIN'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Settings Options
          CustomCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.payments_rounded, color: AppColors.primary),
                  title: const Text('Kelola Tarif Air', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Atur tarif air m³ untuk Rumah Tangga & Bisnis', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageTarifScreen(),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.error)),
                  subtitle: const Text('Keluar dari sesi admin saat ini', style: TextStyle(fontSize: 12)),
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => const LogoutConfirmationDialog(),
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

class ManageTarifScreen extends StatelessWidget {
  const ManageTarifScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: Text(
          'Kelola Tarif Air',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
        ),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: _ManageTarifView(),
              ),
            ],
          ),
        ),
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
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
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
              width: 190,
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
                  initialValue: _role,
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
                    initialValue: _tipePelanggan,
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
}// --- SUB-VIEW: Laporan Keuangan ---
class _LaporanView extends ConsumerStatefulWidget {
  const _LaporanView();

  @override
  ConsumerState<_LaporanView> createState() => _LaporanViewState();
}

class _LaporanViewState extends ConsumerState<_LaporanView> {
  String _selectedFilter = 'Semua';
  List<LaporanPembayaran> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLaporan();
  }

  Future<void> _fetchLaporan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      var query = supabase.from('view_laporan_pembayaran').select();

      if (_selectedFilter != 'Semua') {
        query = query.eq('tipe_pelanggan', _selectedFilter);
      }

      final response = await query.order('waktu_bayar', ascending: false);

      final reports = (response as List)
          .map((json) => LaporanPembayaran.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isDark,
  }) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        if (_selectedFilter != value) {
          setState(() {
            _selectedFilter = value;
          });
          _fetchLaporan();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0EA5E9)
              : (isDark ? AppColors.borderDark : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0EA5E9)
                : (isDark ? Colors.grey[700]! : Colors.transparent),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    double totalIncome = 0;
    int totalTx = 0;
    for (var r in _reports) {
      if (r.statusPembayaran.toLowerCase() == 'sukses') {
        totalIncome += r.jumlahBayar;
        totalTx++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Laporan Pembayaran Air', style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('Analisis konsumsi pemakaian air bulanan dan rekapitulasi pembayaran.', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 13)),
        const SizedBox(height: 20),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(label: 'Semua Tipe', value: 'Semua', isDark: isDark),
              const SizedBox(width: 10),
              _buildFilterChip(label: 'Rumah Tangga', value: 'rumah_tangga', isDark: isDark),
              const SizedBox(width: 10),
              _buildFilterChip(label: 'Bisnis', value: 'bisnis', isDark: isDark),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_isLoading) ...[
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ] else if (_errorMessage != null) ...[
          Expanded(child: Center(child: Text('Gagal memuat laporan: $_errorMessage', style: const TextStyle(color: AppColors.error)))),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: CustomCard(
                  color: AppColors.primary.withAlpha(10),
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
              Expanded(
                child: CustomCard(
                  color: AppColors.secondary.withAlpha(10),
                  hasBorder: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary)),
                      const SizedBox(height: 12),
                      Text('$totalTx Lunas', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('Jumlah pembayaran berhasil', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: CustomCard(
                  color: AppColors.warning.withAlpha(10),
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
          Text('Rincian Pembayaran Pelanggan', style: theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: _reports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, color: isDark ? Colors.grey[700] : Colors.grey[300], size: 48),
                        const SizedBox(height: 12),
                        Text('Tidak ada rincian pembayaran ditemukan.', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final r = _reports[index];
                      final dateStr = r.waktuBayar != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(r.waktuBayar!)
                          : '-';
                      final isBisnis = r.tipePelanggan.toLowerCase() == 'bisnis';

                      return Card(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        surfaceTintColor: isDark ? AppColors.cardDark : Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark ? AppColors.borderDark : Colors.grey.withAlpha(25),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isBisnis
                                      ? Colors.orange.withAlpha(20)
                                      : Colors.blue.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isBisnis
                                      ? Icons.business_rounded
                                      : Icons.home_rounded,
                                  color: isBisnis ? Colors.orange : Colors.blue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            r.namaPelanggan.isNotEmpty ? r.namaPelanggan : '-',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isBisnis
                                                ? Colors.orange.withAlpha(25)
                                                : Colors.blue.withAlpha(25),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isBisnis ? 'Bisnis' : 'Rumah Tangga',
                                            style: TextStyle(
                                              color: isBisnis ? Colors.orange[800] : Colors.blue[800],
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Waktu Bayar: $dateStr',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Metode: ${r.metodePembayaran.toUpperCase()} • Periode: Bulan ${r.periodeBulan} - ${r.periodeTahun}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textDarkSecondary.withAlpha(180) : AppColors.textLightSecondary.withAlpha(180),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                formatter.format(r.jumlahBayar),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isBisnis ? Colors.orange[700] : const Color(0xFF0EA5E9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}

class _StatistikView extends ConsumerStatefulWidget {
  const _StatistikView();

  @override
  ConsumerState<_StatistikView> createState() => _StatistikViewState();
}

class _StatistikViewState extends ConsumerState<_StatistikView> {
  bool _showRevenue = false;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statisticsProvider);
    final customersAsync = ref.watch(pelangganListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive Wrap Header (Title + Toggle Option)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistik Pemakaian & Pendapatan',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grafik perbandingan kategori Rumah Tangga dan Bisnis 6 bulan terakhir.',
                    style: TextStyle(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.inputBgDark : AppColors.inputBgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleOption(
                      label: 'Air (m³)',
                      isSelected: !_showRevenue,
                      onTap: () => setState(() => _showRevenue = false),
                      isDark: isDark,
                    ),
                    _buildToggleOption(
                      label: 'Pendapatan',
                      isSelected: _showRevenue,
                      onTap: () => setState(() => _showRevenue = true),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Main Chart Card
          statsAsync.when(
            data: (stats) {
              if (stats.isEmpty) {
                return const CustomCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('Data statistik belum tersedia.'),
                    ),
                  ),
                );
              }

              final List<FlSpot> spotsRT = [];
              final List<FlSpot> spotsBisnis = [];

              for (int i = 0; i < stats.length; i++) {
                final stat = stats[i];
                final valRT = _showRevenue ? stat.rumahTanggaPendapatan : stat.rumahTanggaPemakaian;
                final valBisnis = _showRevenue ? stat.bisnisPendapatan : stat.bisnisPemakaian;
                spotsRT.add(FlSpot(i.toDouble(), valRT));
                spotsBisnis.add(FlSpot(i.toDouble(), valBisnis));
              }

              double maxVal = 0;
              for (var s in stats) {
                final rt = _showRevenue ? s.rumahTanggaPendapatan : s.rumahTanggaPemakaian;
                final b = _showRevenue ? s.bisnisPendapatan : s.bisnisPemakaian;
                if (rt > maxVal) maxVal = rt;
                if (b > maxVal) maxVal = b;
              }
              maxVal = maxVal == 0 ? 10 : maxVal * 1.2;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomCard(
                    padding: const EdgeInsets.fromLTRB(24, 32, 32, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _showRevenue ? 'Total Pendapatan (Tagihan Lunas)' : 'Total Volume Pemakaian Air',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AspectRatio(
                          aspectRatio: 1.7,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: _showRevenue ? 65 : 40,
                                    getTitlesWidget: (value, meta) {
                                      if (value == meta.max || value == meta.min) {
                                        return const SizedBox();
                                      }
                                      final text = _showRevenue
                                          ? (value >= 1000000 
                                              ? '${(value / 1000000).toStringAsFixed(1)}M' 
                                              : (value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}K' : value.toStringAsFixed(0)))
                                          : value.toStringAsFixed(0);
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Text(
                                          text,
                                          style: TextStyle(
                                            color: isDark ? AppColors.textDarkSecondary.withAlpha(150) : AppColors.textLightSecondary.withAlpha(150),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < stats.length) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          space: 10,
                                          child: Text(
                                            stats[index].monthLabel,
                                            style: TextStyle(
                                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                              ),
                              minY: 0,
                              maxY: maxVal,
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (touchedSpot) => isDark ? AppColors.cardDark : Colors.white,
                                  tooltipBorder: BorderSide(
                                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    width: 1,
                                  ),
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((barSpot) {
                                      final val = barSpot.y;
                                      final label = barSpot.barIndex == 0 ? 'Rumah Tangga' : 'Bisnis';
                                      final unit = _showRevenue ? currencyFormatter.format(val) : '${val.toStringAsFixed(1)} m³';
                                      return LineTooltipItem(
                                        '$label: $unit',
                                        TextStyle(
                                          color: barSpot.barIndex == 0 ? AppColors.primary : AppColors.warning,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spotsRT,
                                  isCurved: true,
                                  color: AppColors.primary,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withAlpha(40),
                                        AppColors.primary.withAlpha(0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                LineChartBarData(
                                  spots: spotsBisnis,
                                  isCurved: true,
                                  color: AppColors.warning,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.warning.withAlpha(40),
                                        AppColors.warning.withAlpha(0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem('Rumah Tangga', AppColors.primary),
                            const SizedBox(width: 24),
                            _buildLegendItem('Bisnis', AppColors.warning),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const CustomCard(
              child: SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, _) => CustomCard(
              child: SizedBox(
                height: 150,
                child: Center(
                  child: Text('Gagal memuat statistik: $err', style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          customersAsync.when(
            data: (customers) {
              final countRT = customers.where((c) => c.tipePelanggan == TipePelanggan.rumahTangga).length;
              final countBisnis = customers.where((c) => c.tipePelanggan == TipePelanggan.bisnis).length;

              return Row(
                children: [
                  Expanded(
                    child: CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Rumah Tangga',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$countRT User Aktif',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.business_rounded, color: AppColors.warning, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Bisnis',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$countBisnis User Aktif',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(),
            error: (e, _) => const SizedBox(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.cardDark : Colors.white) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary)
                : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

