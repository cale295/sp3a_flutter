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
import '../ocr/catat_meteran_screen.dart';

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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.namaLengkap, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  Text(
                    'Pelanggan: ${customer.tipePelanggan.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textDarkSecondary.withOpacity(0.5) : AppColors.textLightSecondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
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
          unselectedItemColor: isDark ? AppColors.textDarkSecondary.withOpacity(0.5) : AppColors.textLightSecondary.withOpacity(0.5),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 22),
              activeIcon: Icon(Icons.home_rounded, size: 22),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined, size: 22),
              activeIcon: Icon(Icons.receipt_long_rounded, size: 22),
              label: 'Tagihan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded, size: 22),
              activeIcon: Icon(Icons.history_rounded, size: 22),
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

  Widget _buildMetricColumnCard({
    required String title,
    required String value,
    required String conversion,
    required bool isDark,
    Widget? bottomRow,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            conversion,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textDarkSecondary.withOpacity(0.7) : AppColors.textLightSecondary.withOpacity(0.7),
            ),
          ),
          if (bottomRow != null) ...[
            const SizedBox(height: 12),
            bottomRow,
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: isDark ? AppColors.textDarkSecondary.withOpacity(0.6) : AppColors.textLightSecondary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(customerReadingsProvider(customerId));
    final authState = ref.watch(authProvider);
    final userType = authState.user?.tipePelanggan ?? TipePelanggan.rumahTangga;
    final tarifAsync = ref.watch(tarifForTipeProvider(userType));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final literFormatter = NumberFormat.decimalPattern('id_ID');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(customerReadingsProvider(customerId));
        ref.invalidate(tarifForTipeProvider(userType));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark ? null : AppColors.lightShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PORTAL PELANGGAN SP3A',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pantau penggunaan air Anda dengan mudah & lakukan pembayaran aman secara online.',
                    style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.speed_rounded, size: 16),
                      label: const Text('Catat Meter Mandiri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      onPressed: () {
                        final authState = ref.read(authProvider);
                        if (authState.user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CatatMeteranScreen(pelanggan: authState.user!),
                            ),
                          ).then((_) {
                            ref.invalidate(customerReadingsProvider(customerId));
                            ref.invalidate(activeTagihanProvider(customerId));
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Prominent Water Usage section
            Text('Pemakaian Air', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            readingsAsync.when(
              data: (readings) {
                int totalUsage = 0;

                if (readings.isNotEmpty) {
                  // Calculate cumulative total usage (sum of all past pemakaian_m3)
                  for (int i = 0; i < readings.length; i++) {
                    final currentMeter = readings[i].angkaMeteran;
                    final prev = (i + 1 < readings.length) ? readings[i + 1].angkaMeteran : 0;
                    final u = currentMeter - prev;
                    if (u > 0) {
                      totalUsage += u;
                    }
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card 1: Total Pemakaian Air
                    _buildMetricColumnCard(
                      title: 'Total Pemakaian Air',
                      value: '$totalUsage m³',
                      conversion: '≈ ${literFormatter.format(totalUsage * 1000)} Liter',
                      isDark: isDark,
                      bottomRow: Row(
                        children: [
                          Icon(Icons.analytics_rounded, color: isDark ? AppColors.textDarkSecondary.withOpacity(0.6) : AppColors.textLightSecondary.withOpacity(0.6), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Akumulasi semua periode',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textDarkSecondary.withOpacity(0.6) : AppColors.textLightSecondary.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Gagal memuat pemakaian: $err')),
            ),
            const SizedBox(height: 28),

            // Quick Actions
            Text('Aksi Cepat', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    title: 'Catat Meter',
                    subtitle: 'Kirim angka meter',
                    icon: Icons.speed_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                    onTap: () {
                      final authState = ref.read(authProvider);
                      if (authState.user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CatatMeteranScreen(pelanggan: authState.user!),
                          ),
                        ).then((_) {
                          ref.invalidate(customerReadingsProvider(customerId));
                          ref.invalidate(activeTagihanProvider(customerId));
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context: context,
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
                  child: _buildActionButton(
                    context: context,
                    title: 'Riwayat Bayar',
                    subtitle: 'Cek transaksi lalu',
                    icon: Icons.history_rounded,
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                    onTap: () => onTabChange?.call(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Informasi Tarif Aktif
            tarifAsync.when(
              data: (tarif) {
                final rate = tarif.hargaPerM3;
                final abodemen = tarif.biayaAbodemen;
                final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informasi Tarif Aktif', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    CustomCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    userType == TipePelanggan.rumahTangga ? 'Tarif Rumah Tangga' : 'Tarif Bisnis',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ],
                              ),
                              const StatusBadge(status: 'aktif'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Harga Air / m³', currencyFormatter.format(rate), isDark: isDark),
                          const SizedBox(height: 10),
                          _buildDetailRow('Biaya Abodemen', currencyFormatter.format(abodemen), isDark: isDark),
                          const SizedBox(height: 14),
                          DashedDivider(
                            height: 1.5,
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            dashWidth: 5,
                            dashGap: 3,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.tips_and_updates_outlined,
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Catatan: Biaya abodemen dibebankan jika pemakaian air 0 m³ pada bulan terkait. Jika pemakaian > 0 m³, biaya abodemen dibebaskan.',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    height: 1.4,
                                    color: isDark ? AppColors.textDarkSecondary.withOpacity(0.8) : AppColors.textLightSecondary.withOpacity(0.8),
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
                  child: Text('Gagal memuat informasi tarif: $err', style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 2: TAGIHAN (BILLS)
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informasi Tagihan Aktif', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            activeTagihanAsync.when(
              data: (bill) {
                if (bill == null) {
                  return CustomCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 36),
                            ),
                            const SizedBox(height: 16),
                            const Text('Semua tagihan Anda lunas!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2)),
                            const SizedBox(height: 4),
                            Text('Terima kasih atas pembayaran tepat waktu.', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return tarifAsync.when(
                  data: (tarif) {
                    final rate = tarif.hargaPerM3;
                    final abodemen = tarif.biayaAbodemen;
                    
                    // APPLY CONDITIONAL ABODEMEN RULE
                    final calculatedTotal = bill.pemakaianM3 == 0 ? abodemen : (bill.pemakaianM3 * rate);

                    return Column(
                      children: [
                        CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tagihan Air Bulan Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                                  StatusBadge(status: bill.statusTagihan.dbValue),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Details breakdown
                              _buildDetailRow('Volume Pemakaian', '${bill.pemakaianM3} m³', isBoldValue: true, isDark: isDark),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Tarif Air',
                                '${bill.pemakaianM3} m³ x ${formatter.format(rate)} = ${formatter.format(bill.pemakaianM3 * rate)}',
                                isDark: isDark,
                              ),
                              // DYNAMICALLY HIDE ABODEMEN ROW IF USAGE > 0
                              if (bill.pemakaianM3 == 0) ...[
                                const SizedBox(height: 12),
                                _buildDetailRow('Biaya Abodemen', formatter.format(abodemen), isDark: isDark),
                              ],
                              // DYNAMICALLY SHOW PENALTY ROW IF LATE BILLS > 0
                              if (bill.jumlahBulanTunggakan > 0) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.error.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Denda Tunggakan (${bill.jumlahBulanTunggakan} Bulan)',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        formatter.format(bill.totalDenda),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              DashedDivider(
                                height: 1.5,
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                dashWidth: 5,
                                dashGap: 3,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    bill.jumlahBulanTunggakan > 0 ? 'Total Pembayaran' : 'Total Tagihan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                    ),
                                  ),
                                  Text(
                                    formatter.format(calculatedTotal + bill.totalDenda),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: AppColors.error,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                text: 'Bayar Sekarang',
                                icon: Icons.payment_rounded,
                                onPressed: () => _openPaymentSheet(
                                  context,
                                  ref,
                                  bill.copyWith(totalTagihan: calculatedTotal + bill.totalDenda),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('Gagal memuat tarif: $err'),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('Gagal memuat tagihan: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildDetailRow(String label, String value, {bool isBoldValue = false, required bool isDark}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
        ),
      ),
    ],
  );
}

// ==========================================
// SUB-WIDGET: Dashed Divider for Premium Receipt Styling
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
// TAB 3: RIWAYAT PEMBAYARAN (HISTORY)
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timeline Pembayaran', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Riwayat lengkap transaksi pembayaran tagihan air Anda.',
              style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
            ),
            const SizedBox(height: 20),
            paymentHistoryAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Text(
                        'Belum ada riwayat pembayaran.',
                        style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 13),
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
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.metodePembayaran,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Order ID: ${tx.id}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkSecondary.withOpacity(0.6) : AppColors.textLightSecondary.withOpacity(0.6))),
                                  const SizedBox(height: 2),
                                  Text(dateStr, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkSecondary.withOpacity(0.6) : AppColors.textLightSecondary.withOpacity(0.6))),
                                ],
                              ),
                            ),
                            Text(
                              formatter.format(tx.jumlahBayar),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary, letterSpacing: -0.2),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Gagal memuat riwayat: $err')),
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
    {'name': 'QRIS', 'subtitle': 'Bayar instan pakai Gopay, OVO, ShopeePay', 'icon': Icons.qr_code_2_rounded},
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 20),
              const Text('Pembayaran Sukses!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              const SizedBox(height: 6),
              Text(
                'Tagihan sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.bill.totalTagihan)} telah lunas.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Selesai',
                width: 140,
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
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: Colors.grey[350], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Text('Pembayaran Air SP3A', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Total tagihan: ${formatter.format(widget.bill.totalTagihan)}',
            style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 14.5, letterSpacing: -0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Pilih Metode Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? Colors.white : AppColors.textLightPrimary),
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
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isSelected ? 1.5 : 1,
                    ),
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.04)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        method['icon'] as IconData,
                        color: isSelected ? AppColors.primary : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method['name'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textLightPrimary),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              method['subtitle'] as String,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Konfirmasi & Bayar',
            isLoading: _isPaying,
            onPressed: _triggerPayment,
          ),
        ],
      ),
    );
  }
}
