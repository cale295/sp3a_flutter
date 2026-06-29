import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sp3a_projek/core/constants/supabase_constants.dart';
import 'package:sp3a_projek/core/theme/app_theme.dart';
import 'package:sp3a_projek/core/theme/app_colors.dart';
import 'package:sp3a_projek/core/widgets/primary_button.dart';
import 'package:sp3a_projek/providers/auth_provider.dart';
import 'package:sp3a_projek/models/user_model.dart';
import 'package:sp3a_projek/screens/auth/login_screen.dart';
import 'package:sp3a_projek/screens/auth/change_password_screen.dart';
import 'package:sp3a_projek/screens/admin/admin_dashboard.dart';
import './screens/petugas/petugas_dashboard.dart';
import 'package:sp3a_projek/screens/pelanggan/pelanggan_dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize locale data for Indonesian formatting
  await initializeDateFormatting('id_ID', null);
  
  // Load environment variables before initializing Supabase
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Failed to load .env: $e");
  }

  // ===== INISIALISASI FIREBASE TAMBAHKAN DI SINI =====
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase berhasil dinyalakan!");
  } catch (e) {
    debugPrint("Gagal menyalakan Firebase: $e");
  }
  // ===================================================

  bool isSupabaseInitialized = false;
  String? initError;

  try {
    // Try to initialize Supabase. If credentials are placeholders, this may fail on launch.
    final url = SupabaseConstants.url.trim();
    final key = SupabaseConstants.anonKey.trim();

    if (url.isNotEmpty && key.isNotEmpty) {
      await Supabase.initialize(
        url: url,
        anonKey: key, // Note: gw ubah publishableKey jadi anonKey karena standar supabase_flutter pakai ini
      );
      isSupabaseInitialized = true;
    } else {
      initError = "SUPABASE_URL atau SUPABASE_ANON_KEY belum dikonfigurasi.";
    }
  } catch (e) {
    initError = e.toString();
  }

  runApp(
    ProviderScope(
      child: SP3AApp(
        isInitialized: isSupabaseInitialized,
        initializationError: initError,
      ),
    ),
  );
}

class SP3AApp extends ConsumerWidget {
  final bool isInitialized;
  final String? initializationError;

  const SP3AApp({
    super.key,
    required this.isInitialized,
    this.initializationError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SP3A - Sistem Pembayaran Air',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: !isInitialized
          ? _UnconfiguredFallbackScreen(errorMessage: initializationError)
          : const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // 1. Loading state
    if (authState.isLoading && authState.user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. Unauthenticated -> Login
    if (!authState.isAuthenticated || authState.user == null) {
      return const LoginScreen();
    }

    final user = authState.user!;

    // 3. First Login -> Force Change Password
    if (user.isFirstLogin) {
      return const ChangePasswordScreen();
    }

    // 4. Role-based Navigation
    switch (user.role) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.petugas:
        return const PetugasDashboard();
      case UserRole.pelanggan:
        return const PelangganDashboard();
    }
  }
}

// Fallback Screen when Supabase credentials are not set
class _UnconfiguredFallbackScreen extends StatelessWidget {
  final String? errorMessage;

  const _UnconfiguredFallbackScreen({this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.settings_suggest_rounded,
                  size: 64,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 24),
                Text(
                  'Konfigurasi Diperlukan',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Selamat datang di SP3A! Untuk mengaktifkan sinkronisasi database, harap edit file kredensial Anda di:',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withAlpha(51)),
                  ),
                  child: const SelectableText(
                    'lib/core/constants/supabase_constants.dart',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Detail Error:\n$errorMessage',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 32),
                // Demo Quick-Start button
                PrimaryButton(
                  text: 'Jalankan Sebagai Demo',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    // Force start app by setting mock credentials or bypassing
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const _DemoModeGateway(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Demo Bypass Gateway to inspect/play with the dashboards offline
class _DemoModeGateway extends StatefulWidget {
  const _DemoModeGateway();

  @override
  State<_DemoModeGateway> createState() => _DemoModeGatewayState();
}

class _DemoModeGatewayState extends State<_DemoModeGateway> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SP3A Demo Gateways'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app_rounded, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text('Masuk langsung ke salah satu Role Dashboard untuk uji coba:', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _DemoCard(
                    title: 'ADMIN PORTAL',
                    subtitle: 'Web Sidebar, CRUD, Tarif, Laporan View',
                    icon: Icons.admin_panel_settings_rounded,
                    color: AppColors.primary,
                    onTap: () {
                      _launchDemo(
                        context,
                        UserModel(
                          id: 'demo-admin-id',
                          username: 'admin_demo',
                          role: UserRole.admin,
                          namaLengkap: 'Pak Ahmad (Admin)',
                          alamat: 'Kantor SP3A Pusat',
                          tipePelanggan: TipePelanggan.rumahTangga,
                          isFirstLogin: false,
                        ),
                      );
                    },
                  ),
                  _DemoCard(
                    title: 'PETUGAS PORTAL',
                    subtitle: 'Mobile Bottom Nav, Daftar Pelanggan, OCR Reading',
                    icon: Icons.directions_run_rounded,
                    color: AppColors.secondary,
                    onTap: () {
                      _launchDemo(
                        context,
                        UserModel(
                          id: 'demo-petugas-id',
                          username: 'petugas_demo',
                          role: UserRole.petugas,
                          namaLengkap: 'Budi Hartono (Petugas)',
                          alamat: 'Pos Lapangan Wilayah A',
                          tipePelanggan: TipePelanggan.rumahTangga,
                          isFirstLogin: false,
                        ),
                      );
                    },
                  ),
                  _DemoCard(
                    title: 'PELANGGAN PORTAL',
                    subtitle: 'Billing Card, Mock Payment Gateways, Payment History',
                    icon: Icons.person_rounded,
                    color: AppColors.warning,
                    onTap: () {
                      _launchDemo(
                        context,
                        UserModel(
                          id: 'demo-pelanggan-id',
                          username: 'pelanggan_demo',
                          role: UserRole.pelanggan,
                          namaLengkap: 'Ibu Ratna (Pelanggan)',
                          alamat: 'Perumahan Lestari Indah Blok B/12',
                          tipePelanggan: TipePelanggan.rumahTangga,
                          isFirstLogin: false,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchDemo(BuildContext context, UserModel mockUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderScope(
          overrides: [
            // Overriding authState to mock selection directly
            authProvider.overrideWith((ref) => _MockAuthNotifier(mockUser)),
          ],
          child: const _AuthGate(),
        ),
      ),
    );
  }
}

class _MockAuthNotifier extends AuthNotifier {
  final UserModel mockUser;
  _MockAuthNotifier(this.mockUser) {
    state = AuthState(user: mockUser, isAuthenticated: true, isLoading: false);
  }

  @override
  Future<void> signIn(String identifier, String password) async {}
  @override
  Future<void> fetchUserProfile(String userId) async {}
  @override
  Future<bool> changePassword(String newPassword) async => true;
  @override
  Future<void> signOut() async {
    state = AuthState(isAuthenticated: false);
  }
}

class _DemoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DemoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withAlpha(26),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
