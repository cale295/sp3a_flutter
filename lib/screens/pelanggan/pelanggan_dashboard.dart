import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/tagihan_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tagihan_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/pencatatan_provider.dart';

class PelangganDashboard extends ConsumerStatefulWidget {
  const PelangganDashboard({super.key});

  @override
  ConsumerState<PelangganDashboard> createState() => _PelangganDashboardState();
}

class _PelangganDashboardState extends ConsumerState<PelangganDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final customer = authState.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (customer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> pages = [
      _HomeTab(
        customerId: customer.id,
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      _BillsTab(customerId: customer.id),
      _HistoryTab(customerId: customer.id),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black.withAlpha(10),
        toolbarHeight: 64, // Slightly taller for easier interaction
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.namaLengkap,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Pelanggan ${customer.tipePelanggan.name == 'rumahTangga' ? 'Rumah Tangga' : 'Bisnis'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Logout with explicit label for accessibility
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
              label: const Text(
                'Keluar',
                style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 44),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 68, // Generous height for senior tap targets
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: isDark
                  ? AppColors.textDarkSecondary.withAlpha(130)
                  : AppColors.textLightSecondary.withAlpha(150),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11.5),
              type: BottomNavigationBarType.fixed,
              iconSize: 24,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Beranda', // Always visible label
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Tagihan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded),
                  activeIcon: Icon(Icons.history_rounded),
                  label: 'Riwayat',
                ),
              ],
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: HOME (BERANDA)
// ==========================================
class _HomeTab extends ConsumerWidget {
  final String customerId;
  final ValueChanged<int>? onTabChange;

