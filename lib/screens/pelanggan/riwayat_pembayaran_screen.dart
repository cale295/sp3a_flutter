import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/pembayaran_detail_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tagihan_provider.dart';
import '../../providers/database_provider.dart';

class RiwayatPembayaranScreen extends ConsumerStatefulWidget {
  final String customerId;

  const RiwayatPembayaranScreen({super.key, required this.customerId});

  @override
  ConsumerState<RiwayatPembayaranScreen> createState() => _RiwayatPembayaranScreenState();
}

class _RiwayatPembayaranScreenState extends ConsumerState<RiwayatPembayaranScreen> {
  String _selectedYear = 'Semua';

  // Constant colors for Design System
  static const Color scaffoldBgColor = Color(0xFFFAFAFA);
  static const Color waterBlueColor = Color(0xFF0EA5E9);



  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentHistoryWithDetailsProvider(widget.customerId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: waterBlueColor),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Riwayat Pembayaran',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: paymentsAsync.when(
        data: (payments) {
          // Dynamic Years for Dropdown based on fetched records
          final years = {'Semua'};
          for (var p in payments) {
            years.add(p.periodeTahun.toString());
          }
          final sortedYears = years.toList()..sort((a, b) => b.compareTo(a)); // Newest year first

          // Filter Logic
          final filteredPayments = payments.where((p) {
            return _selectedYear == 'Semua' || p.periodeTahun.toString() == _selectedYear;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(paymentHistoryWithDetailsProvider(widget.customerId));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Filter Section ──────────────────────────────────
                Container(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : Colors.grey[300]!,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedYear,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: waterBlueColor),
                        items: sortedYears.map((year) {
                          return DropdownMenuItem<String>(
                            value: year,
                            child: Text(
                              year == 'Semua' ? 'Semua Tahun' : 'Tahun $year',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedYear = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                // ── Transaction List ──────────────────────────────────────────
                Expanded(
                  child: filteredPayments.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 80),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 56,
                                    color: (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)
                                        .withAlpha(100),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada transaksi pembayaran.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          itemCount: filteredPayments.length,
                          itemBuilder: (context, index) {
                            final tx = filteredPayments[index];
                            return _buildTransactionCard(context, tx, isDark);
                          },
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Gagal memuat riwayat transaksi: $err',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, PembayaranDetailModel tx, bool isDark) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final paymentDateStr = DateFormat('dd MMM yyyy, HH:mm').format(tx.waktuBayar);

    // List of months in Indonesian
    final listBulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final billPeriodStr = "${listBulan[tx.periodeBulan]} ${tx.periodeTahun}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showPaymentDetailBottomSheet(context, tx, isDark),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Bill Icon decoration
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tagihan $billPeriodStr',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        paymentDateStr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Transaction ID label
                      Text(
                        'ID: ${tx.id.length > 18 ? '${tx.id.substring(0, 18)}…' : tx.id}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary).withAlpha(160),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Payment status and amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormatter.format(tx.jumlahBayar),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // "Berhasil" Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Berhasil',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.success,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
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
      ),
    );
  }

  void _showPaymentDetailBottomSheet(BuildContext context, PembayaranDetailModel tx, bool isDark) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final longDateStr = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(tx.waktuBayar);

    // List of months in Indonesian
    final listBulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final billPeriodStr = "${listBulan[tx.periodeBulan]} ${tx.periodeTahun}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authProvider);
            final customer = authState.user;

            if (customer == null) {
              return const SizedBox();
            }

            final tarifAsync = ref.watch(tarifForTipeProvider(customer.tipePelanggan));

            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // BottomSheet Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bukti Pembayaran',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 18, color: waterBlueColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Receipt Logo / State Decoration
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: AppColors.success, size: 36),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pembayaran Sukses',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 16),

                  // Transaction Metadata Fields
                  _buildReceiptField('ID Transaksi', tx.id, isDark, isSelectable: true),
                  const SizedBox(height: 10),
                  _buildReceiptField('Waktu Bayar', longDateStr, isDark),
                  const SizedBox(height: 10),
                  _buildReceiptField('Metode Pembayaran', tx.metodePembayaran.toUpperCase(), isDark),
                  const SizedBox(height: 10),
                  _buildReceiptField('Periode Tagihan', billPeriodStr, isDark),

                  const SizedBox(height: 20),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 16),

                  // Bill Details Breakdown Title
                  Text(
                    'Rincian Tagihan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Asynchronous Tariff lookup & breakdown rendering
                  tarifAsync.when(
                    data: (tarif) {
                      final rate = tarif.hargaPerM3;
                      final abodemen = tarif.biayaAbodemen;
                      final volume = tx.tagihan.pemakaianM3;

                      final double waterCost = volume > 0 ? (volume * rate) : 0.0;
                      final double abodemenCost = volume == 0 ? abodemen : 0.0;

                      return Column(
                        children: [
                          _buildBreakdownRow(
                            'Tarif Air ($volume m³ × ${currencyFormatter.format(rate)})',
                            volume > 0 ? currencyFormatter.format(waterCost) : 'Gratis / Rp 0',
                            isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildBreakdownRow(
                            'Biaya Abodemen',
                            volume == 0 ? currencyFormatter.format(abodemenCost) : 'Bebas Biaya',
                            isDark,
                          ),
                          if (tx.tagihan.totalDenda > 0) ...[
                            const SizedBox(height: 10),
                            _buildBreakdownRow(
                              'Denda Keterlambatan',
                              currencyFormatter.format(tx.tagihan.totalDenda),
                              isDark,
                              color: AppColors.error,
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                    error: (e, _) => Text(
                      'Gagal memuat rincian tarif: $e',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.error, fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 16),

                  // Total Amount Fintech-style Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Bayar',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                        Text(
                          currencyFormatter.format(tx.jumlahBayar),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReceiptField(String label, String value, bool isDark, {bool isSelectable = false}) {
    final valueWidget = Text(
      value,
      textAlign: TextAlign.right,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: isSelectable
              ? SelectableText(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                  ),
                )
              : valueWidget,
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, String value, bool isDark, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color ?? (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
          ),
        ),
      ],
    );
  }
}