  const _HomeTab({
    required this.customerId,
    this.onTabChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(customerReadingsProvider(customerId));
    final authState = ref.watch(authProvider);
    final userType = authState.user?.tipePelanggan ?? TipePelanggan.rumahTangga;
    final tarifAsync = ref.watch(tarifForTipeProvider(userType));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final literFormatter = NumberFormat.decimalPattern('id_ID');
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(customerReadingsProvider(customerId));
        ref.invalidate(tarifForTipeProvider(userType));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Welcome Banner ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(60),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'SP3A — Portal Pelanggan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pantau air, bayar mudah.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cek pemakaian & tagihan air Anda kapan saja secara online.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Pencatatan meter dilakukan oleh Petugas — info chip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withAlpha(60)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_rounded, color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Meter dicatat oleh Petugas SP3A',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Section: Pemakaian Air ───────────────────────────────────
            Text(
              'Pemakaian Air',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Akumulasi total pemakaian seluruh periode',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: 14),

            readingsAsync.when(
              data: (readings) {
                int totalUsage = 0;
                int latestUsage = 0;
                double? trendPercent;

                if (readings.isNotEmpty) {
                  for (int i = 0; i < readings.length; i++) {
                    final cur = readings[i].angkaMeteran;
                    final prev = (i + 1 < readings.length) ? readings[i + 1].angkaMeteran : 0;
                    final u = cur - prev;
                    if (u > 0) totalUsage += u;
                  }
                  // Latest month usage (first record diff)
                  if (readings.length >= 2) {
                    latestUsage = readings[0].angkaMeteran - readings[1].angkaMeteran;
                    if (latestUsage < 0) latestUsage = 0;
                    // Previous month usage
                    if (readings.length >= 3) {
                      final prevUsage = readings[1].angkaMeteran - readings[2].angkaMeteran;
                      if (prevUsage > 0) {
                        trendPercent = ((latestUsage - prevUsage) / prevUsage) * 100;
                      }
                    }
                  } else if (readings.length == 1) {
                    latestUsage = readings[0].angkaMeteran;
                  }
                }

                return Column(
                  children: [
                    // Main usage card — hero metric, large readable value
                    CustomCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.water_drop_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Pemakaian',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textDarkSecondary
                                            : AppColors.textLightSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Semua periode',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.textDarkSecondary.withAlpha(140)
                                            : AppColors.textLightSecondary.withAlpha(140),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Prominently large, bold metric value
                          Text(
                            '$totalUsage m³',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 48, // Hero metric — highly visible
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                              letterSpacing: -2,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Conversion with clear separation
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '≈ ${literFormatter.format(totalUsage * 1000)} Liter',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Two sub-metric cards: latest usage + trend
                    Row(
                      children: [
                        Expanded(
                          child: CustomCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bulan Ini',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textDarkSecondary
                                        : AppColors.textLightSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$latestUsage m³',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28, // Large secondary metric
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: -0.8,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${literFormatter.format(latestUsage * 1000)} L',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textDarkSecondary
                                        : AppColors.textLightSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (trendPercent != null)
                          Expanded(
                            child: CustomCard(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tren Bulan Ini',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textDarkSecondary
                                          : AppColors.textLightSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${trendPercent >= 0 ? '+' : ''}${trendPercent.toStringAsFixed(0)}%',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: trendPercent > 0 ? AppColors.error : AppColors.success,
                                      letterSpacing: -0.8,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        trendPercent > 0
                                            ? Icons.trending_up_rounded
                                            : Icons.trending_down_rounded,
                                        size: 14,
                                        color: trendPercent > 0 ? AppColors.error : AppColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'dibanding bulan lalu',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.textDarkSecondary
                                                : AppColors.textLightSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Gagal memuat pemakaian: $err',
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Section: Aksi Cepat ──────────────────────────────────────
            Text(
              'Aksi Cepat',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    title: 'Bayar Tagihan',
                    subtitle: 'Lihat tagihan aktif',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.success,
                    isDark: isDark,
                    onTap: () => onTabChange?.call(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    title: 'Riwayat',
                    subtitle: 'Cek transaksi',
                    icon: Icons.history_rounded,
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                    onTap: () => onTabChange?.call(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Section: Informasi Tarif ─────────────────────────────────
            tarifAsync.when(
              data: (tarif) {
                final rate = tarif.hargaPerM3;
                final abodemen = tarif.biayaAbodemen;
                final denda = tarif.dendaPerBulan;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Tarif Aktif',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    CustomCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userType == TipePelanggan.rumahTangga
                                          ? 'Tarif Rumah Tangga'
                                          : 'Tarif Bisnis',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Tarif resmi berlaku saat ini',
                                      style: TextStyle(fontSize: 12, color: AppColors.textLightSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const StatusBadge(status: 'aktif'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow(
                            'Harga Air / m³',
                            currencyFormatter.format(rate),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Biaya Abodemen',
                            currencyFormatter.format(abodemen),
                            isDark: isDark,
                          ),
                          if (denda > 0) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Denda Keterlambatan / Bln',
                              currencyFormatter.format(denda),
                              isDark: isDark,
                              valueColor: AppColors.error,
                            ),
                          ],
                          const SizedBox(height: 16),
                          DashedDivider(
                            height: 1.5,
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            dashWidth: 5,
                            dashGap: 3,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.tips_and_updates_outlined,
                                color: AppColors.warning,
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Catatan: Biaya abodemen dibebankan jika pemakaian air 0 m³ pada bulan terkait. Jika pemakaian > 0 m³, biaya abodemen dibebaskan.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: isDark
                                        ? AppColors.textDarkSecondary
                                        : AppColors.textLightSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('Gagal memuat informasi tarif: $err',
                      style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Button Card ─────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textDarkSecondary.withAlpha(160)
                  : AppColors.textLightSecondary.withAlpha(160),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 2: TAGIHAN (BILLS) — Fintech-style receipt
// ==========================================
class _BillsTab extends ConsumerWidget {
  final String customerId;
  const _BillsTab({required this.customerId});

  void _openPaymentSheet(BuildContext context, WidgetRef ref, TagihanModel bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentGatewaySheet(bill: bill),
    ).then((success) {
      if (success == true) {
        ref.invalidate(activeTagihanProvider(customerId));
        ref.invalidate(paymentHistoryProvider(customerId));
        ref.invalidate(customerReadingsProvider(customerId));
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTagihanAsync = ref.watch(activeTagihanProvider(customerId));
    final authState = ref.watch(authProvider);
    final userType = authState.user?.tipePelanggan ?? TipePelanggan.rumahTangga;
    final tarifAsync = ref.watch(tarifForTipeProvider(userType));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeTagihanProvider(customerId));
        ref.invalidate(tarifForTipeProvider(userType));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tagihan Aktif',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Detail tagihan dan pembayaran bulan ini',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: 16),
            activeTagihanAsync.when(
              data: (bill) {
                if (bill == null) {
                  return _buildAllClearCard(isDark);
                }

                return tarifAsync.when(
                  data: (tarif) {
                    final rate = tarif.hargaPerM3;
                    final abodemen = tarif.biayaAbodemen;
                    final calculatedTotal = bill.pemakaianM3 == 0
                        ? abodemen
                        : (bill.pemakaianM3 * rate);
                    final totalBayar = calculatedTotal + bill.totalDenda;

                    return _buildBillReceipt(
                      context: context,
                      ref: ref,
                      bill: bill,
                      rate: rate,
                      abodemen: abodemen,
                      calculatedTotal: calculatedTotal,
                      totalBayar: totalBayar,
                      formatter: formatter,
                      isDark: isDark,
                    );
                  },
                  loading: () => const Center(
                    child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Gagal memuat tarif: $err',
                          style: const TextStyle(color: AppColors.error)),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal memuat tagihan: $err',
                      style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllClearCard(bool isDark) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Semua Tagihan Lunas!',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Terima kasih atas pembayaran tepat waktu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillReceipt({
    required BuildContext context,
    required WidgetRef ref,
    required TagihanModel bill,
    required double rate,
    required double abodemen,
    required double calculatedTotal,
    required double totalBayar,
    required NumberFormat formatter,
    required bool isDark,
  }) {
    return Column(
      children: [
        // ── Digital Receipt Card ─────────────────────────────────────────
        CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Receipt header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withAlpha(30)
                      : AppColors.primary.withAlpha(15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tagihan Air Bulan Ini',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No. Tagihan: #${bill.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                    StatusBadge(status: bill.statusTagihan.dbValue),
                  ],
                ),
              ),

              // Receipt body — breakdown rows
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildReceiptRow(
                      label: 'Volume Pemakaian',
                      value: '${bill.pemakaianM3} m³',
                      isDark: isDark,
                      isBold: true,
                    ),
                    const SizedBox(height: 14),
                    _buildReceiptRow(
                      label: 'Tarif Air',
                      value: bill.pemakaianM3 > 0
                          ? '${bill.pemakaianM3} m³ × ${formatter.format(rate)}'
                          : '-',
                      isDark: isDark,
                    ),
                    if (bill.pemakaianM3 == 0) ...[
                      const SizedBox(height: 14),
                      _buildReceiptRow(
                        label: 'Biaya Abodemen',
                        value: formatter.format(abodemen),
                        isDark: isDark,
                      ),
                    ],
                    _buildSubtotalRow(
                      label: 'Subtotal',
                      value: formatter.format(calculatedTotal),
                      isDark: isDark,
                    ),

                    // Penalty row — highlighted with warning color
                    if (bill.jumlahBulanTunggakan > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withAlpha(50),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Denda Tunggakan',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  Text(
                                    '${bill.jumlahBulanTunggakan} bulan belum dibayar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.error.withAlpha(180),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatter.format(bill.totalDenda),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    DashedDivider(
                      height: 1.5,
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      dashWidth: 6,
                      dashGap: 4,
                    ),
                    const SizedBox(height: 20),

                    // ── Total Pembayaran — Large fintech-style amount ─────
                    Column(
                      children: [
                        Text(
                          bill.jumlahBulanTunggakan > 0 ? 'Total Pembayaran' : 'Total Tagihan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Hero total amount — large, bold, unmissable
                        Text(
                          formatter.format(totalBayar),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 36, // Large fintech-style total
                            color: bill.jumlahBulanTunggakan > 0
                                ? AppColors.error
                                : AppColors.textLightPrimary,
                            letterSpacing: -1.0,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Termasuk semua biaya',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pay button at bottom of card
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: PrimaryButton(
                  text: 'Bayar Sekarang',
                  icon: Icons.payment_rounded,
                  height: 56, // Extra generous touch target for CTA
                  onPressed: () => _openPaymentSheet(
                    context,
                    ref,
                    bill.copyWith(totalTagihan: totalBayar),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow({
    required String label,
    required String value,
    required bool isDark,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtotalRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Shared detail row for Tarif section
Widget _buildDetailRow(
  String label,
  String value, {
  bool isBoldValue = false,
  required bool isDark,
  Color? valueColor,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isBoldValue ? FontWeight.w800 : FontWeight.w700,
          color: valueColor ?? (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
        ),
      ),
    ],
  );
}

// ==========================================
// SUB-WIDGET: Dashed Divider
// ==========================================
class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashGap;

  const DashedDivider({
    super.key,
    this.height = 1,
    this.color = Colors.grey,
    this.dashWidth = 5,
    this.dashGap = 3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashGap)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

// ==========================================
// TAB 3: RIWAYAT PEMBAYARAN
// ==========================================
class _HistoryTab extends ConsumerWidget {
  final String customerId;
  const _HistoryTab({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentHistoryAsync = ref.watch(paymentHistoryProvider(customerId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(paymentHistoryProvider(customerId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Pembayaran',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Riwayat lengkap transaksi pembayaran tagihan air Anda.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: 20),
            paymentHistoryAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)
                                .withAlpha(120),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada riwayat pembayaran.',
                            style: TextStyle(
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final tx = payments[index];
                    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(tx.waktuBayar);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CustomCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.success.withAlpha(20),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.success,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.metodePembayaran,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textDarkSecondary
                                          : AppColors.textLightSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${tx.id.length > 20 ? '${tx.id.substring(0, 20)}…' : tx.id}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: (isDark
                                          ? AppColors.textDarkSecondary
                                          : AppColors.textLightSecondary)
                                          .withAlpha(150),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatter.format(tx.jumlahBayar),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.primary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Gagal memuat riwayat: $err',
                    style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SUB-WIDGET: Payment Gateway Bottom Sheet
// ==========================================
class _PaymentGatewaySheet extends ConsumerStatefulWidget {
  final TagihanModel bill;
  const _PaymentGatewaySheet({required this.bill});

  @override
  ConsumerState<_PaymentGatewaySheet> createState() => _PaymentGatewaySheetState();
}

class _PaymentGatewaySheetState extends ConsumerState<_PaymentGatewaySheet> {
  String _selectedMethod = 'QRIS';
  bool _isPaying = false;

  final List<Map<String, dynamic>> _methods = [
    {'name': 'QRIS', 'subtitle': 'Gopay, OVO, ShopeePay & semua e-wallet', 'icon': Icons.qr_code_2_rounded},
    {'name': 'Virtual Account (VA)', 'subtitle': 'Mandiri, BCA, BRI, BNI', 'icon': Icons.account_balance_rounded},
    {'name': 'e-Wallet', 'subtitle': 'DANA, LinkAja', 'icon': Icons.account_balance_wallet_rounded},
  ];

  void _triggerPayment() async {
    setState(() {
      _isPaying = true;
    });

    try {
      final success = await ref.read(tagihanServiceProvider).processPaymentMock(
            tagihanId: widget.bill.id,
            metodePembayaran: _selectedMethod,
            jumlahBayar: widget.bill.totalTagihan,
            totalDenda: widget.bill.totalDenda,
          );

      if (success && mounted) {
        Navigator.pop(context, true);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pembayaran gagal: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 52),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pembayaran Sukses!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'Tagihan sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.bill.totalTagihan)} telah lunas.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.grey),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Selesai',
                width: 150,
                onPressed: () => Navigator.pop(context),
              ),
            ],
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Text(
            'Konfirmasi Pembayaran',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Total yang akan dibayar',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 8),
          // Prominently styled total amount
          Text(
            formatter.format(widget.bill.totalTagihan),
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.error,
              fontWeight: FontWeight.w800,
              fontSize: 30,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Pilih Metode Pembayaran',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._methods.map((method) {
            final isSelected = _selectedMethod == method['name'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: _isPaying
                    ? null
                    : () {
                        setState(() {
                          _selectedMethod = method['name'] as String;
                        });
                      },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected
                        ? AppColors.primary.withAlpha(12)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        method['icon'] as IconData,
                        color: isSelected ? AppColors.primary : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method['name'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? Colors.white : AppColors.textLightPrimary),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              method['subtitle'] as String,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Konfirmasi & Bayar',
            height: 56,
            isLoading: _isPaying,
            onPressed: _triggerPayment,
          ),
        ],
      ),
    );
  }
}
